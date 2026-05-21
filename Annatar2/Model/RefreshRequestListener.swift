import Foundation
import SwiftData
internal import CoreData

/// Watches for incoming "please push a fresh reading" requests aimed at
/// *this* device and fulfils them by running `DeviceWriter.refresh`.
///
/// Requests are surfaced via the `refreshRequestedAt` field on our own
/// `Device` record. They arrive through CloudKit's silent push (handled
/// automatically by SwiftData) which fires `NSPersistentStoreRemoteChange`
/// after the merge. Stale requests (older than `staleThreshold`) are
/// ignored and cleared so they don't trigger refreshes after the user
/// has long since put the phone down.
///
/// Owned by `Annatar2App` as a `let` so it lives for the process lifetime.
final class RefreshRequestListener {

  private let modelContainer: ModelContainer
  private var observer: NSObjectProtocol?

  /// Requests older than this on first observation are considered stale.
  private let staleThreshold: TimeInterval = 60

  init(modelContainer: ModelContainer) {
    self.modelContainer = modelContainer
    start()
  }

  deinit { stop() }
}


// MARK: - Setup / teardown

private extension RefreshRequestListener {

  func start() {
    observer = NotificationCenter.default.addObserver(
      forName: .NSPersistentStoreRemoteChange,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      self?.checkForRequest()
    }
  }

  func stop() {
    if let observer { NotificationCenter.default.removeObserver(observer) }
  }

  func checkForRequest() {
    let context = ModelContext(modelContainer)
    let localID = LocalDeviceReader.identity.id

    let descriptor = FetchDescriptor<Device>(
      predicate: #Predicate { $0.id == localID }
    )

    guard let me = try? context.fetch(descriptor).first,
          let requestedAt = me.refreshRequestedAt
    else { return }

    let age = Date.now.timeIntervalSince(requestedAt)

    // Stale or future-dated — clear and ignore.
    guard age >= 0, age < staleThreshold else {
      me.refreshRequestedAt = nil
      try? context.save()
      return
    }

    try? DeviceWriter.refresh(in: context)
  }
}
