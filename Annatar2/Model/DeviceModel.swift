import Foundation

enum DeviceModel: String, Codable, Sendable, CaseIterable {
  case iPhone
  case iPad
  case watch
  case mac
  case unknown

  var systemImageName: String {
    switch self {
    case .iPhone:  "iphone"
    case .iPad:    "ipad.landscape"
    case .watch:   "applewatch.side.right"
    case .mac:     "macbook"
    case .unknown: "questionmark"
    }
  }
}
