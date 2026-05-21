import Foundation

/// Thin wrapper around POSIX `sysctlbyname` for reading the platform's
/// hardware identifier — `"hw.machine"` on iOS/watchOS/visionOS, `"hw.model"`
/// on macOS. Returns codes like `"iPhone16,2"` or `"Mac14,7"`.
enum Hardware {

  static func identifier(forSysctl key: String) -> String {
    // On iOS simulator, `hw.machine` returns the *host Mac's* identifier
    // ("arm64", etc.). The Simulator exports the simulated device's id via
    // an env var — prefer it when present.
    if let simulated = ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] {
      return simulated
    }

    var size: size_t = 0
    sysctlbyname(key, nil, &size, nil, 0)
    guard size > 0 else { return "" }

    var bytes = [CChar](repeating: 0, count: Int(size))
    sysctlbyname(key, &bytes, &size, nil, 0)
    return String(cString: bytes)
  }
}
