import Foundation

enum BatteryState: Int, Codable, Sendable, CaseIterable {
  case unknown   = 0
  case unplugged = 1
  case charging  = 2
  case full      = 3
}


// MARK: - Display

extension BatteryState {

  /// Short, human-readable label. `nil` for `.unknown` so the UI can
  /// hide the label entirely rather than show the unhelpful word.
  var shortLabel: String? {
    switch self {
    case .unknown:   nil
    case .unplugged: "Unplugged"
    case .charging:  "Charging"
    case .full:      "Full"
    }
  }
}
