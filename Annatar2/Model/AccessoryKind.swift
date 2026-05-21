import Foundation

/// What kind of Bluetooth accessory we're looking at. Used to pick an icon
/// and (eventually) tailor the row layout. Inferred from the BLE peripheral
/// name because the standard `appearance` characteristic isn't always
/// exposed.
enum AccessoryKind: String, Sendable, CaseIterable {

  case headphones
  case keyboard
  case mouse
  case trackpad
  case gamepad
  case generic

  static func inferred(from name: String) -> AccessoryKind {
    let lower = name.lowercased()
    if lower.contains("keyboard")  { return .keyboard }
    if lower.contains("trackpad")  { return .trackpad }
    if lower.contains("mouse")     { return .mouse }
    if lower.contains("controller") || lower.contains("dualsense") ||
       lower.contains("xbox")      || lower.contains("gamepad") {
      return .gamepad
    }
    if lower.contains("headphone") || lower.contains("airpods") ||
       lower.contains("beats")     || lower.contains("buds") ||
       lower.contains("audio")     || lower.contains("speaker") {
      return .headphones
    }
    return .generic
  }

  var systemImageName: String {
    switch self {
    case .headphones: "headphones"
    case .keyboard:   "keyboard"
    case .mouse:      "computermouse"
    case .trackpad:   "rectangle.and.hand.point.up.left"
    case .gamepad:    "gamecontroller"
    case .generic:    "dot.radiowaves.left.and.right"
    }
  }
}
