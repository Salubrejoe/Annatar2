import Foundation
import CoreBluetooth
import Observation

/// Discovers Bluetooth accessories that expose the standard Battery
/// Service (`0x180F`) and reads their level characteristic (`0x2A19`).
///
/// AirPods, Apple Pencil, and other devices that use Apple's private
/// W1/H1/H2 chip protocol are intentionally invisible to third-party
/// apps and **won't** appear here. That's surfaced honestly in the
/// Settings sheet rather than silently swallowed.
///
/// Owned by the main app as a `let`; lifetime = process lifetime.
@Observable
final class BluetoothScanner: NSObject {

  private(set) var accessories: [Accessory] = []
  private(set) var state: BluetoothState = .unknown

  @ObservationIgnored private var centralManager: CBCentralManager!
  @ObservationIgnored private var connected: [UUID: CBPeripheral] = [:]
  @ObservationIgnored private var refreshTimer: Timer?

  private let batteryService = CBUUID(string: "180F")
  private let batteryLevel   = CBUUID(string: "2A19")

  override init() {
    super.init()
    centralManager = CBCentralManager(delegate: self, queue: .main)
  }

  deinit {
    refreshTimer?.invalidate()
    for peripheral in connected.values {
      centralManager.cancelPeripheralConnection(peripheral)
    }
  }

  /// Re-poll currently connected peripherals. Cheap to call; useful on
  /// scene phase becoming `.active` for snappier "I just opened the app"
  /// UX without waiting for the 60s timer tick.
  func refresh() {
    guard state == .scanning else { return }
    sweep()
  }
}


// MARK: - State

enum BluetoothState: Equatable {
  case unknown
  case unsupported     // Device has no Bluetooth radio
  case unauthorized    // User denied permission
  case poweredOff      // Bluetooth turned off
  case scanning        // All good
}


// MARK: - CBCentralManagerDelegate

extension BluetoothScanner: CBCentralManagerDelegate {

  func centralManagerDidUpdateState(_ central: CBCentralManager) {
    switch central.state {
    case .poweredOn:
      state = .scanning
      sweep()
      startRefreshTimer()
    case .unauthorized:
      state = .unauthorized
      clearAll()
    case .poweredOff:
      state = .poweredOff
      clearAll()
    case .unsupported:
      state = .unsupported
    case .resetting, .unknown:
      state = .unknown
    @unknown default:
      state = .unknown
    }
  }

  func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
    peripheral.discoverServices([batteryService])
  }

  func centralManager(
    _ central: CBCentralManager,
    didDisconnectPeripheral peripheral: CBPeripheral,
    error: Error?
  ) {
    connected.removeValue(forKey: peripheral.identifier)
    accessories.removeAll { $0.id == peripheral.identifier }
  }

  func centralManager(
    _ central: CBCentralManager,
    didFailToConnect peripheral: CBPeripheral,
    error: Error?
  ) {
    connected.removeValue(forKey: peripheral.identifier)
  }
}


// MARK: - CBPeripheralDelegate

extension BluetoothScanner: CBPeripheralDelegate {

  func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
    guard let services = peripheral.services else { return }
    for service in services where service.uuid == batteryService {
      peripheral.discoverCharacteristics([batteryLevel], for: service)
    }
  }

  func peripheral(
    _ peripheral: CBPeripheral,
    didDiscoverCharacteristicsFor service: CBService,
    error: Error?
  ) {
    guard let characteristics = service.characteristics else { return }
    for c in characteristics where c.uuid == batteryLevel {
      peripheral.readValue(for: c)
      if c.properties.contains(.notify) {
        peripheral.setNotifyValue(true, for: c)
      }
    }
  }

  func peripheral(
    _ peripheral: CBPeripheral,
    didUpdateValueFor characteristic: CBCharacteristic,
    error: Error?
  ) {
    guard error == nil,
          characteristic.uuid == batteryLevel,
          let raw = characteristic.value?.first
    else { return }

    let level = Double(min(raw, 100)) / 100.0
    upsert(peripheral: peripheral, batteryLevel: level)
  }
}


// MARK: - Internals

private extension BluetoothScanner {

  func sweep() {
    let peripherals = centralManager.retrieveConnectedPeripherals(
      withServices: [batteryService]
    )

    for peripheral in peripherals {
      // First sighting — wire up delegate and connect.
      if connected[peripheral.identifier] == nil {
        peripheral.delegate = self
        connected[peripheral.identifier] = peripheral
        centralManager.connect(peripheral, options: nil)
      }
      // Already connected — re-read in case the value drifted between pushes.
      else if peripheral.state == .connected {
        for service in peripheral.services ?? [] where service.uuid == batteryService {
          for c in service.characteristics ?? [] where c.uuid == batteryLevel {
            peripheral.readValue(for: c)
          }
        }
      }
    }
  }

  func startRefreshTimer() {
    refreshTimer?.invalidate()
    refreshTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
      self?.sweep()
    }
  }

  func clearAll() {
    refreshTimer?.invalidate()
    refreshTimer = nil
    for peripheral in connected.values {
      centralManager.cancelPeripheralConnection(peripheral)
    }
    connected.removeAll()
    accessories.removeAll()
  }

  func upsert(peripheral: CBPeripheral, batteryLevel: Double) {
    let id = peripheral.identifier
    let name = peripheral.name ?? "Bluetooth Accessory"

    let updated = Accessory(
      id: id,
      name: name,
      kind: .inferred(from: name),
      batteryLevel: batteryLevel,
      lastUpdatedAt: .now
    )

    if let index = accessories.firstIndex(where: { $0.id == id }) {
      accessories[index] = updated
    } else {
      accessories.append(updated)
    }
  }
}
