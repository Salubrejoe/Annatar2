import Foundation

/// A single snapshot of a device's battery, with no identity attached.
///
/// `level` is `nil` when the platform can't report a meaningful percentage
/// (simulator, unplugged Mac with no battery, denied permission, etc.).
struct BatteryReading: Sendable, Equatable {
  let level: Double?
  let state: BatteryState
  let capturedAt: Date

  init(level: Double?, state: BatteryState, capturedAt: Date = .now) {
    self.level = level
    self.state = state
    self.capturedAt = capturedAt
  }

  static let unknown = BatteryReading(level: nil, state: .unknown)
}


// MARK: - Display helpers

extension BatteryReading {

  /// True when the reading is older than the freshness window — the gauge
  /// should desaturate to gray to signal "this isn't current any more".
  var isStale: Bool {
    Date.now.timeIntervalSince(capturedAt) > 12 * 60 * 60
  }

  /// Compact "last seen" string. Mirrors the original's behaviour but with
  /// the broken thresholds fixed: `< 5 min` → "now", same day → time of
  /// day, yesterday → "yesterday", older → "Nd".
  var displayUpdatedAt: String {
    let minutes = Date.now.timeIntervalSince(capturedAt) / 60
    if minutes < 5    { return "now" }
    if minutes < 1440 { return capturedAt.formatted(date: .omitted, time: .shortened) }
    if minutes < 2880 { return "yesterday" }
    return "\(Int(minutes / 1440))d"
  }
}
