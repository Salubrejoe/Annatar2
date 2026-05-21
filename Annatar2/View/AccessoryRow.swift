import SwiftUI

/// Compact horizontal row for a Bluetooth accessory. Deliberately distinct
/// from `DeviceCell`: smaller, row-shaped, no large gauge — these aren't
/// part of the synced fleet, they're nearby peripherals.
struct AccessoryRow: View {

  let accessory: Accessory

  var body: some View {
    HStack(spacing: 12) {

      ring
        .frame(width: 36, height: 36)

      VStack(alignment: .leading, spacing: 1) {
        Text(accessory.name)
          .font(.subheadline)
          .lineLimit(1)
        Text(percentLabel)
          .font(.caption.monospaced())
          .foregroundStyle(.secondary)
      }

      Spacer(minLength: 0)
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 10)
    .background(
      RoundedRectangle(cornerRadius: 16, style: .continuous)
        .fill(.background.tertiary)
    )
  }
}


// MARK: - Pieces

private extension AccessoryRow {

  var ring: some View {
    ZStack {
      Circle()
        .stroke(.quaternary, lineWidth: 3)

      Circle()
        .trim(from: 0, to: accessory.batteryLevel ?? 0)
        .stroke(
          AngularGradient.annatarAccent,
          style: StrokeStyle(lineWidth: 3, lineCap: .round)
        )
        .rotationEffect(.degrees(-90))

      Image(systemName: accessory.kind.systemImageName)
        .imageScale(.small)
    }
  }

  var percentLabel: String {
    if let level = accessory.batteryLevel {
      "\(Int(level * 100))%"
    } else {
      "—"
    }
  }
}


#Preview {
  VStack(spacing: 8) {
    AccessoryRow(accessory: Accessory(
      id: UUID(), name: "Magic Keyboard", kind: .keyboard,
      batteryLevel: 0.62, lastUpdatedAt: .now
    ))
    AccessoryRow(accessory: Accessory(
      id: UUID(), name: "Sony WH-1000XM5", kind: .headphones,
      batteryLevel: 0.88, lastUpdatedAt: .now
    ))
    AccessoryRow(accessory: Accessory(
      id: UUID(), name: "DualSense Controller", kind: .gamepad,
      batteryLevel: 0.34, lastUpdatedAt: .now
    ))
  }
  .padding()
}
