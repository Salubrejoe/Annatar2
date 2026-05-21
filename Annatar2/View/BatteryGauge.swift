import SwiftUI

/// Circular battery gauge with the Annatar identity: angular-gradient ring,
/// device icon at the centre, a tip dot at the leading edge of the stroke,
/// and a charging bolt above. Goes gray when the reading is stale.
///
/// Sizes proportionally to its frame. Pure — no `@Environment`, no
/// `ModelContext` — so it works identically in the app, in widgets, and
/// in complications.
struct BatteryGauge: View {

  let level: Double?
  let state: BatteryState
  let isStale: Bool
  let modelImageName: String

  var body: some View {
    GeometryReader { geo in
      let size      = min(geo.size.width, geo.size.height)
      let lineWidth = size / 9
      let iconSize  = size / 1.75

      ZStack {
        ring(lineWidth: lineWidth)
        tipDot(lineWidth: lineWidth, size: size)
        icon(iconSize: iconSize)
        bolt(size: size, lineWidth: lineWidth)
      }
      .frame(width: size, height: size)
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    .aspectRatio(1, contentMode: .fit)
  }
}


// MARK: - Pieces

private extension BatteryGauge {

  var gradient: AngularGradient {
    isStale ? .annatarStale : .annatarAccent
  }

  var tipColor: Color {
    isStale ? .gray : .pink   // matches stop 0.0 of `.annatarAccent`
  }

  func ring(lineWidth: Double) -> some View {
    Circle()
      .trim(from: 0, to: level ?? 0)
      .stroke(
        gradient,
        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .bevel)
      )
      .rotationEffect(.degrees(-90))
      .animation(.bouncy(duration: 1.0), value: level)
  }

  func tipDot(lineWidth: Double, size: Double) -> some View {
    Circle()
      .fill(tipColor)
      .frame(width: lineWidth, height: lineWidth)
      .offset(y: -size / 2)
  }

  func icon(iconSize: Double) -> some View {
    Image(systemName: modelImageName)
      .resizable()
      .scaledToFit()
      .frame(width: iconSize, height: iconSize)
  }

  @ViewBuilder
  func bolt(size: Double, lineWidth: Double) -> some View {
    if state == .charging {
      Image(systemName: "bolt.circle.fill")
        .imageScale(.small)
        .fontWeight(.light)
//        .frame(width: size, height: size, alignment: .top)
        .offset(y: -size/2)
    }
  }
}


// MARK: - Preview

#Preview("States") {
  HStack(spacing: 16) {
    BatteryGauge(level: 0.88, state: .charging,  isStale: false, modelImageName: "iphone")
    BatteryGauge(level: 0.42, state: .unplugged, isStale: false, modelImageName: "ipad.landscape")
    BatteryGauge(level: 0.18, state: .unplugged, isStale: true,  modelImageName: "macbook")
    BatteryGauge(level: nil,  state: .unknown,   isStale: true,  modelImageName: "questionmark")
  }
  .frame(height: 80)
  .padding()
}
