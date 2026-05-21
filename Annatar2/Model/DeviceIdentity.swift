import Foundation

/// The parts of a device that don't change between battery refreshes.
///
/// Holds the platform hardware identifier (e.g. `"iPhone16,2"`) and a
/// stable per-install UUID. The user-facing name and the device-family
/// icon are computed from the hardware id — no editable custom name.
struct DeviceIdentity: Sendable, Equatable, Hashable {

  let id: UUID
  let hardwareID: String
}


// MARK: - Display projection

extension DeviceIdentity {

  /// Marketing name ("iPhone 15 Pro Max"). Falls back to the family name
  /// ("iPhone") for unrecognised hardware ids.
  var name: String {
    MarketingNames.name(for: hardwareID)
  }

  /// Device family — drives the icon choice in `BatteryGauge`.
  var model: DeviceModel {
    MarketingNames.category(for: hardwareID)
  }
}
