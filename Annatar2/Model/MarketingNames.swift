import Foundation

/// Maps platform hardware identifiers (`"iPhone18,1"`, `"Mac17,2"`, ...) to
/// the marketing names Apple uses publicly ("iPhone 17 Pro", "MacBook Pro
/// 14” (M5)").
///
/// Apple does not publish this table — extend it as new devices ship. An
/// unknown identifier falls back to its device-family name via
/// `name(for:)`, so a missing entry never breaks the UI.
///
/// Source-of-truth references when updating:
///   • DeviceKit (https://github.com/devicekit/DeviceKit) — iPhone / iPad / Watch
///   • The Apple Wiki + AppleDB — Macs
enum MarketingNames {

  static func name(for hardwareID: String) -> String {
    table[hardwareID] ?? fallback(for: hardwareID)
  }

  static func category(for hardwareID: String) -> DeviceModel {
    switch true {
    case hardwareID.hasPrefix("iPhone"):                                    .iPhone
    case hardwareID.hasPrefix("iPad"):                                      .iPad
    case hardwareID.hasPrefix("Watch"):                                     .watch
    case hardwareID.hasPrefix("Mac"), hardwareID.hasPrefix("MacBook"),
         hardwareID.hasPrefix("iMac"), hardwareID.hasPrefix("Macmini"):     .mac
    default:                                                                .unknown
    }
  }
}


// MARK: - Fallback

private extension MarketingNames {

  static func fallback(for hardwareID: String) -> String {
    switch category(for: hardwareID) {
    case .iPhone:  "iPhone"
    case .iPad:    "iPad"
    case .watch:   "Apple Watch"
    case .mac:     "Mac"
    case .unknown: hardwareID.isEmpty ? "Unknown device" : hardwareID
    }
  }
}


// MARK: - The table

private extension MarketingNames {

