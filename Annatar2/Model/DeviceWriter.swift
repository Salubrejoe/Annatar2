import Foundation
import SwiftData
import WidgetKit

/// Stateless writer: takes the current local battery snapshot and reflects
/// it into the SwiftData store.
///
/// Designed for both foreground refreshes and background tasks. There is
/// nothing to own, nothing to keep alive — just call `refresh(in:)`. This
/// is deliberately the entire replacement for the original `ATContainer`'s
/// stateful timer/observer machinery.
enum DeviceWriter {

  /// Read this device's current battery and write it to the store.
  /// Inserts a new record on first run, updates the existing one
  /// thereafter, and clears any pending refresh request aimed at us.
  @discardableResult
  static func refresh(in context: ModelContext) throws -> Device {
    let snapshot = LocalDevice.current()

    let device = try existing(matching: snapshot.identity.id, in: context)
                 ?? insert(snapshot, in: context)
    device.apply(snapshot)
    device.refreshRequestedAt = nil

    try context.save()
    WidgetCenter.shared.reloadAllTimelines()
    return device
  }

  /// Ask another device to push a fresh reading. Sets `refreshRequestedAt`
  /// on the target's `Device` record; CloudKit's silent push wakes the
  /// target, its `RefreshRequestListener` sees the field and runs
  /// `refresh(in:)`. Caller decides what to do while waiting.
  static func requestRefresh(for deviceID: UUID, in context: ModelContext) throws {
    let descriptor = FetchDescriptor<Device>(
      predicate: #Predicate { $0.id == deviceID }
    )
    guard let device = try context.fetch(descriptor).first else { return }
    device.refreshRequestedAt = .now
    try context.save()
  }

  /// Delete a tracked device from this device's store. CloudKit will
  /// propagate the deletion to other devices on the user's account.
  static func forget(id: UUID, in context: ModelContext) throws {
    guard let device = try existing(matching: id, in: context) else { return }
    context.delete(device)
    try context.save()
  }

  // MARK: - Private

  private static func existing(matching id: UUID, in context: ModelContext) throws -> Device? {
    let descriptor = FetchDescriptor<Device>(
      predicate: #Predicate { $0.id == id }
    )
    return try context.fetch(descriptor).first
  }

  private static func insert(_ snapshot: LocalDevice, in context: ModelContext) -> Device {
    let device = Device(snapshot)
    context.insert(device)
    return device
  }
}
