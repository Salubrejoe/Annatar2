import SwiftUI
import SwiftData
#if canImport(UIKit)
import UIKit
#endif

struct MainView: View {

  @Environment(\.modelContext) private var context
  @Query(sort: [SortDescriptor(\Device.capturedAt, order: .reverse)])
  private var devices: [Device]

  /// Matches the standard small-widget footprint so a cell here looks
  /// identical to a cell on the home screen.
  private let cellSize: CGFloat = 158
  private let spacing:  CGFloat = 12
  private let maxColumns: Int = 4

  /// In-flight refresh requests: deviceID → moment the request was sent.
  /// A success is detected when the device's `capturedAt` advances past
  /// the request time; otherwise the entry is cleared on timeout.
  @State private var pendingRequests: [UUID: Date] = [:]

  /// Name of the device that couldn't be reached, or nil. Drives the
  /// alert. A name (not an id) so the alert message can read naturally.
  @State private var unreachableDeviceName: String?

  /// How long to wait for a response before declaring the device
  /// unreachable. CloudKit silent-push round-trip is usually 1–5s, so 15s
  /// is generous enough that a brief delay isn't mis-classified.
  private let refreshTimeout: Duration = .seconds(15)

  var body: some View {
    NavigationStack {
      ScrollView {
        LazyVGrid(columns: columns, spacing: spacing) {
          ForEach(devices) { device in
            if let identity = device.identity {
              cell(for: device, identity: identity)
            }
          }
        }
        .frame(maxWidth: maxGridWidth)
        .frame(maxWidth: .infinity)
        .padding()
      }
      .navigationTitle("Annatar")
      .toolbar {
        Button("Refresh") {
          try? DeviceWriter.refresh(in: context)
        }
      }
    }
    .onChange(of: devices) { _, newDevices in
      pruneSucceededRequests(in: newDevices)
    }
    .alert(
      "Couldn't reach \(unreachableDeviceName ?? "device")",
      isPresented: alertBinding
    ) {
      Button("OK", role: .cancel) { }
    } message: {
      Text("Open Annatar on that device to push a fresh reading.")
    }
  }
}


// MARK: - Cell

private extension MainView {

  func cell(for device: Device, identity: DeviceIdentity) -> some View {
    let pending = pendingRequests[identity.id] != nil

    return Button {
      tap(device, identity: identity)
    } label: {
      DeviceCell(identity: identity, battery: device.battery)
        .frame(width: cellSize, height: cellSize)
        .background(
          RoundedRectangle(cornerRadius: 32, style: .continuous)
            .fill(.background.secondary)
        )
        .overlay(pendingOverlay(visible: pending))
    }
    .buttonStyle(.plain)
    .disabled(pending)
  }

  @ViewBuilder
  func pendingOverlay(visible: Bool) -> some View {
    if visible {
      ZStack {
        RoundedRectangle(cornerRadius: 32, style: .continuous)
          .fill(.background.tertiary)
        ProgressView()
      }
    }
  }
}


// MARK: - Tap behaviour

private extension MainView {

  func tap(_ device: Device, identity: DeviceIdentity) {
    haptic()

    // Tap on our own cell — no remote round-trip needed.
    if identity.id == LocalDeviceReader.identity.id {
      try? DeviceWriter.refresh(in: context)
      return
    }

    let requestTime = Date.now
    pendingRequests[identity.id] = requestTime

    try? DeviceWriter.requestRefresh(for: identity.id, in: context)

    Task { @MainActor in
      try? await Task.sleep(for: refreshTimeout)

      // If the entry is still our request (user didn't re-tap with a newer
      // request, and the @Query change handler didn't clear it on success),
      // the device is unreachable.
      if pendingRequests[identity.id] == requestTime {
        pendingRequests.removeValue(forKey: identity.id)
        unreachableDeviceName = identity.name
      }
    }
  }

  /// Clear any pending request whose target has refreshed since the
  /// request was sent. Called whenever `@Query` delivers new data.
  func pruneSucceededRequests(in newDevices: [Device]) {
    for (id, requestTime) in pendingRequests {
      if let device = newDevices.first(where: { $0.id == id }),
         let capturedAt = device.capturedAt,
         capturedAt > requestTime {
        pendingRequests.removeValue(forKey: id)
      }
    }
  }

  func haptic() {
    #if canImport(UIKit) && !os(watchOS)
    UIImpactFeedbackGenerator(style: .light).impactOccurred()
    #endif
  }
}


// MARK: - Layout

private extension MainView {

  var columns: [GridItem] {
    [GridItem(.adaptive(minimum: cellSize, maximum: cellSize), spacing: spacing)]
  }

  var maxGridWidth: CGFloat {
    CGFloat(maxColumns) * cellSize + CGFloat(maxColumns - 1) * spacing
  }

  var alertBinding: Binding<Bool> {
    Binding(
      get: { unreachableDeviceName != nil },
      set: { if !$0 { unreachableDeviceName = nil } }
    )
  }
}


#Preview {
  MainView()
    .modelContainer(AnnatarSchema.makePreviewContainer())
}
