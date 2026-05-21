import Foundation
import SwiftData

/// The persisted, CloudKit-synced shape of a tracked device.
///
/// All properties are optional because CloudKit doesn't enforce required
/// fields — every record must be able to round-trip with any subset of
/// values present. The display name and the device-family icon are
/// derived from `hardwareID` at read time, so a future update to
/// `MarketingNames` refreshes every device's name without re-syncing.
@Model
final class Device {

  var id: UUID?
  var hardwareID: String?
  var batteryLevel: Double?
  var batteryStateRawValue: Int?
  var capturedAt: Date?

  /// Set by another device asking *this* device to push a fresh reading.
  /// Cleared by the target as part of `DeviceWriter.refresh`. A `nil` value
  /// means "no pending request."
  var refreshRequestedAt: Date?

  init(
    id: UUID? = nil,
    hardwareID: String? = nil,
    batteryLevel: Double? = nil,
    batteryStateRawValue: Int? = nil,
    capturedAt: Date? = nil,
    refreshRequestedAt: Date? = nil
  ) {
    self.id                   = id
    self.hardwareID           = hardwareID
    self.batteryLevel         = batteryLevel
    self.batteryStateRawValue = batteryStateRawValue
    self.capturedAt           = capturedAt
    self.refreshRequestedAt   = refreshRequestedAt
  }
}


// MARK: - Domain projection

extension Device {

  var batteryState: BatteryState {
    BatteryState(rawValue: batteryStateRawValue ?? 0) ?? .unknown
  }

  var battery: BatteryReading {
    BatteryReading(
      level: batteryLevel,
      state: batteryState,
      capturedAt: capturedAt ?? .distantPast
    )
  }

  var identity: DeviceIdentity? {
    guard let id, let hardwareID else { return nil }
    return DeviceIdentity(id: id, hardwareID: hardwareID)
  }
}


// MARK: - Writing

extension Device {

  /// Absorb a fresh `LocalDevice` snapshot into this record.
  func apply(_ snapshot: LocalDevice) {
    self.id                   = snapshot.identity.id
    self.hardwareID           = snapshot.identity.hardwareID
    self.batteryLevel         = snapshot.battery.level
    self.batteryStateRawValue = snapshot.battery.state.rawValue
    self.capturedAt           = snapshot.battery.capturedAt
  }

  /// A fresh, not-yet-inserted `Device` initialised from a snapshot.
  convenience init(_ snapshot: LocalDevice) {
    self.init()
    apply(snapshot)
  }
}
