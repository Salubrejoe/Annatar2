import Foundation

/// The kinds of moments worth recording for the Activity tab.
///
/// All values are stable strings because they're persisted in CloudKit
/// (via `LogEvent.kindRawValue`) and must round-trip even if we add or
/// reorder cases later.
enum LogEventKind: String, Sendable, CaseIterable {

  /// A battery snapshot was written to the store (and pushed to CloudKit).
  case post

  /// The app became active — user is looking at it.
  case foreground

  /// The app left the foreground — backgrounded or swiped away.
  case background

  /// This device asked another device to push a fresh reading.
  case refreshRequested

  /// Fallback when we read a record with an unknown kind string (forward-compat).
  case unknown


  var systemImageName: String {
    switch self {
    case .post:             "arrow.up.circle.fill"
    case .foreground:       "eye.fill"
    case .background:       "moon.fill"
    case .refreshRequested: "arrow.triangle.2.circlepath"
    case .unknown:          "questionmark.circle"
    }
  }

  var displayName: String {
    switch self {
    case .post:             "Posted"
    case .foreground:       "Opened"
    case .background:       "Backgrounded"
    case .refreshRequested: "Asked for refresh"
    case .unknown:          "Unknown"
    }
  }

  var tint: String {
    // Returning a colour name string — view layer translates. Keeps this
    // file free of SwiftUI.
    switch self {
    case .post:             "blue"
    case .foreground:       "green"
    case .background:       "gray"
    case .refreshRequested: "purple"
    case .unknown:          "gray"
    }
  }
}
