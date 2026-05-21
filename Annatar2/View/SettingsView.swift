import SwiftUI

/// App settings sheet. Custom card-based layout — `Form` renders too
/// densely on macOS and doesn't separate sections visually enough for
/// what we want to communicate (especially the "AirPods can't show up"
/// explanation, which is the whole point of this screen).
struct SettingsView: View {

  @Environment(BluetoothScanner.self) private var scanner
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 16) {
          if let banner = bluetoothBanner {
            statusCard(banner)
          }
          accessoryInfoCard
          aboutCard
        }
        .padding(20)
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
    #if os(macOS)
    .frame(minWidth: 480, idealWidth: 520, minHeight: 540, idealHeight: 600)
    #endif
  }
}


// MARK: - Cards

private extension SettingsView {

  func statusCard(_ banner: StatusBanner) -> some View {
    HStack(alignment: .top, spacing: 12) {
      Image(systemName: banner.icon)
        .font(.title2)
        .foregroundStyle(banner.tone.color)
        .frame(width: 24)

      VStack(alignment: .leading, spacing: 4) {
        Text(banner.title)
          .font(.headline)
        if let detail = banner.detail {
          Text(detail)
            .font(.callout)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
        }
      }

      Spacer(minLength: 0)
    }
    .padding(16)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(card)
  }

  var accessoryInfoCard: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(spacing: 10) {
        Image(systemName: "questionmark.circle.fill")
          .font(.title2)
          .foregroundStyle(.tint)
          .frame(width: 24)
        Text("Why aren't my AirPods showing?")
          .font(.headline)
      }

      VStack(alignment: .leading, spacing: 10) {
        Text("AirPods and Apple Pencil use Apple's private W1, H1, and H2 chip protocols. Third-party apps cannot read their battery — that's an OS-level restriction, not a permission you can toggle.")
          .font(.callout)

        Text("Annatar shows any Bluetooth accessory that exposes the standard battery service: keyboards, mice, trackpads, controllers, and most non-Apple headphones. If Apple ever publishes a public API for AirPods, they'll appear automatically.")
          .font(.callout)
          .foregroundStyle(.secondary)
      }
      .fixedSize(horizontal: false, vertical: true)
      .padding(.leading, 34)
    }
    .padding(16)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(card)
  }

  var aboutCard: some View {
    HStack(spacing: 12) {
      Image(systemName: "minus.plus.batteryblock.stack.fill")
        .font(.title)
        .foregroundStyle(AngularGradient.annatarAccent)
        .frame(width: 32)

      VStack(alignment: .leading, spacing: 2) {
        Text("Annatar")
          .font(.headline)
        Text("Version \(versionString)")
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      Spacer(minLength: 0)
    }
    .padding(16)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(card)
  }

  var card: some View {
    RoundedRectangle(cornerRadius: 14, style: .continuous)
      .fill(.background.secondary)
  }

  var versionString: String {
    let info = Bundle.main.infoDictionary
    return info?["CFBundleShortVersionString"] as? String ?? "1.0"
  }
}


// MARK: - Banner state

private struct StatusBanner {
  let icon: String
  let title: String
  let detail: String?
  let tone: Tone

  enum Tone {
    case warning, info

    var color: Color {
      switch self {
      case .warning: .orange
      case .info:    .secondary
      }
    }
  }
}

private extension SettingsView {

  var bluetoothBanner: StatusBanner? {
    switch scanner.state {
    case .unauthorized:
      StatusBanner(
        icon: "exclamationmark.triangle.fill",
        title: "Bluetooth permission denied",
        detail: "Open System Settings → Privacy & Security → Bluetooth and turn Annatar on.",
        tone: .warning
      )
    case .poweredOff:
      StatusBanner(
        icon: "antenna.radiowaves.left.and.right.slash",
        title: "Bluetooth is off",
        detail: "Turn Bluetooth on to see your accessories.",
        tone: .info
      )
    case .unsupported:
      StatusBanner(
        icon: "antenna.radiowaves.left.and.right.slash",
        title: "Bluetooth unavailable",
        detail: "Annatar hasn't been granted access to the Bluetooth radio. Check System Settings → Privacy & Security → Bluetooth — if Annatar isn't listed, run `tccutil reset Bluetooth com.lorep.uk.Annatar2` in Terminal and relaunch.",
        tone: .warning
      )
    case .scanning, .unknown:
      nil
    }
  }
}
