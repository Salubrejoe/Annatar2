import SwiftUI
import Charts

/// Battery curve for one device. Header changes when the user scrubs;
/// otherwise shows the chosen window and the current burn rate.
///
/// Faint green bands behind the curve mark periods when the device was
/// charging. The line uses the Annatar gauge gradient (pink at the top
/// → indigo at the bottom), so a glance at the colour conveys roughly
/// how high the value was at every point.
struct BatteryChart: View {

  let events: [LogEvent]

  @State private var range: ChartRange = .day
  @State private var selectedDate: Date?

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      rangePicker
      header
      content
    }
  }
}


// MARK: - Range picker

extension BatteryChart {

  enum ChartRange: String, CaseIterable, Identifiable {
    case day  = "24 Hours"
    case week = "7 Days"

    var id: String { rawValue }

    var seconds: TimeInterval {
      switch self {
      case .day:  24 * 3600
      case .week: 7 * 24 * 3600
      }
    }
  }
}

private extension BatteryChart {

  var rangePicker: some View {
    Picker("Range", selection: $range) {
      ForEach(ChartRange.allCases) { range in
        Text(range.rawValue).tag(range)
      }
    }
    .pickerStyle(.segmented)
    .labelsHidden()
    .onChange(of: range) { _, _ in
      selectedDate = nil   // scrub on the new window, not the old one
    }
  }
}


// MARK: - Header

private extension BatteryChart {

  @ViewBuilder
  var header: some View {
    if let selected = selectedPoint {
      HStack(spacing: 6) {
        Text(selected.timestamp, format: timestampFormat)
          .fontWeight(.medium)
        Text("•")
        Text("\(Int(selected.level))%")
          .fontDesign(.monospaced)
          .fontWeight(.semibold)
        if let label = selected.state.shortLabel {
          Text("•")
          Text(label)
        }
        Spacer()
      }
      .font(.caption)
      .foregroundStyle(.primary)
      .contentTransition(.numericText())
    } else {
      HStack(spacing: 6) {
        Text(range.rawValue)
        if let rate = burnRate {
          Text("•")
          Text(rate)
        }
        Spacer()
      }
      .font(.caption)
      .foregroundStyle(.secondary)
    }
  }

  /// Hour:minute on the day window, day+hour on the week window.
  var timestampFormat: Date.FormatStyle {
    switch range {
    case .day:  .dateTime.hour().minute()
    case .week: .dateTime.weekday(.abbreviated).hour().minute()
    }
  }
}


// MARK: - Chart / empty state

private extension BatteryChart {

  @ViewBuilder
  var content: some View {
    if points.isEmpty {
      emptyChart
    } else {
      chart
    }
  }

  var emptyChart: some View {
    RoundedRectangle(cornerRadius: 8, style: .continuous)
      .fill(.background.tertiary)
      .frame(height: 110)
      .overlay {
        Text("No battery posts in this window")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
  }

  var chart: some View {
    Chart {
      ForEach(chargingSegments, id: \.start) { segment in
        RectangleMark(
          xStart: .value("Start", segment.start),
          xEnd: .value("End", segment.end),
          yStart: .value("Min", 0),
          yEnd: .value("Max", 100)
        )
        .foregroundStyle(.green.opacity(0.12))
      }

      ForEach(points) { point in
        AreaMark(
          x: .value("Time", point.timestamp),
          y: .value("Level", point.level)
        )
        .foregroundStyle(
          .linearGradient(
            colors: [.purple.opacity(0.28), .purple.opacity(0.0)],
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
        .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
        .interpolationMethod(.monotone)
      }

      if let selected = selectedPoint {
        RuleMark(x: .value("Selected", selected.timestamp))
          .foregroundStyle(.secondary.opacity(0.4))
          .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))

        PointMark(
          x: .value("Selected", selected.timestamp),
          y: .value("Level", selected.level)
        )
        .foregroundStyle(.primary)
        .symbolSize(60)
      }
    }
    .chartYScale(domain: 0...100)
    .chartYAxis {
      AxisMarks(position: .leading, values: [0, 50, 100]) { _ in
        AxisValueLabel().font(.caption2).foregroundStyle(.secondary)
        AxisGridLine().foregroundStyle(.secondary.opacity(0.15))
      }
    }
    .chartXAxis {
      switch range {
      case .day:
        AxisMarks(values: .stride(by: .hour, count: 6)) { _ in
          AxisValueLabel(format: .dateTime.hour())
            .font(.caption2)
            .foregroundStyle(.secondary)
          AxisGridLine().foregroundStyle(.secondary.opacity(0.15))
        }
      case .week:
        AxisMarks(values: .stride(by: .day, count: 1)) { _ in
          AxisValueLabel(format: .dateTime.day())
            .font(.caption2)
            .foregroundStyle(.secondary)
          AxisGridLine().foregroundStyle(.secondary.opacity(0.15))
        }
      }
    }
    .chartXSelection(value: $selectedDate)
    .frame(height: 110)
  }
}


// MARK: - Derived data

private extension BatteryChart {

