import SwiftUI
import Charts

/// Minimal 24-hour battery curve — no axes, no labels, just the shape.
/// Designed to sit inline in a list row at ~60×24pt. Reuses the same
/// gauge gradient as the full chart so the visual language is consistent.
struct BatterySparkline: View {

  let events: [LogEvent]

  var body: some View {
    if points.isEmpty {
      Color.clear
    } else {
      chart
    }
  }
}


// MARK: - Chart

private extension BatterySparkline {

  var chart: some View {
    Chart {
      ForEach(points) { point in
        AreaMark(
          x: .value("Time", point.timestamp),
          y: .value("Level", point.level)
        )
        .foregroundStyle(
          .linearGradient(
            colors: [.purple.opacity(0.3), .purple.opacity(0.0)],
            startPoint: .top,
            endPoint: .bottom
          )
        )
        .interpolationMethod(.monotone)
      }

      ForEach(points) { point in
        LineMark(
          x: .value("Time", point.timestamp),
          y: .value("Level", point.level)
        )
        .foregroundStyle(.gaugeLineGradient)
        .lineStyle(StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
        .interpolationMethod(.monotone)
      }
    }
    .chartYScale(domain: 0...100)
    .chartXAxis(.hidden)
    .chartYAxis(.hidden)
    .chartLegend(.hidden)
    .chartPlotStyle { plot in
      plot.padding(0)
    }
  }
}


// MARK: - Data

private extension BatterySparkline {

  var points: [SparkPoint] {
    let cutoff = Date.now.addingTimeInterval(-24 * 3600)
    return events
      .compactMap { event -> SparkPoint? in
        guard event.kind == .post,
              let ts = event.timestamp,
              ts >= cutoff,
              let level = event.batteryLevel
        else { return nil }
        return SparkPoint(timestamp: ts, level: level * 100)
      }
      .sorted { $0.timestamp < $1.timestamp }
  }
}


private struct SparkPoint: Identifiable {
  let id = UUID()
  let timestamp: Date
  let level: Double
}
