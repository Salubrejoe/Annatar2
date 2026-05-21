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
      .frame(width: 52, height: 52)
      .frame(maxWidth: .infinity, alignment: .leading)

      Spacer(minLength: 4)

      VStack(alignment: .leading, spacing: 1) {

        Text(percentLabel)
          .font(.title2)
          .fontDesign(.monospaced)
          .fontWeight(.semibold)
          .contentTransition(.numericText())

        Text(identity.name)
          .font(.callout)
          .lineLimit(1)
          .minimumScaleFactor(0.7)
          .truncationMode(.tail)

        Text(battery.displayUpdatedAt)
          .font(.caption2)
          .foregroundStyle(updatedAtStyle)
      }
    }
    
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
  let identity = DeviceIdentity(id: UUID(), hardwareID: "Mac15,3")
  let reading  = BatteryReading(level: 0.67, state: .charging, capturedAt: .now)

  return DeviceCell(identity: identity, battery: reading)
    .frame(width: 158, height: 158)
    .background(
      RoundedRectangle(cornerRadius: 28, style: .continuous)
        .fill(.background.secondary)
    )
    .padding()
}
