import Foundation
import ComposableArchitecture

public extension PersistenceReaderKey where Self == PersistenceKeyDefault<FileStorageKey<IdentifiedArrayOf<RecordingInfo>>> {
  static var recordings: Self {
    PersistenceKeyDefault(.fileStorage(URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]).appendingPathComponent("recordings.json")), [])
  }
}

public extension PersistenceReaderKey where Self == PersistenceKeyDefault<InMemoryKey<IdentifiedArrayOf<TranscriptionTask>>> {
  static var transcriptionTasks: Self {
    PersistenceKeyDefault(.inMemory(#function), [])
  }
}

public extension PersistenceReaderKey where Self == PersistenceKeyDefault<InMemoryKey<Bool>> {
  static var isICloudSyncInProgress: Self {
    PersistenceKeyDefault(.inMemory(#function), false)
  }
}

public extension PersistenceReaderKey where Self == FileStorageKey<Settings> {
  static var settings: Self {
    .fileStorage(URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]).appendingPathComponent("settings.json"))
  }
}
