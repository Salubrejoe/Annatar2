import Foundation
import SwiftData

/// A single recorded moment in the Activity log: a battery push, a
/// foreground/background transition, or a refresh request.
///
/// Synced via CloudKit so the Activity tab on the iPhone shows the
/// activity of *all* the user's devices, not just this one.
///
/// Every property is optional because CloudKit doesn't enforce required
/// fields and the schema must round-trip with any subset of values
/// present — same convention as `Device`.
@Model
final class LogEvent {

  var id: UUID?
  var timestamp: Date?
  var sourceDeviceID: UUID?
  var kindRawValue: String?

  // .post only:
  var batteryLevel: Double?
  var batteryStateRawValue: Int?

  // .refreshRequested only:
  var targetDeviceID: UUID?

  init(
    id: UUID? = nil,
    timestamp: Date? = nil,
    sourceDeviceID: UUID? = nil,
    kindRawValue: String? = nil,
    batteryLevel: Double? = nil,
    batteryStateRawValue: Int? = nil,
    targetDeviceID: UUID? = nil
  ) {
    self.id                   = id
    self.timestamp            = timestamp
    self.sourceDeviceID       = sourceDeviceID
    self.kindRawValue         = kindRawValue
    self.batteryLevel         = batteryLevel
    self.batteryStateRawValue = batteryStateRawValue
    self.targetDeviceID       = targetDeviceID
  }
}


// MARK: - Domain projection

extension LogEvent {

  var kind: LogEventKind {
    LogEventKind(rawValue: kindRawValue ?? "") ?? .unknown
  }

  var batteryState: BatteryState? {
    guard let raw = batteryStateRawValue else { return nil }
    return BatteryState(rawValue: raw)
  }
}