  /// Post events in the current window, mapped to chart points.
  var points: [ChartPoint] {
    let cutoff = Date.now.addingTimeInterval(-range.seconds)
    return events
      .compactMap { event -> ChartPoint? in
        guard event.kind == .post,
              let ts = event.timestamp,
              ts >= cutoff,
              let level = event.batteryLevel
        else { return nil }
        return ChartPoint(
          timestamp: ts,
          level: level * 100,
          state: event.batteryState ?? .unknown
        )
      }
      .sorted { $0.timestamp < $1.timestamp }
  }

  /// Contiguous stretches of time where the device was reported charging.
  var chargingSegments: [(start: Date, end: Date)] {
    var segments: [(start: Date, end: Date)] = []
    var currentStart: Date?

    for point in points {
      if point.state == .charging {
        if currentStart == nil { currentStart = point.timestamp }
      } else if let start = currentStart {
        segments.append((start: start, end: point.timestamp))
        currentStart = nil
      }
    }

    if let start = currentStart, let last = points.last {
      segments.append((start: start, end: last.timestamp))
    }
    return segments
  }

  /// The point closest in time to wherever the user is scrubbing.
  var selectedPoint: ChartPoint? {
    guard let selectedDate, !points.isEmpty else { return nil }
    return points.min { a, b in
      abs(a.timestamp.timeIntervalSince(selectedDate)) <
      abs(b.timestamp.timeIntervalSince(selectedDate))
    }
  }

  /// Instant rate of change over the last hour, regardless of chart range.
  /// "Full" wins when the device is reported at .full; otherwise "charging
  /// N%/hr" / "discharging N%/hr". Returns nil when the change is too small
  /// to meaningfully describe.
  var burnRate: String? {
    let cutoff = Date.now.addingTimeInterval(-3600)
    let lastHour: [ChartPoint] = events
      .compactMap { event -> ChartPoint? in
        guard event.kind == .post,
              let ts = event.timestamp,
              ts >= cutoff,
              let level = event.batteryLevel
        else { return nil }
        return ChartPoint(
          timestamp: ts,
          level: level * 100,
          state: event.batteryState ?? .unknown
        )
      }
      .sorted { $0.timestamp < $1.timestamp }

    guard let first = lastHour.first, let last = lastHour.last else { return nil }
    if last.state == .full { return "Full" }

    let hours = last.timestamp.timeIntervalSince(first.timestamp) / 3600
    guard hours > 0.1 else { return nil }

    let rate = (last.level - first.level) / hours
    if rate > 0.5  { return "charging \(Int(rate))%/hr" }
    if rate < -0.5 { return "discharging \(Int(abs(rate)))%/hr" }
    return nil
  }
}


// MARK: - Internal types

struct ChartPoint: Identifiable, Equatable {
  let id = UUID()
  let timestamp: Date
  let level: Double
  let state: BatteryState
}


// MARK: - Shared gradient

extension ShapeStyle where Self == LinearGradient {

  /// Vertical pink → purple → blue → indigo, matching the gauge ring's
  /// angular gradient projected onto a vertical axis. Used by the chart
  /// line and the sparkline so they read as the same visual language.
  static var gaugeLineGradient: LinearGradient {
    LinearGradient(
      stops: [
        .init(color: .pink,   location: 0.0),
        .init(color: .purple, location: 0.35),
        .init(color: .blue,   location: 0.7),
        .init(color: .indigo, location: 1.0),
      ],
      startPoint: .top,
      endPoint: .bottom
    )
  }
}


// MARK: - Preview

#Preview {
  let now = Date.now
  let mock: [LogEvent] = stride(from: 0, through: 24, by: 1).map { hour in
    let ts = now.addingTimeInterval(-Double(hour) * 3600)
    let level = max(0.1, min(1.0, 0.95 - Double(hour) * 0.03 + .random(in: -0.05...0.05)))
    let state: BatteryState = hour < 4 ? .charging : .unplugged
    return LogEvent(
      id: UUID(),
      timestamp: ts,
      sourceDeviceID: UUID(),
      kindRawValue: LogEventKind.post.rawValue,
      batteryLevel: level,
      batteryStateRawValue: state.rawValue
    )
  }
  return BatteryChart(events: mock)
    .padding()
}
