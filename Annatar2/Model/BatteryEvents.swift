import Foundation
import SwiftData
#if canImport(UIKit)
import UIKit
#endif
#if canImport(IOKit)
import IOKit.ps
#endif

/// Listens to native battery-change events while the app is alive and
/// triggers a `DeviceWriter.refresh` whenever the local battery moves.
/// Complements the scene-phase and background-task triggers.
///
/// Platform coverage:
///   • iOS / iPadOS / visionOS — `UIDevice` level + state notifications
///     (1% granularity while battery monitoring is enabled)
///   • macOS — `IOPSNotificationCreateRunLoopSource` on the main run loop
///   • watchOS — relies on scene-phase transitions; the wrist-raise /
///     wrist-down cycle already gives us frequent foreground hits.
///
/// Owned by `Annatar2App` as a `let` so the observer pair lives for the
/// process lifetime and is torn down at termination via `deinit`.
final class BatteryEvents {

  private let modelContainer: ModelContainer

  #if os(iOS) || os(visionOS)
  private var levelToken: NSObjectProtocol?
  private var stateToken: NSObjectProtocol?
  #endif

  #if os(macOS)
  private var iopsRunLoopSource: CFRunLoopSource?
  #endif

  init(modelContainer: ModelContainer) {
    self.modelContainer = modelContainer
    start()
  }

  deinit { stop() }
}


// MARK: - Setup / teardown

private extension BatteryEvents {

  func start() {
    #if os(iOS) || os(visionOS)
    UIDevice.current.isBatteryMonitoringEnabled = true

    levelToken = NotificationCenter.default.addObserver(
      forName: UIDevice.batteryLevelDidChangeNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in self?.refresh() }

    stateToken = NotificationCenter.default.addObserver(
      forName: UIDevice.batteryStateDidChangeNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in self?.refresh() }
    #endif

    #if os(macOS)
    let context = Unmanaged.passUnretained(self).toOpaque()
    let callback: IOPowerSourceCallbackType = { ptr in
      guard let ptr = ptr else { return }
      Unmanaged<BatteryEvents>.fromOpaque(ptr).takeUnretainedValue().refresh()
    }
    if let source = IOPSNotificationCreateRunLoopSource(callback, context)?
        .takeRetainedValue() {
      CFRunLoopAddSource(CFRunLoopGetMain(), source, .defaultMode)
      iopsRunLoopSource = source
    }
    #endif
  }

  func stop() {
    #if os(iOS) || os(visionOS)
    if let t = levelToken { NotificationCenter.default.removeObserver(t) }
    if let t = stateToken { NotificationCenter.default.removeObserver(t) }
    #endif

    #if os(macOS)
    if let source = iopsRunLoopSource {
      CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .defaultMode)
    }
    #endif
  }

  func refresh() {
    let context = ModelContext(modelContainer)
    try? DeviceWriter.refresh(in: context)
  }
}