  static let table: [String: String] = [

    // ──────────────────────────────────────────────────────────────────
    // iPhone
    // ──────────────────────────────────────────────────────────────────

    // Legacy (kept for completeness; fall-through is "iPhone" anyway)
    "iPhone8,1":  "iPhone 6s",
    "iPhone8,2":  "iPhone 6s Plus",
    "iPhone8,4":  "iPhone SE",
    "iPhone9,1":  "iPhone 7",
    "iPhone9,3":  "iPhone 7",
    "iPhone9,2":  "iPhone 7 Plus",
    "iPhone9,4":  "iPhone 7 Plus",
    "iPhone10,1": "iPhone 8",
    "iPhone10,4": "iPhone 8",
    "iPhone10,2": "iPhone 8 Plus",
    "iPhone10,5": "iPhone 8 Plus",
    "iPhone10,3": "iPhone X",
    "iPhone10,6": "iPhone X",
    "iPhone11,2": "iPhone XS",
    "iPhone11,4": "iPhone XS Max",
    "iPhone11,6": "iPhone XS Max",
    "iPhone11,8": "iPhone XR",

    // 2019 — iPhone 11
    "iPhone12,1": "iPhone 11",
    "iPhone12,3": "iPhone 11 Pro",
    "iPhone12,5": "iPhone 11 Pro Max",
    "iPhone12,8": "iPhone SE (2nd gen)",

    // 2020 — iPhone 12
    "iPhone13,1": "iPhone 12 mini",
    "iPhone13,2": "iPhone 12",
    "iPhone13,3": "iPhone 12 Pro",
    "iPhone13,4": "iPhone 12 Pro Max",

    // 2021 — iPhone 13
    "iPhone14,2": "iPhone 13 Pro",
    "iPhone14,3": "iPhone 13 Pro Max",
    "iPhone14,4": "iPhone 13 mini",
    "iPhone14,5": "iPhone 13",
    "iPhone14,6": "iPhone SE (3rd gen)",

    // 2022 — iPhone 14
    "iPhone14,7": "iPhone 14",
    "iPhone14,8": "iPhone 14 Plus",
    "iPhone15,2": "iPhone 14 Pro",
    "iPhone15,3": "iPhone 14 Pro Max",

    // 2023 — iPhone 15
    "iPhone15,4": "iPhone 15",
    "iPhone15,5": "iPhone 15 Plus",
    "iPhone16,1": "iPhone 15 Pro",
    "iPhone16,2": "iPhone 15 Pro Max",

    // 2024 — iPhone 16
    "iPhone17,1": "iPhone 16 Pro",
    "iPhone17,2": "iPhone 16 Pro Max",
    "iPhone17,3": "iPhone 16",
    "iPhone17,4": "iPhone 16 Plus",
    "iPhone17,5": "iPhone 16e",

    // 2025 — iPhone 17 / Air
    "iPhone18,1": "iPhone 17 Pro",
    "iPhone18,2": "iPhone 17 Pro Max",
    "iPhone18,3": "iPhone 17",
    "iPhone18,4": "iPhone Air",
    "iPhone18,5": "iPhone 17e",


    // ──────────────────────────────────────────────────────────────────
    // iPad
    // ──────────────────────────────────────────────────────────────────

    // iPad (mainline)
    "iPad7,11":   "iPad (7th gen)",
    "iPad7,12":   "iPad (7th gen)",
    "iPad11,6":   "iPad (8th gen)",
    "iPad11,7":   "iPad (8th gen)",
    "iPad12,1":   "iPad (9th gen)",
    "iPad12,2":   "iPad (9th gen)",
    "iPad13,18":  "iPad (10th gen)",
    "iPad13,19":  "iPad (10th gen)",
    "iPad15,7":   "iPad (A16)",
    "iPad15,8":   "iPad (A16)",

    // iPad mini
    "iPad11,1":   "iPad mini (5th gen)",
    "iPad11,2":   "iPad mini (5th gen)",
    "iPad14,1":   "iPad mini (6th gen)",
    "iPad14,2":   "iPad mini (6th gen)",
    "iPad16,1":   "iPad mini (A17 Pro)",
    "iPad16,2":   "iPad mini (A17 Pro)",

    // iPad Air
    "iPad11,3":   "iPad Air (3rd gen)",
    "iPad11,4":   "iPad Air (3rd gen)",
    "iPad13,1":   "iPad Air (4th gen)",
    "iPad13,2":   "iPad Air (4th gen)",
    "iPad13,16":  "iPad Air (5th gen)",
    "iPad13,17":  "iPad Air (5th gen)",
    "iPad14,8":   "iPad Air 11” (M2)",
    "iPad14,9":   "iPad Air 11” (M2)",
    "iPad14,10":  "iPad Air 13” (M2)",
    "iPad14,11":  "iPad Air 13” (M2)",
    "iPad15,3":   "iPad Air 11” (M3)",
    "iPad15,4":   "iPad Air 11” (M3)",
    "iPad15,5":   "iPad Air 13” (M3)",
    "iPad15,6":   "iPad Air 13” (M3)",
    "iPad16,8":   "iPad Air 11” (M4)",
    "iPad16,9":   "iPad Air 11” (M4)",
    "iPad16,10":  "iPad Air 13” (M4)",
    "iPad16,11":  "iPad Air 13” (M4)",

    // iPad Pro 11"
    "iPad8,1":    "iPad Pro 11” (1st gen)",
    "iPad8,2":    "iPad Pro 11” (1st gen)",
    "iPad8,3":    "iPad Pro 11” (1st gen)",
    "iPad8,4":    "iPad Pro 11” (1st gen)",
    "iPad8,9":    "iPad Pro 11” (2nd gen)",
    "iPad8,10":   "iPad Pro 11” (2nd gen)",
    "iPad13,4":   "iPad Pro 11” (3rd gen)",
    "iPad13,5":   "iPad Pro 11” (3rd gen)",
    "iPad13,6":   "iPad Pro 11” (3rd gen)",
    "iPad13,7":   "iPad Pro 11” (3rd gen)",
    "iPad14,3":   "iPad Pro 11” (M2)",
    "iPad14,4":   "iPad Pro 11” (M2)",
    "iPad16,3":   "iPad Pro 11” (M4)",
    "iPad16,4":   "iPad Pro 11” (M4)",
    "iPad17,1":   "iPad Pro 11” (M5)",
    "iPad17,2":   "iPad Pro 11” (M5)",

    // iPad Pro 12.9" / 13"
    "iPad8,5":    "iPad Pro 12.9” (3rd gen)",
    "iPad8,6":    "iPad Pro 12.9” (3rd gen)",
    "iPad8,7":    "iPad Pro 12.9” (3rd gen)",
    "iPad8,8":    "iPad Pro 12.9” (3rd gen)",
    "iPad8,11":   "iPad Pro 12.9” (4th gen)",
    "iPad8,12":   "iPad Pro 12.9” (4th gen)",
    "iPad13,8":   "iPad Pro 12.9” (5th gen)",
    "iPad13,9":   "iPad Pro 12.9” (5th gen)",
    "iPad13,10":  "iPad Pro 12.9” (5th gen)",
    "iPad13,11":  "iPad Pro 12.9” (5th gen)",
    "iPad14,5":   "iPad Pro 12.9” (M2)",
    "iPad14,6":   "iPad Pro 12.9” (M2)",
    "iPad16,5":   "iPad Pro 13” (M4)",
    "iPad16,6":   "iPad Pro 13” (M4)",
    "iPad17,3":   "iPad Pro 13” (M5)",
    "iPad17,4":   "iPad Pro 13” (M5)",


    // ──────────────────────────────────────────────────────────────────
    // Apple Watch
    // ──────────────────────────────────────────────────────────────────

    "Watch4,1":   "Apple Watch Series 4 (40mm)",
    "Watch4,2":   "Apple Watch Series 4 (44mm)",
    "Watch4,3":   "Apple Watch Series 4 (40mm)",
    "Watch4,4":   "Apple Watch Series 4 (44mm)",
    "Watch5,1":   "Apple Watch Series 5 (40mm)",
    "Watch5,2":   "Apple Watch Series 5 (44mm)",
    "Watch5,3":   "Apple Watch Series 5 (40mm)",
    "Watch5,4":   "Apple Watch Series 5 (44mm)",
    "Watch5,9":   "Apple Watch SE (40mm)",
    "Watch5,10":  "Apple Watch SE (44mm)",
    "Watch5,11":  "Apple Watch SE (40mm)",
    "Watch5,12":  "Apple Watch SE (44mm)",
    "Watch6,1":   "Apple Watch Series 6 (40mm)",
    "Watch6,2":   "Apple Watch Series 6 (44mm)",
    "Watch6,3":   "Apple Watch Series 6 (40mm)",
    "Watch6,4":   "Apple Watch Series 6 (44mm)",
    "Watch6,6":   "Apple Watch Series 7 (41mm)",
    "Watch6,7":   "Apple Watch Series 7 (45mm)",
    "Watch6,8":   "Apple Watch Series 7 (41mm)",
    "Watch6,9":   "Apple Watch Series 7 (45mm)",
    "Watch6,10":  "Apple Watch SE (2nd gen, 40mm)",
    "Watch6,11":  "Apple Watch SE (2nd gen, 44mm)",
    "Watch6,12":  "Apple Watch SE (2nd gen, 40mm)",
    "Watch6,13":  "Apple Watch SE (2nd gen, 44mm)",
    "Watch6,14":  "Apple Watch Series 8 (41mm)",
    "Watch6,15":  "Apple Watch Series 8 (45mm)",
    "Watch6,16":  "Apple Watch Series 8 (41mm)",
    "Watch6,17":  "Apple Watch Series 8 (45mm)",
    "Watch6,18":  "Apple Watch Ultra",
    "Watch7,1":   "Apple Watch Series 9 (41mm)",
    "Watch7,2":   "Apple Watch Series 9 (45mm)",
    "Watch7,3":   "Apple Watch Series 9 (41mm)",
    "Watch7,4":   "Apple Watch Series 9 (45mm)",
    "Watch7,5":   "Apple Watch Ultra 2",
    "Watch7,8":   "Apple Watch Series 10 (42mm)",
    "Watch7,9":   "Apple Watch Series 10 (46mm)",
    "Watch7,10":  "Apple Watch Series 10 (42mm)",
    "Watch7,11":  "Apple Watch Series 10 (46mm)",
    "Watch7,12":  "Apple Watch Ultra 3",
    "Watch7,13":  "Apple Watch SE (3rd gen, 40mm)",
    "Watch7,14":  "Apple Watch SE (3rd gen, 40mm)",
    "Watch7,15":  "Apple Watch SE (3rd gen, 44mm)",
    "Watch7,16":  "Apple Watch SE (3rd gen, 44mm)",
    "Watch7,17":  "Apple Watch Series 11 (42mm)",
    "Watch7,18":  "Apple Watch Series 11 (46mm)",
    "Watch7,19":  "Apple Watch Series 11 (42mm)",
    "Watch7,20":  "Apple Watch Series 11 (46mm)",


    // ──────────────────────────────────────────────────────────────────
    // Mac — Apple Silicon
    // ──────────────────────────────────────────────────────────────────

    // M1 era
    "MacBookAir10,1": "MacBook Air (M1)",
    "MacBookPro17,1": "MacBook Pro 13” (M1)",
    "Macmini9,1":     "Mac mini (M1)",
    "iMac21,1":       "iMac 24” (M1)",
    "iMac21,2":       "iMac 24” (M1)",
    "MacBookPro18,1": "MacBook Pro 16” (M1 Pro)",
    "MacBookPro18,2": "MacBook Pro 16” (M1 Max)",
    "MacBookPro18,3": "MacBook Pro 14” (M1 Pro)",
    "MacBookPro18,4": "MacBook Pro 14” (M1 Max)",
    "Mac13,1":        "Mac Studio (M1 Max)",
    "Mac13,2":        "Mac Studio (M1 Ultra)",

    // M2 era
    "Mac14,2":  "MacBook Air (M2)",
    "Mac14,3":  "Mac mini (M2)",
    "Mac14,5":  "MacBook Pro 14” (M2 Max)",
    "Mac14,6":  "MacBook Pro 16” (M2 Max)",
    "Mac14,7":  "MacBook Pro 13” (M2)",
    "Mac14,8":  "Mac Pro (M2 Ultra)",
    "Mac14,9":  "MacBook Pro 14” (M2 Pro)",
    "Mac14,10": "MacBook Pro 16” (M2 Pro)",
    "Mac14,12": "Mac mini (M2 Pro)",
    "Mac14,13": "Mac Studio (M2 Max)",
    "Mac14,14": "Mac Studio (M2 Ultra)",
    "Mac14,15": "MacBook Air 15” (M2)",

    // M3 era
    "Mac15,3":  "MacBook Pro 14” (M3)",
    "Mac15,4":  "iMac 24” (M3)",
    "Mac15,5":  "iMac 24” (M3)",
    "Mac15,6":  "MacBook Pro 14” (M3 Pro)",
    "Mac15,7":  "MacBook Pro 16” (M3 Pro)",
    "Mac15,8":  "MacBook Pro 14” (M3 Max)",
    "Mac15,9":  "MacBook Pro 16” (M3 Max)",
    "Mac15,10": "MacBook Pro 14” (M3 Max)",
    "Mac15,11": "MacBook Pro 16” (M3 Max)",
    "Mac15,12": "MacBook Air 13” (M3)",
    "Mac15,13": "MacBook Air 15” (M3)",

    // M4 era
    "Mac16,1":  "MacBook Pro 14” (M4)",
    "Mac16,3":  "iMac 24” (M4)",
    "Mac16,5":  "MacBook Pro 16” (M4 Max)",
    "Mac16,6":  "MacBook Pro 14” (M4 Max)",
    "Mac16,7":  "MacBook Pro 16” (M4 Pro)",
    "Mac16,8":  "MacBook Pro 14” (M4 Pro)",
    "Mac16,10": "Mac mini (M4)",
    "Mac16,11": "Mac mini (M4 Pro)",
    "Mac16,12": "MacBook Air 13” (M4)",
    "Mac16,13": "MacBook Air 15” (M4)",

    // M5 era
    "Mac17,2":  "MacBook Pro 14” (M5)",
    "Mac17,3":  "MacBook Air 13” (M5)",
    "Mac17,4":  "MacBook Air 15” (M5)",
    "Mac17,6":  "MacBook Pro 16” (M5 Max)",
    "Mac17,7":  "MacBook Pro 14” (M5 Max)",
    "Mac17,8":  "MacBook Pro 16” (M5 Pro)",
    "Mac17,9":  "MacBook Pro 14” (M5 Pro)",
  ]
}
