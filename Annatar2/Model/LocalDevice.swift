import Foundation

/// A full local-device snapshot: who we are + what our battery looks like.
struct LocalDevice: Sendable, Equatable {
  let identity: DeviceIdentity
  let battery: BatteryReading

  static func current() -> LocalDevice {
    LocalDevice(
      identity: LocalDeviceReader.identity,
      battery: LocalDeviceReader.readBattery()
    )
  }
}
