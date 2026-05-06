import Foundation

public enum NoiseColors: String {
    case white
    case pink
    case brown
}

enum WavesIntensity: String, CaseIterable {
    case off = "Off"
    case low = "Low"
    case medium = "Med"
    case high = "High"

    var minVolume: Float? {
        switch self {
        case .off: nil
        case .low: 0.5
        case .medium: 0.3
        case .high: 0.1
        }
    }
}

enum TimerPreset: String, Equatable {
    case min15 = "15m"
    case min30 = "30m"
    case hour1 = "1h"
    case hour4 = "4h"
    case custom = "Custom"

    var seconds: Double {
        switch self {
        case .min15: 15 * 60
        case .min30: 30 * 60
        case .hour1: 60 * 60
        case .hour4: 4 * 60 * 60
        case .custom: 0
        }
    }

    static func from(seconds: Double) -> TimerPreset? {
        guard seconds > 0 else { return nil }
        switch seconds {
        case 15 * 60: return .min15
        case 30 * 60: return .min30
        case 60 * 60: return .hour1
        case 4 * 60 * 60: return .hour4
        default: return .custom
        }
    }
}
