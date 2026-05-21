import WidgetKit
import SwiftUI
import SwiftData

/// Single small home-screen widget that displays one device's battery via
/// the same `DeviceCell` used inside the app. Configurable by the user
/// via `DeviceSelectionIntent`.
struct BatteryWidget: Widget {

  let kind: String = "BatteryWidget"

  var body: some WidgetConfiguration {
    AppIntentConfiguration(
      kind: kind,
      intent: DeviceSelectionIntent.self,
      provider: BatteryProvider()
    ) { entry in
      BatteryWidgetEntryView(entry: entry)
        .containerBackground(.fill.tertiary, for: .widget)
    }
    .configurationDisplayName("Battery")
    .description("See a device's battery on your home screen.")
    .supportedFamilies([.systemSmall])
  }
}


// MARK: - Entry

struct DeviceEntry: TimelineEntry {
  let date: Date
  let identity: DeviceIdentity
  let battery: BatteryReading

  /// Reasonable default when no device has been chosen or the store is empty.
  static let placeholder = DeviceEntry(
    date: .now,
    identity: DeviceIdentity(id: UUID(), hardwareID: "iPhone15,4"),
    battery: BatteryReading(level: 0.62, state: .unplugged, capturedAt: .now)
  )
}


// MARK: - Provider

struct BatteryProvider: AppIntentTimelineProvider {

  func placeholder(in context: Context) -> DeviceEntry { .placeholder }

  func snapshot(for configuration: DeviceSelectionIntent, in context: Context) async -> DeviceEntry {
    await entry(for: configuration) ?? .placeholder
  }

  func timeline(for configuration: DeviceSelectionIntent, in context: Context) async -> Timeline<DeviceEntry> {
    let entry = await entry(for: configuration) ?? .placeholder
    // Fallback reload — the main app calls `WidgetCenter.shared.reloadAllTimelines()`
    // after every successful refresh, so this 15-minute heartbeat is just a
    // safety net in case we miss a wake.
    return Timeline(entries: [entry], policy: .after(.now.addingTimeInterval(15 * 60)))
  }

  @MainActor
  private func entry(for configuration: DeviceSelectionIntent) async -> DeviceEntry? {
    guard let chosen = configuration.device else { return nil }

    guard let container = try? AnnatarSchema.makeContainer() else { return nil }
    let context = container.mainContext
    let devices = (try? context.fetch(FetchDescriptor<Device>())) ?? []

    guard let device = devices.first(where: { $0.id == chosen.id }),
          let identity = device.identity
    else { return nil }

    return DeviceEntry(date: .now, identity: identity, battery: device.battery)
  }
}


// MARK: - View

struct BatteryWidgetEntryView: View {

  let entry: DeviceEntry

  var body: some View {
    DeviceCell(identity: entry.identity, battery: entry.battery)
          
  }
}


// MARK: - Preview

#Preview(as: .systemSmall) {
  BatteryWidget()
} timeline: {
  DeviceEntry(
    date: .now,
    identity: DeviceIdentity(id: UUID(), hardwareID: "iPhone18,1"),
    battery: BatteryReading(level: 0.88, state: .charging, capturedAt: .now)
  )
  DeviceEntry(
    date: .now,
    identity: DeviceIdentity(id: UUID(), hardwareID: "Mac17,2"),
    battery: BatteryReading(level: 0.42, state: .unplugged, capturedAt: .now)
  )
}
