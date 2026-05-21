import WidgetKit
import SwiftUI
import SwiftData

/// Watch complications backed by the same SwiftData + CloudKit pipeline
/// as the rest of Annatar. One widget kind, four families. The user picks
/// which device the complication tracks via `DeviceSelectionIntent`.
struct WatchBatteryWidget: Widget {

  let kind: String = "WatchBatteryWidget"

  var body: some WidgetConfiguration {
    AppIntentConfiguration(
      kind: kind,
      intent: DeviceSelectionIntent.self,
      provider: WatchBatteryProvider()
    ) { entry in
      WatchBatteryEntryView(entry: entry)
        .containerBackground(.fill.tertiary, for: .widget)
    }
    .configurationDisplayName("Battery")
    .description("Track a device's battery on your watch face.")
    .supportedFamilies([
      .accessoryCircular,
      .accessoryCorner,
      .accessoryInline,
      .accessoryRectangular,
    ])
  }
}


// MARK: - Entry

struct WatchDeviceEntry: TimelineEntry {
  let date: Date
  let identity: DeviceIdentity
  let battery: BatteryReading

  static let placeholder = WatchDeviceEntry(
    date: .now,
    identity: DeviceIdentity(id: UUID(), hardwareID: "Watch7,5"),
    battery: BatteryReading(level: 0.72, state: .unplugged, capturedAt: .now)
  )
}


// MARK: - Provider

struct WatchBatteryProvider: AppIntentTimelineProvider {

  func placeholder(in context: Context) -> WatchDeviceEntry { .placeholder }

  func snapshot(for configuration: DeviceSelectionIntent, in context: Context) async -> WatchDeviceEntry {
    await entry(for: configuration) ?? .placeholder
  }

  func timeline(for configuration: DeviceSelectionIntent, in context: Context) async -> Timeline<WatchDeviceEntry> {
    let entry = await entry(for: configuration) ?? .placeholder
    return Timeline(entries: [entry], policy: .after(.now.addingTimeInterval(15 * 60)))
  }

  func recommendations() -> [AppIntentRecommendation<DeviceSelectionIntent>] {
    [AppIntentRecommendation(intent: DeviceSelectionIntent(), description: "Battery")]
  }

  @MainActor
  private func entry(for configuration: DeviceSelectionIntent) async -> WatchDeviceEntry? {
    guard let chosen = configuration.device else { return nil }

    guard let container = try? AnnatarSchema.makeContainer() else { return nil }
    let context = container.mainContext
    let devices = (try? context.fetch(FetchDescriptor<Device>())) ?? []

    guard let device = devices.first(where: { $0.id == chosen.id }),
          let identity = device.identity
    else { return nil }

    return WatchDeviceEntry(date: .now, identity: identity, battery: device.battery)
  }
}


// MARK: - Family dispatch

struct WatchBatteryEntryView: View {

  @Environment(\.widgetFamily) private var family
  let entry: WatchDeviceEntry

  var body: some View {
    switch family {
    case .accessoryCircular:    CircularComplication(identity: entry.identity, battery: entry.battery)
    case .accessoryCorner:      CornerComplication(identity: entry.identity, battery: entry.battery)
    case .accessoryInline:      InlineComplication(identity: entry.identity, battery: entry.battery)
    case .accessoryRectangular: RectangularComplication(identity: entry.identity, battery: entry.battery)
    default:                    Text("Annatar")
    }
  }
}


// MARK: - Circular

/// Ring + icon. Tracks the system tint so it adapts to the watch face's
/// accent. The percentage is shown via `widgetLabel` next to the corner /
/// outer edge of the complication.
struct CircularComplication: View {

  let identity: DeviceIdentity
  let battery: BatteryReading

  var body: some View {
    ZStack {
      Circle()
        .stroke(.tertiary, lineWidth: 4)
      Circle()
        .trim(from: 0, to: battery.level ?? 0)
        .stroke(.primary, style: StrokeStyle(lineWidth: 4, lineCap: .round))
        .rotationEffect(.degrees(-90))

      ZStack {
        Image(systemName: identity.model.systemImageName)
          .resizable()
          .scaledToFit()
          .padding(8)

        if battery.state == .charging {
          Image(systemName: "bolt.fill")
            .imageScale(.small)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .offset(y: -2)
        }
      }
    }
    .widgetLabel(percentLabel)
  }

