import SwiftUI
import SwiftData
#if canImport(BackgroundTasks)
import BackgroundTasks
#endif
#if canImport(WatchKit)
import WatchKit
#endif

@main
struct Annatar2App: App {

  @Environment(\.scenePhase) private var scenePhase
  private let modelContainer: ModelContainer
  private let batteryEvents: BatteryEvents
  private let refreshRequestListener: RefreshRequestListener
  private let widgetReloader: WidgetReloader
  private let bluetoothScanner: BluetoothScanner

  init() {
    do {
      let container = try AnnatarSchema.makeContainer()
      self.modelContainer = container
      self.batteryEvents = BatteryEvents(modelContainer: container)
      self.refreshRequestListener = RefreshRequestListener(modelContainer: container)
      self.widgetReloader = WidgetReloader()
      self.bluetoothScanner = BluetoothScanner()
    } catch {
      fatalError("Could not open Annatar store: \(error)")
    }
  }

  var body: some Scene {
    #if os(macOS)
    macScene
    #else
    primaryScene
    #endif
  }
}


// MARK: - Scenes

#if os(iOS) || os(visionOS)
extension Annatar2App {

  private var primaryScene: some Scene {
    WindowGroup {
      TabView {
        Tab("Devices", systemImage: "rectangle.stack.fill") {
          MainView()
        }
        Tab("Activity", systemImage: "clock.arrow.circlepath") {
          LogView()
        }
      }
    }
    .modelContainer(modelContainer)
    .environment(bluetoothScanner)
    .onChange(of: scenePhase) { _, phase in handleScenePhase(phase) }
    .backgroundTask(.appRefresh(AnnatarSchema.backgroundTaskID)) {
      await refreshInBackground()
    }
  }
}
#endif

#if os(macOS)
extension Annatar2App {

  /// Placeholder. Will become a `MenuBarExtra` in a later round.
  private var macScene: some Scene {
    WindowGroup {
      MainView()
    }
    .modelContainer(modelContainer)
    .environment(bluetoothScanner)
    .onChange(of: scenePhase) { _, phase in handleScenePhase(phase) }
  }
}
#endif


// MARK: - Lifecycle

extension Annatar2App {

  private func handleScenePhase(_ phase: ScenePhase) {
    switch phase {
    case .active:
      refreshNow()
      bluetoothScanner.refresh()
      logEvent { context in EventLogger.logForeground(in: context) }
    case .background:
      refreshNow()                  // capture one last snapshot on the way out
      scheduleBackgroundRefresh()
      logEvent { context in EventLogger.logBackground(in: context) }
    default:
      break
    }
  }

  private func refreshNow() {
    let context = ModelContext(modelContainer)
    try? DeviceWriter.refresh(in: context)
  }

  private func refreshInBackground() async {
    let context = ModelContext(modelContainer)
    try? DeviceWriter.refresh(in: context)
    scheduleBackgroundRefresh()
  }

  private func logEvent(_ work: (ModelContext) -> Void) {
    let context = ModelContext(modelContainer)
    work(context)
  }

  private func scheduleBackgroundRefresh() {
    #if os(iOS) || os(visionOS)
    let request = BGAppRefreshTaskRequest(identifier: AnnatarSchema.backgroundTaskID)
    request.earliestBeginDate = .now.addingTimeInterval(15 * 60)
    try? BGTaskScheduler.shared.submit(request)
    #elseif os(watchOS)
    WKExtension.shared().scheduleBackgroundRefresh(
      withPreferredDate: .now.addingTimeInterval(15 * 60),
      userInfo: nil,
      scheduledCompletion: { _ in }
    )
    #endif
  }
}
