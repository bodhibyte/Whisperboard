import ComposableArchitecture

// MARK: - DebugSettings

public struct DebugSettings: Codable, Hashable {
  public var shouldOverridePurchaseStatus = false
  public var liveTranscriptionIsPurchasedOverride = false
}

public extension PersistenceReaderKey where Self == PersistenceKeyDefault<FileStorageKey<DebugSettings>> {
  static var debugSettings: Self {
    PersistenceKeyDefault(.fileStorage(URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]).appendingPathComponent("debugSettings.json")), DebugSettings())
  }
}
