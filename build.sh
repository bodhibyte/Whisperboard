#!/bin/bash

# --- CONFIGURATION ---
# Update this path to point to your actual entitlements file
ENTITLEMENTS_PATH="./TrollStore.entitlements"
# ---------------------

# 1. Define Clipboard Command
if command -v pbcopy &> /dev/null; then CLIP_CMD="pbcopy"; elif command -v clip.exe &> /dev/null; then CLIP_CMD="clip.exe"; elif command -v xclip &> /dev/null; then CLIP_CMD="xclip -selection clipboard"; else CLIP_CMD="cat"; fi

# 2. Setup Timestamp
TS=$(date '+%Y-%m-%d-%H-%M-%S')

# 3. Commit and Push
git add . && git commit -m "Update $TS"
COMMIT_SHA=$(git rev-parse HEAD)
git push

echo "Waiting for workflow to initialize for commit: $COMMIT_SHA..."

# 4. Get Run ID (Loop until the specific commit appears in the run list)
RUN_ID=""
while [ -z "$RUN_ID" ]; do
    sleep 3
    RUN_ID=$(gh run list --commit "$COMMIT_SHA" --limit 1 --json databaseId --jq '.[0].databaseId')
done

echo "Found Run ID: $RUN_ID"

# 5. Watch Run
if gh run watch $RUN_ID --exit-status; then
    echo "Build Succeeded! Fetching artifact name..."

    # Get Artifact Name
    ARTIFACT_NAME=$(gh api "/repos/:owner/:repo/actions/runs/$RUN_ID/artifacts" --jq '.artifacts[0].name')

    if [ -z "$ARTIFACT_NAME" ] || [ "$ARTIFACT_NAME" == "null" ]; then
        echo "❌ Error: No artifacts found in this run."
        exit 1
    fi

    DOWNLOAD_DIR="build-$TS"
    echo "Downloading '$ARTIFACT_NAME' to: $DOWNLOAD_DIR"

    # Download
    gh run download $RUN_ID -n "$ARTIFACT_NAME" --dir "$DOWNLOAD_DIR"

    # ========================================================
    # 6. MANUAL REPACK METHOD (Inject Entitlements)
    # ========================================================
    echo "--- Starting Manual Repack ---"

    # Check if ldid exists
    if ! command -v ldid &> /dev/null; then
        echo "❌ Error: 'ldid' is not installed. Skipping repack."
        exit 1
    fi

    # Check if entitlements file exists
    if [ ! -f "$ENTITLEMENTS_PATH" ]; then
        echo "❌ Error: Entitlements file not found at: $ENTITLEMENTS_PATH"
        echo "   Please create it or update the path in the script configuration."
        exit 1
    fi

    # Find the downloaded .ipa file
    IPA_FILE=$(find "$DOWNLOAD_DIR" -name "*.ipa" | head -n 1)

    if [ -z "$IPA_FILE" ]; then
        echo "❌ Error: No .ipa file found in download folder."
        exit 1
    fi

    echo "Found IPA: $IPA_FILE"

    # Create Temp Folder
    TEMP_DIR="temp_repack_$TS"
    echo "Unzipping to temporary folder: $TEMP_DIR..."
    unzip -q "$IPA_FILE" -d "$TEMP_DIR"

    # Target the .app folder inside Payload
    APP_BUNDLE=$(find "$TEMP_DIR/Payload" -maxdepth 1 -name "*.app" | head -n 1)

    if [ -z "$APP_BUNDLE" ]; then
        echo "❌ Error: No .app bundle found inside Payload."
        rm -rf "$TEMP_DIR"
        exit 1
    fi

    echo "Injecting entitlements into: $APP_BUNDLE"

    # Run ldid -S (Note: -S must stick to the path without space)
    ldid -S"$ENTITLEMENTS_PATH" "$APP_BUNDLE"

    # If ldid failed on the bundle, try the binary directly (as per your notes)
    if [ $? -ne 0 ]; then
        echo "⚠️ ldid failed on bundle. Trying binary directly..."
        APP_NAME=$(basename "$APP_BUNDLE" .app)
        BINARY_PATH="$APP_BUNDLE/$APP_NAME"
        ldid -S"$ENTITLEMENTS_PATH" "$BINARY_PATH"
    fi

    # Verify (Optional)
    echo "Verifying signature..."
    ldid -e "$APP_BUNDLE" | grep -q "<key>" && echo "✅ Entitlements detected."

    # Re-zip
    NEW_IPA_NAME="Signed-$(basename "$IPA_FILE")"
    echo "Re-zipping to: $NEW_IPA_NAME"

    cd "$TEMP_DIR"
    zip -qr "../$NEW_IPA_NAME" Payload
    cd ..

    # Cleanup
    rm -rf "$TEMP_DIR"

    echo "✅ Success! Signed IPA saved as: $NEW_IPA_NAME"
    # ========================================================

else
    echo "❌ Build Failed!"
    gh run view $RUN_ID --log-failed | $CLIP_CMD
    echo "Error logs copied to clipboard."
fi
