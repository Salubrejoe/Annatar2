import Foundation

/// A Bluetooth accessory currently connected to *this* device. Unlike
/// `Device`, accessories are **not** CloudKit-synced — each host phone /
/// Mac sees its own paired peripherals, not the rest of the fleet's.
///
/// Lifetime is bound to the live BLE connection: when a peripheral
/// disconnects, its `Accessory` disappears from `BluetoothScanner`.
struct Accessory: Identifiable, Equatable, Sendable {

  let id: UUID
  let name: String
  let kind: AccessoryKind
  let batteryLevel: Double?
  let lastUpdatedAt: Date
}
