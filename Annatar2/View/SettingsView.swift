import SwiftUI

/// App settings sheet. Currently houses:
///   • A status banner for Bluetooth permission / power state.
///   • An honest explanation of why AirPods + Apple Pencil don't appear.
///   • App version / about.
struct SettingsView: View {

  @Environment(BluetoothScanner.self) private var scanner
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      Form {
        bluetoothStatusSection
        missingAccessoriesSection
        aboutSection
      }
      .navigationTitle("Settings")
      #if os(iOS) || os(visionOS)
      .navigationBarTitleDisplayMode(.inline)
      #endif
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("Done") { dismiss() }
        }
      }
    }
  }
}


// MARK: - Sections

private extension SettingsView {

  @ViewBuilder
  var bluetoothStatusSection: some View {
    switch scanner.state {
    case .unauthorized:
      Section {
        Label("Bluetooth permission denied", systemImage: "exclamationmark.triangle.fill")
          .foregroundStyle(.orange)
        Text("Annatar can't see nearby Bluetooth accessories without this. Re-enable it in System Settings → Bluetooth → Annatar.")
          .font(.callout)
      }
    case .poweredOff:
      Section {
        Label("Bluetooth is off", systemImage: "antenna.radiowaves.left.and.right.slash")
          .foregroundStyle(.secondary)
        Text("Turn Bluetooth on to see your nearby accessories.")
          .font(.callout)
      }
    case .unsupported:
      Section {
        Label("Bluetooth unavailable", systemImage: "antenna.radiowaves.left.and.right.slash")
          .foregroundStyle(.secondary)
      }
    case .scanning, .unknown:
      EmptyView()
    }
  }

  var missingAccessoriesSection: some View {
    Section {
      Text("AirPods and Apple Pencil use Apple's private W1, H1, and H2 chip protocols. Third-party apps cannot read their battery — that's an OS-level restriction, not a permission you can toggle.")
        .font(.callout)
      Text("Annatar shows any Bluetooth accessory that exposes the standard battery service: keyboards, mice, trackpads, controllers, and most non-Apple headphones. If Apple ever publishes a public API for AirPods, they'll appear automatically.")
        .font(.callout)
        .foregroundStyle(.secondary)
    } header: {
      Text("Why aren't my AirPods showing?")
    }
  }

  var aboutSection: some View {
    Section("About") {
      HStack {
        Text("Version")
        Spacer()
        Text(version)
          .foregroundStyle(.secondary)
      }
    }
  }

  var version: String {
    let info = Bundle.main.infoDictionary
    let short = info?["CFBundleShortVersionString"] as? String ?? "1.0"
    return short
  }
}
