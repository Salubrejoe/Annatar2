import SwiftUI
import SwiftData

/// Watch main view: a vertically-paged TabView with one cell per device.
/// Crown-scrollable. Tap any cell to ask that device to push a fresh
/// reading — same `DeviceWriter.requestRefresh` path as the iPhone app.
struct WatchMainView: View {

  @Environment(\.modelContext) private var context
  @Query(sort: [SortDescriptor(\Device.capturedAt, order: .reverse)])
  private var devices: [Device]

  @State private var pendingRequests: [UUID: Date] = [:]
  private let refreshTimeout: Duration = .seconds(15)

  var body: some View {
    TabView {
      if devices.isEmpty {
        emptyState
      } else {
        ForEach(devices) { device in
          if let identity = device.identity {
            cell(for: device, identity: identity)
          }
        }
      }
    }
    .tabViewStyle(.verticalPage)
    .onChange(of: devices) { _, newDevices in
      pruneSucceededRequests(in: newDevices)
    }
  }
}


// MARK: - Cell

private extension WatchMainView {

  func cell(for device: Device, identity: DeviceIdentity) -> some View {
    let pending = pendingRequests[identity.id] != nil

    return WatchCell(identity: identity, battery: device.battery)
      .opacity(pending ? 0.4 : 1)
      .overlay { if pending { ProgressView() } }
      .contentShape(Rectangle())
      .onTapGesture {
        tap(device, identity: identity)
      }
  }

  var emptyState: some View {
    VStack(spacing: 8) {
      Image(systemName: "icloud.slash")
        .imageScale(.large)
        .foregroundStyle(.secondary)
      Text("No devices yet")
        .font(.caption)
        .foregroundStyle(.secondary)
    }
  }
}


// MARK: - Tap behaviour

private extension WatchMainView {

  func tap(_ device: Device, identity: DeviceIdentity) {
    // Tap on our own watch cell — refresh inline, no round-trip.
    if identity.id == LocalDeviceReader.identity.id {
      try? DeviceWriter.refresh(in: context)
      return
    }

    let requestTime = Date.now
    pendingRequests[identity.id] = requestTime

    try? DeviceWriter.requestRefresh(for: identity.id, in: context)

    Task { @MainActor in
      try? await Task.sleep(for: refreshTimeout)
      if pendingRequests[identity.id] == requestTime {
        pendingRequests.removeValue(forKey: identity.id)
      }
    }
  }

  func pruneSucceededRequests(in newDevices: [Device]) {
    for (id, requestTime) in pendingRequests {
      if let device = newDevices.first(where: { $0.id == id }),
         let capturedAt = device.capturedAt,
         capturedAt > requestTime {
        pendingRequests.removeValue(forKey: id)
      }
    }
  }
}


// MARK: - WatchCell

/// Full-screen page for a single device. Big gauge, percent below, name
/// + last-updated at the bottom.
struct WatchCell: View {

  let identity: DeviceIdentity
  let battery: BatteryReading

  var body: some View {
    VStack(spacing: 6) {

      BatteryGauge(
        level:          battery.level,
        state:          battery.state,
        isStale:        battery.isStale,
        modelImageName: identity.model.systemImageName
      )
      .frame(width: 80, height: 80)

      Text(percentLabel)
        .font(.title2.monospaced())
        .contentTransition(.numericText())

      VStack(spacing: 2) {
        Text(identity.name)
          .font(.caption)
          .lineLimit(1)
          .minimumScaleFactor(0.8)
        Text(battery.displayUpdatedAt)
          .font(.caption2)
          .foregroundStyle(.secondary)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.horizontal, 4)
  }

  private var percentLabel: String {
    if let level = battery.level { "\(Int(level * 100))%" } else { "—" }
  }
}


#Preview {
  WatchMainView()
    .modelContainer(AnnatarSchema.makePreviewContainer())
}
