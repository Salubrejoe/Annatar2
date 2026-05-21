import SwiftUI
import SwiftData
import WatchKit

@main
struct WatchAnnatar2App: App {

  @Environment(\.scenePhase) private var scenePhase
  private let modelContainer: ModelContainer
  private let batteryEvents: BatteryEvents
  private let refreshRequestListener: RefreshRequestListener
  private let widgetReloader: WidgetReloader

  init() {
    do {
      let container = try AnnatarSchema.makeContainer()
      self.modelContainer = container
      self.batteryEvents = BatteryEvents(modelContainer: container)
      self.refreshRequestListener = RefreshRequestListener(modelContainer: container)
      self.widgetReloader = WidgetReloader()
    } catch {
      fatalError("Could not open Annatar store: \(error)")
    }
  }

  var body: some Scene {
    WindowGroup {
      WatchMainView()
    }
    .modelContainer(modelContainer)
    .onChange(of: scenePhase) { _, phase in handleScenePhase(phase) }
    .backgroundTask(.appRefresh(AnnatarSchema.backgroundTaskID)) {
      await refreshInBackground()
    }
  }
}


// MARK: - Lifecycle

extension WatchAnnatar2App {

  private func handleScenePhase(_ phase: ScenePhase) {
    switch phase {
    case .active:
      refreshNow()
    case .background:
      refreshNow()
      scheduleBackgroundRefresh()
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

  /// watchOS uses `WKExtension` instead of `BGTaskScheduler`. Same intent,
  /// different ceremony.
  private func scheduleBackgroundRefresh() {
    WKExtension.shared().scheduleBackgroundRefresh(
      withPreferredDate: .now.addingTimeInterval(15 * 60),
      userInfo: nil,
      scheduledCompletion: { _ in }
    )
  }
}
