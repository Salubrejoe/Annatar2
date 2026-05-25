import SwiftUI
import SwiftData

/// Activity tab — root level.
///
/// Shows one row per device with a summary of its most recent event.
/// Tap a row to drill into the full chronological log for that device.
struct LogView: View {

  @Query(sort: \Device.capturedAt, order: .reverse)
  private var devices: [Device]

  @Query(sort: \LogEvent.timestamp, order: .reverse)
  private var events: [LogEvent]

  var body: some View {
    NavigationStack {
      List {
        if devicesWithEvents.isEmpty {
          emptyState
        } else {
          ForEach(devicesWithEvents) { device in
            if let identity = device.identity {
              NavigationLink {
                DeviceLogView(deviceID: identity.id, deviceName: identity.name)
              } label: {
                DeviceSummaryRow(
                  identity: identity,
                  events: eventsByDevice[identity.id] ?? []
                )
              }
            }
          }
        }
      }
      .navigationTitle("Activity")
    }
  }
}


// MARK: - Derived

private extension LogView {

  /// All events grouped by source device — built once per body to avoid
  /// recomputing inside each row.
  var eventsByDevice: [UUID: [LogEvent]] {
    Dictionary(grouping: events) { $0.sourceDeviceID ?? UUID() }
  }

  /// Devices that have at least one event in the log, ordered by the
  /// timestamp of their latest event (busiest first).
  var devicesWithEvents: [Device] {
    let activeIDs = Set(events.compactMap { $0.sourceDeviceID })
    let activeDevices = devices.filter {
      guard let id = $0.id else { return false }
      return activeIDs.contains(id)
    }
    return activeDevices.sorted {
      let lhs = eventsByDevice[$0.id ?? UUID()]?.first?.timestamp ?? .distantPast
      let rhs = eventsByDevice[$1.id ?? UUID()]?.first?.timestamp ?? .distantPast
      return lhs > rhs
    }
  }

  var emptyState: some View {
    ContentUnavailableView(
      "No activity yet",
      systemImage: "clock.arrow.circlepath",
      description: Text("Foreground/background transitions, battery posts, and refresh requests will appear here.")
    )
    .listRowBackground(Color.clear)
    .listRowSeparator(.hidden)
  }
}


// MARK: - Summary row

private struct DeviceSummaryRow: View {

  let identity: DeviceIdentity
  let events: [LogEvent]

  var body: some View {
    HStack(spacing: 12) {
      Image(systemName: identity.model.systemImageName)
        .font(.title2)
        .foregroundStyle(.secondary)
        .frame(width: 32)

      VStack(alignment: .leading, spacing: 2) {
        Text(identity.name)
          .font(.body)
          .lineLimit(1)

        if let event = latestEvent {
          HStack(spacing: 4) {
            Image(systemName: event.kind.systemImageName)
              .imageScale(.small)
              .foregroundStyle(kindColor(event.kind))
            Text(summary(of: event))
              .font(.caption)
              .foregroundStyle(.secondary)
              .lineLimit(1)
          }
        } else {
          Text("No activity yet")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }

      Spacer(minLength: 8)

      VStack(alignment: .trailing, spacing: 2) {
        BatterySparkline(events: events)
          .frame(width: 60, height: 24)
        if let ts = latestEvent?.timestamp {
          Text(ts, format: .relative(presentation: .named, unitsStyle: .abbreviated))
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
      }
    }
    .padding(.vertical, 4)
  }

  private var latestEvent: LogEvent? { events.first }

  private func summary(of event: LogEvent) -> String {
    switch event.kind {
    case .post:
      let lvl = event.batteryLevel.map { "\(Int($0 * 100))%" } ?? "—"
      if let state = event.batteryState?.shortLabel {
        return "Posted \(lvl) • \(state)"
      }
      return "Posted \(lvl)"
    case .foreground:       return "Opened"
    case .background:       return "Backgrounded"
    case .refreshRequested: return "Asked for refresh"
    case .unknown:          return "Unknown"
    }
  }

  private func kindColor(_ kind: LogEventKind) -> Color {
    switch kind.tint {
    case "blue":   .blue
    case "green":  .green
    case "purple": .purple
    case "gray":   .gray
    default:       .secondary
    }
  }
}


// MARK: - Per-device detail view

struct DeviceLogView: View {

  let deviceID: UUID
  let deviceName: String

  @Query private var events: [LogEvent]
  @Query(sort: \Device.capturedAt, order: .reverse) private var devices: [Device]

  init(deviceID: UUID, deviceName: String) {
    self.deviceID = deviceID
    self.deviceName = deviceName
    _events = Query(
      filter: #Predicate<LogEvent> { $0.sourceDeviceID == deviceID },
      sort: [SortDescriptor(\.timestamp, order: .reverse)]
    )
  }

  var body: some View {
    List {
      Section {
        BatteryChart(events: events)
          .padding(.vertical, 8)
          .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 12, trailing: 16))
          .listRowBackground(Color.clear)
          .listRowSeparator(.hidden)
      }

      if events.isEmpty {
        ContentUnavailableView(
          "No activity",
          systemImage: "clock",
          description: Text("This device hasn't recorded anything yet.")
        )
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
      } else {
        Section {
          ForEach(events) { event in
            LogEventDetailRow(event: event, deviceNameLookup: deviceName(for:))
          }
        } header: {
          Text("\(events.count) events")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }
    }
    .navigationTitle(deviceName)
    #if os(iOS) || os(visionOS)
    .navigationBarTitleDisplayMode(.inline)
    #endif
  }

  private func deviceName(for id: UUID) -> String {
    devices.first(where: { $0.id == id })?.identity?.name ?? "Unknown"
  }
}


// MARK: - Detail row

private struct LogEventDetailRow: View {

  let event: LogEvent
  let deviceNameLookup: (UUID) -> String

  var body: some View {
    HStack(spacing: 12) {
      Image(systemName: event.kind.systemImageName)
        .foregroundStyle(kindColor)
        .frame(width: 22)

      VStack(alignment: .leading, spacing: 2) {
        Text(headline)
          .font(.callout)
        Text(timestampString)
          .font(.caption2.monospacedDigit())
          .foregroundStyle(.secondary)
      }

      Spacer(minLength: 0)
    }
    .padding(.vertical, 2)
  }

  private var headline: String {
    switch event.kind {
    case .post:
      let lvl = event.batteryLevel.map { "\(Int($0 * 100))%" } ?? "—"
      if let state = event.batteryState?.shortLabel {
        return "Posted \(lvl) • \(state)"
      }
      return "Posted \(lvl)"
    case .foreground:       return "Opened"
    case .background:       return "Backgrounded"
    case .refreshRequested:
      let target = event.targetDeviceID.map(deviceNameLookup) ?? "another device"
      return "Asked \(target) to refresh"
    case .unknown:          return "Unknown event"
    }
  }

  private var timestampString: String {
    guard let ts = event.timestamp else { return "—" }
    return ts.formatted(date: .abbreviated, time: .shortened)
  }

  private var kindColor: Color {
    switch event.kind.tint {
    case "blue":   .blue
    case "green":  .green
    case "purple": .purple
    case "gray":   .gray
    default:       .secondary
    }
  }
}


#Preview {
  LogView()
    .modelContainer(AnnatarSchema.makePreviewContainer())
}
