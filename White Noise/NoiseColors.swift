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

struct TimerPreset: Equatable, Hashable {
    let hours: Int
    let minutes: Int

    var seconds: Double { Double(hours * 3600 + minutes * 60) }

    var label: String {
        if hours > 0, minutes > 0 { return "\(hours)h \(minutes)m" }
        if hours > 0 { return "\(hours)h" }
        return "\(minutes)m"
    }

    var isCustom: Bool { !Self.standard.contains(self) }

    static let standard: [TimerPreset] = [
        TimerPreset(hours: 0, minutes: 15),
        TimerPreset(hours: 0, minutes: 30),
        TimerPreset(hours: 1, minutes: 0),
        TimerPreset(hours: 4, minutes: 0),
    ]

    static func from(seconds: Double) -> TimerPreset? {
        guard seconds > 0 else { return nil }
        let total = Int(seconds)
        return TimerPreset(hours: total / 3600, minutes: (total % 3600) / 60)
    }
}
