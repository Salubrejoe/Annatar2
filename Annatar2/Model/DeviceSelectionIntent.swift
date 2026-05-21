import Foundation
import AppIntents
import SwiftData

/// The configurable intent attached to every widget / complication. Lets
/// the user pick *which* device the widget should display.
///
/// Add this file's target membership to:
///   • Annatar2          (so the main app links AppIntents)
///   • WidgetAnnatar2    (iOS widget extension)
///   • ComplicationsAnnatar2 (watch widget extension)
struct DeviceSelectionIntent: WidgetConfigurationIntent {

  static var title: LocalizedStringResource     { "Device" }
  static var description: IntentDescription     { "Choose which device's battery to show." }

  @Parameter(title: "Device")
  var device: DeviceEntity?
}


// MARK: - Entity

/// AppIntents entity representing a tracked `Device`. Pure value type so
/// it can flow through the AppIntents serialisation layer cleanly.
struct DeviceEntity: AppEntity, Identifiable {

  let id: UUID
  let hardwareID: String

  static var typeDisplayRepresentation: TypeDisplayRepresentation {
    TypeDisplayRepresentation(name: "Device")
  }

  var displayRepresentation: DisplayRepresentation {
    DisplayRepresentation(title: "\(MarketingNames.name(for: hardwareID))")
  }

  static var defaultQuery = DeviceQuery()
}


// MARK: - Query

/// Sources the list of devices for the widget configuration sheet.
/// Pulls live from the SwiftData store the same way the app does.
struct DeviceQuery: EntityQuery {

  @MainActor
  func entities(for identifiers: [DeviceEntity.ID]) async throws -> [DeviceEntity] {
    try fetch().filter { identifiers.contains($0.id) }
  }

  @MainActor
  func suggestedEntities() async throws -> [DeviceEntity] {
    try fetch()
  }

  @MainActor
  private func fetch() throws -> [DeviceEntity] {
    let container = try AnnatarSchema.makeContainer()
    let context = container.mainContext
    let devices = try context.fetch(FetchDescriptor<Device>())
    return devices.compactMap { device in
      guard let id = device.id, let hardwareID = device.hardwareID
      else { return nil }
      return DeviceEntity(id: id, hardwareID: hardwareID)
    }
  }
}
