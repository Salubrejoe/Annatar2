import Foundation
import SwiftData

/// Stateless writer for `LogEvent` records. Same shape as `DeviceWriter`
/// — call from anywhere with a `ModelContext`, no shared state.
///
/// Every call inserts one record and saves. CloudKit propagates from
/// there so the Activity tab on every device sees the full fleet's
/// history.
enum EventLogger {

  static func logPost(level: Double?, state: BatteryState, in context: ModelContext) {
    insert(
      kind: .post,
      batteryLevel: level,
      batteryState: state,
      in: context
    )
  }

  static func logForeground(in context: ModelContext) {
    insert(kind: .foreground, in: context)
  }

  static func logBackground(in context: ModelContext) {
    insert(kind: .background, in: context)
  }

  static func logRefreshRequested(targetDeviceID: UUID, in context: ModelContext) {
    insert(kind: .refreshRequested, targetDeviceID: targetDeviceID, in: context)
  }


  // MARK: - Private

  private static func insert(
    kind: LogEventKind,
    batteryLevel: Double? = nil,
    batteryState: BatteryState? = nil,
    targetDeviceID: UUID? = nil,
    in context: ModelContext
  ) {
    let event = LogEvent(
      id: UUID(),
      timestamp: .now,
      sourceDeviceID: LocalDeviceReader.identity.id,
      kindRawValue: kind.rawValue,
      batteryLevel: batteryLevel,
      batteryStateRawValue: batteryState?.rawValue,
      targetDeviceID: targetDeviceID
    )
    context.insert(event)
    try? context.save()
  }
}
