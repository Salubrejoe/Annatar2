import Foundation

enum BatteryState: Int, Codable, Sendable, CaseIterable {
  case unknown   = 0
  case unplugged = 1
  case charging  = 2
  case full      = 3
}
