import Foundation
import SwiftData

/// Centralised SwiftData + CloudKit configuration.
///
/// The three identifiers below must match what's configured in Xcode's
/// Signing & Capabilities tab:
///   • App Groups capability includes `appGroup`
///   • iCloud capability has CloudKit enabled with `cloudContainerID`
///   • Background Modes includes "Background fetch" + "Remote notifications"
enum AnnatarSchema {

  static let appGroup          = "group.com.lorep.uk.Annatar2"
  static let cloudContainerID  = "iCloud.com.lorep.uk.Annatar2"
  static let storeName         = "AnnatarStore"

  /// Background-refresh task identifier. Must also appear in Info.plist
  /// under `BGTaskSchedulerPermittedIdentifiers` for iOS/iPadOS/visionOS.
  static let backgroundTaskID  = "com.lorep.uk.Annatar2.refresh"

  static let schema = Schema([Device.self])

  /// Production container: app-group-shared, CloudKit-private-DB-backed.
  static func makeContainer() throws -> ModelContainer {
    let configuration = ModelConfiguration(
      storeName,
      schema: schema,
      groupContainer: .identifier(appGroup),
      cloudKitDatabase: .private(cloudContainerID)
    )
    return try ModelContainer(for: schema, configurations: configuration)
  }

  /// Empty in-memory container for SwiftUI previews & tests. No CloudKit,
  /// no app group, no seed data.
  @MainActor
  static func makePreviewContainer() -> ModelContainer {
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    return try! ModelContainer(for: schema, configurations: configuration)
  }
}
