import SwiftUI

/// The single cell view that's reused everywhere a device is shown: in the
/// app's main grid, in the small home-screen widget, in the Mac menu bar,
/// in watch complications (rectangular family).
///
/// Pure — takes a `DeviceIdentity` + `BatteryReading` and renders. No
/// background of its own: callers add the rounded surface (the app wraps
/// it; the widget supplies `.containerBackground`).
struct DeviceCell: View {

  let identity: DeviceIdentity
  let battery: BatteryReading

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {

      BatteryGauge(
        level:          battery.level,
        state:          battery.state,
        isStale:        battery.isStale,
        modelImageName: identity.model.systemImageName
      )
      .frame(maxWidth: 48, maxHeight: 48, alignment: .leading)
      .frame(maxWidth: .infinity, alignment: .leading)

      Spacer(minLength: 0)

      VStack(alignment: .leading, spacing: 2) {

        Text(percentLabel)
          .font(.title)
          .fontDesign(.monospaced)
          .contentTransition(.numericText())

        HStack(alignment: .firstTextBaseline, spacing: 4) {
          Text(identity.name)
            .font(.body)
            .lineLimit(1)

          Text(battery.displayUpdatedAt)
            .font(.footnote)
            .foregroundStyle(updatedAtStyle)
        }
      }
    }
    .padding()
  }
}


// MARK: - Labels & styles

private extension DeviceCell {

  var percentLabel: String {
    if let level = battery.level {
      "\(Int(level * 100))%"
    } else {
      "—"
    }
  }

  var updatedAtStyle: AngularGradient {
    battery.isStale ? .annatarStale : .annatarAccent
  }
}


// MARK: - Preview

#Preview("Cell") {
  let identity = DeviceIdentity(id: UUID(), hardwareID: "iPhone16,2")
  let reading  = BatteryReading(level: 0.67, state: .charging, capturedAt: .now)

  DeviceCell(identity: identity, battery: reading)
    .frame(width: 170, height: 170)
    .background(
      RoundedRectangle(cornerRadius: 20, style: .continuous)
        .fill(.background.secondary)
    )
    .padding()
}