  private var percentLabel: String {
    if let level = battery.level { "\(Int(level * 100))%" } else { "—" }
  }
}


// MARK: - Corner

/// Lives in the corner of an analog face. Big number, name on the curve.
struct CornerComplication: View {

  let identity: DeviceIdentity
  let battery: BatteryReading

  var body: some View {
    Text(percentLabel)
      .font(.system(.title3, design: .monospaced).weight(.medium))
      .widgetLabel(identity.name)
  }

  private var percentLabel: String {
    if let level = battery.level { "\(Int(level * 100))%" } else { "—" }
  }
}


// MARK: - Inline

/// Single-line strip at the top of a face. Icon + name + percent, with a
/// bolt suffix when charging.
struct InlineComplication: View {

  let identity: DeviceIdentity
  let battery: BatteryReading

  var body: some View {
    if battery.state == .charging {
      Label("\(identity.name) \(percentLabel)", systemImage: "bolt.fill")
    } else {
      Label("\(identity.name) \(percentLabel)", systemImage: identity.model.systemImageName)
    }
  }

  private var percentLabel: String {
    if let level = battery.level { "\(Int(level * 100))%" } else { "—" }
  }
}


// MARK: - Rectangular

/// Two-line block. Name on top, big percent below, ring on the left.
struct RectangularComplication: View {

  let identity: DeviceIdentity
  let battery: BatteryReading

  var body: some View {
    HStack(spacing: 8) {

      ZStack {
        Circle()
          .stroke(.tertiary, lineWidth: 3)
        Circle()
          .trim(from: 0, to: battery.level ?? 0)
          .stroke(.primary, style: StrokeStyle(lineWidth: 3, lineCap: .round))
          .rotationEffect(.degrees(-90))
        Image(systemName: identity.model.systemImageName)
          .resizable()
          .scaledToFit()
          .padding(4)
      }
      .frame(width: 32, height: 32)

      VStack(alignment: .leading, spacing: 0) {
        Text(identity.name)
          .font(.caption2)
          .lineLimit(1)

        HStack(alignment: .firstTextBaseline, spacing: 2) {
          Text(percentLabel)
            .font(.headline.monospaced())
          if battery.state == .charging {
            Image(systemName: "bolt.fill")
              .imageScale(.small)
          }
        }
      }
      Spacer(minLength: 0)
    }
  }

  private var percentLabel: String {
    if let level = battery.level { "\(Int(level * 100))%" } else { "—" }
  }
}


// MARK: - Preview

#Preview(as: .accessoryRectangular) {
  WatchBatteryWidget()
} timeline: {
  WatchDeviceEntry(
    date: .now,
    identity: DeviceIdentity(id: UUID(), hardwareID: "iPhone18,1"),
    battery: BatteryReading(level: 0.88, state: .charging, capturedAt: .now)
  )
}

#Preview(as: .accessoryCircular) {
  WatchBatteryWidget()
} timeline: {
  WatchDeviceEntry(
    date: .now,
    identity: DeviceIdentity(id: UUID(), hardwareID: "Mac17,2"),
    battery: BatteryReading(level: 0.42, state: .unplugged, capturedAt: .now)
  )
}

#Preview(as: .accessoryInline) {
  WatchBatteryWidget()
} timeline: {
  WatchDeviceEntry(
    date: .now,
    identity: DeviceIdentity(id: UUID(), hardwareID: "iPad17,3"),
    battery: BatteryReading(level: 0.63, state: .full, capturedAt: .now)
  )
}

#Preview(as: .accessoryCorner) {
  WatchBatteryWidget()
} timeline: {
  WatchDeviceEntry(
    date: .now,
    identity: DeviceIdentity(id: UUID(), hardwareID: "Watch7,12"),
    battery: BatteryReading(level: 0.92, state: .charging, capturedAt: .now)
  )
}
