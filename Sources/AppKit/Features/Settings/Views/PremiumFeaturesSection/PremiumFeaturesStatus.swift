import ComposableArchitecture

// MARK: - PremiumFeaturesStatus

public struct PremiumFeaturesStatus: Codable, Hashable {
  public var liveTranscriptionIsPurchased: Bool? = nil
  public var isProductFound: Bool? = nil
}

// MARK: - PremiumFeaturesProductID

public enum PremiumFeaturesProductID {
  public static let liveTranscription = "me.igortarasenko.Whisperboard.LiveTranscription"
}

public extension PersistenceReaderKey where Self == PersistenceKeyDefault<FileStorageKey<PremiumFeaturesStatus>> {
  static var premiumFeatures: Self {
    PersistenceKeyDefault(.fileStorage(URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]).appendingPathComponent("premiumFeatures.json")), PremiumFeaturesStatus())
  }
}
