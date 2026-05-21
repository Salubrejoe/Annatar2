import Foundation
#if canImport(UIKit)
import UIKit
#endif
#if canImport(WatchKit)
import WatchKit
#endif
#if canImport(IOKit)
import IOKit.ps
#endif

/// The one place platform-specific battery code lives.
///
/// `identity` is computed once and cached. `readBattery()` is called on
/// every refresh and is the only function that touches platform APIs at
/// runtime.
enum LocalDeviceReader {}


// MARK: - iOS / iPadOS / visionOS

#if os(iOS) || os(visionOS)
extension LocalDeviceReader {

  static let identity: DeviceIdentity = DeviceIdentity(
    id: UIDevice.current.identifierForVendor ?? UUID(),
    hardwareID: Hardware.identifier(forSysctl: "hw.machine")
  )

  static func readBattery() -> BatteryReading {
    let device = UIDevice.current
    device.isBatteryMonitoringEnabled = true

    let raw = device.batteryLevel
    let level: Double? = raw >= 0 ? Double(raw) : nil
    let state = BatteryState(rawValue: device.batteryState.rawValue) ?? .unknown

    return BatteryReading(level: level, state: state)
  }
}
#endif


// MARK: - watchOS

#if os(watchOS)
extension LocalDeviceReader {

  static let identity: DeviceIdentity = DeviceIdentity(
    id: WKInterfaceDevice.current().identifierForVendor ?? UUID(),
    hardwareID: Hardware.identifier(forSysctl: "hw.machine")
  )

  static func readBattery() -> BatteryReading {
    let device = WKInterfaceDevice.current()
    device.isBatteryMonitoringEnabled = true

    let raw = device.batteryLevel
    let level: Double? = raw >= 0 ? Double(raw) : nil
    let state = BatteryState(rawValue: device.batteryState.rawValue) ?? .unknown

    return BatteryReading(level: level, state: state)
  }
}
#endif


// MARK: - macOS

#if os(macOS)
extension LocalDeviceReader {

  static let identity: DeviceIdentity = DeviceIdentity(
    id: MacIdentity.persistentUUID,
    hardwareID: Hardware.identifier(forSysctl: "hw.model")
  )

  static func readBattery() -> BatteryReading {
    MacPower.read()
  }
}

private enum MacIdentity {

  /// `identifierForVendor` doesn't exist on macOS, so we generate a UUID
  /// once and persist it in standard `UserDefaults` for this machine.
  static let persistentUUID: UUID = {
    let key = "annatar.localDeviceUUID"
    if let stored = UserDefaults.standard.string(forKey: key),
       let uuid = UUID(uuidString: stored) {
      return uuid
    }
    let new = UUID()
    UserDefaults.standard.set(new.uuidString, forKey: key)
    return new
  }()
}

private enum MacPower {

  static func read() -> BatteryReading {
    let info = IOPSCopyPowerSourcesInfo().takeRetainedValue()
    let sources = IOPSCopyPowerSourcesList(info).takeRetainedValue() as Array

    for source in sources {
      guard let desc = IOPSGetPowerSourceDescription(info, source)?
              .takeUnretainedValue() as? [String: Any]
      else { continue }

      let level: Double? = {
        if let current = desc[kIOPSCurrentCapacityKey] as? Int,
           let max = desc[kIOPSMaxCapacityKey] as? Int, max > 0 {
          return Double(current) / Double(max)
        }
        return nil
      }()

      let isCharging = (desc[kIOPSIsChargingKey] as? Bool) ?? false
      let state: BatteryState = {
        if isCharging { return .charging }
        if let l = level, l >= 0.99 { return .full }
        return .unplugged
      }()

      return BatteryReading(level: level, state: state)
    }

    return .unknown
  }
}
#endif
