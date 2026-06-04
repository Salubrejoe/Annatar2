#if os(macOS)
import SwiftUI
import SwiftData
import AppKit

/// macOS menu-bar curtain. Tapping the menu-bar item drops this view
/// down — a tight version of the iOS grid, with a compact footer of
/// gear / refresh / quit buttons. No NavigationStack: the view *is*
/// the chrome.
struct MacMenuBarView: View {

  @Environment(\.modelContext) private var context
  @Environment(BluetoothScanner.self) private var scanner

  @Query(sort: [SortDescriptor(\Device.capturedAt, order: .reverse)])
  private var devices: [Device]

  @State private var pendingRequests: [UUID: Date] = [:]
  @State private var unreachableDeviceName: String?
  @State private var showingSettings = false

  private let cellSize: CGFloat = 148
  private let spacing:  CGFloat = 12

  var body: some View {
    VStack(spacing: 0) {
      header
      Divider()
      content
      if !scanner.accessories.isEmpty {
        Divider()
        accessoriesSection
      }
      Divider()
      footer
    }
    .frame(width: 2 * cellSize + spacing + 32)
    .background(.regularMaterial)
    .onAppear {
      try? DeviceWriter.refresh(in: context)
      scanner.refresh()
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
    .sheet(isPresented: $showingSettings) {
      SettingsView()
        .environment(scanner)
    }
  }
}


// MARK: - Header

private extension MacMenuBarView {

  var header: some View {
    HStack(spacing: 8) {
      Image(systemName: "minus.plus.batteryblock.stack.fill")
        .foregroundStyle(AngularGradient.annatarAccent)
      Text("Annatar")
        .font(.headline)
      Spacer()
    }
    .padding(.horizontal, 14)
    .padding(.vertical, 10)
  }
}


// MARK: - Content (grid)

private extension MacMenuBarView {

  var content: some View {
    ScrollView {
      LazyVGrid(columns: columns, spacing: spacing) {
        ForEach(devices) { device in
          if let identity = device.identity {
            cell(for: device, identity: identity)
          }
        }
      }
      .padding(16)
    }
    .frame(minHeight: cellSize + 32, maxHeight: 2 * cellSize + spacing + 32)
  }

  var columns: [GridItem] {
    [GridItem(.adaptive(minimum: cellSize, maximum: cellSize), spacing: spacing)]
  }

  func cell(for device: Device, identity: DeviceIdentity) -> some View {
    let pending = pendingRequests[identity.id] != nil

    return Button {
      tap(device, identity: identity)
    } label: {
      DeviceCell(identity: identity, battery: device.battery)
        .padding(8)
        .frame(width: cellSize, height: cellSize)
        .background(
          RoundedRectangle(cornerRadius: 24, style: .continuous)
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
        RoundedRectangle(cornerRadius: 24, style: .continuous)
          .fill(.background.tertiary)
        ProgressView().controlSize(.small)
      }
    }
  }
}


// MARK: - Accessories

private extension MacMenuBarView {

  var accessoriesSection: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text("Accessories")
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 14)
        .padding(.top, 10)
      VStack(spacing: 6) {
        ForEach(scanner.accessories) { accessory in
          AccessoryRow(accessory: accessory)
        }
      }
      .padding(.horizontal, 12)
      .padding(.bottom, 10)
    }
  }
}


// MARK: - Footer

private extension MacMenuBarView {

  var footer: some View {
    HStack(spacing: 14) {
      Button {
        showingSettings = true
      } label: {
        Image(systemName: "gear")
      }
      .help("Settings")

      Button {
        try? DeviceWriter.refresh(in: context)
        scanner.refresh()
      } label: {
        Image(systemName: "arrow.clockwise")
      }
      .help("Refresh")

      Spacer()

      Button("Quit") {
        NSApplication.shared.terminate(nil)
      }
      .keyboardShortcut("q")
    }
    .buttonStyle(.borderless)
    .padding(.horizontal, 14)
    .padding(.vertical, 8)
  }
}


// MARK: - Tap behaviour (mirror of MainView)

private extension MacMenuBarView {

  func tap(_ device: Device, identity: DeviceIdentity) {
    if identity.id == LocalDeviceReader.identity.id {
      try? DeviceWriter.refresh(in: context)
      return
    }

    let requestTime = Date.now
    pendingRequests[identity.id] = requestTime

    try? DeviceWriter.requestRefresh(for: identity.id, in: context)

    Task { @MainActor in
      try? await Task.sleep(for: .seconds(15))
      if pendingRequests[identity.id] == requestTime {
        pendingRequests.removeValue(forKey: identity.id)
        unreachableDeviceName = identity.name
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

  var alertBinding: Binding<Bool> {
    Binding(
      get: { unreachableDeviceName != nil },
      set: { if !$0 { unreachableDeviceName = nil } }
    )
  }
}

#endif
