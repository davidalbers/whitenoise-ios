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
        case .off: 1.0
        case .low: 0.5
        case .medium: 0.3
        case .high: 0.1
        }
    }
}
