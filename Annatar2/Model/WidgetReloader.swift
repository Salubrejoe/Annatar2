import Foundation
import WidgetKit
internal import CoreData

/// Tells WidgetKit to refresh its timelines whenever the persistent store
/// reports a remote change — i.e. when CloudKit pushes an update from
/// another device. Local writes already reload via `DeviceWriter.refresh`.
///
/// Owned by the main app and the watch app as a `let` so it lives for the
/// process lifetime; `deinit` removes the observer.
final class WidgetReloader {

  private var observer: NSObjectProtocol?

  init() { start() }

  deinit { stop() }
}


// MARK: - Setup / teardown

private extension WidgetReloader {

  func start() {
    observer = NotificationCenter.default.addObserver(
      forName: .NSPersistentStoreRemoteChange,
      object: nil,
      queue: .main
    ) { _ in
      WidgetCenter.shared.reloadAllTimelines()
    }
  }

  func stop() {
    if let observer { NotificationCenter.default.removeObserver(observer) }
  }
}
