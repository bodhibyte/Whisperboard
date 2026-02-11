import Foundation

public enum Configs {
  public static var recordingsDirectoryURL: URL { FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first! }
}
