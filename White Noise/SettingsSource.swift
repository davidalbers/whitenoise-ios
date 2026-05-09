import Foundation
import WidgetKit

class SettingsSource {
    var userDefaults = UserDefaults(suiteName: "group.com.dalbers.WhiteNoise")!
    private static let colorKey: String = "colorKey"
    private static let wavesKey: String = "wavesKey"
    private static let fadeKey: String = "fadeKey"
    private static let timerKey: String = "timerKey"
    private static let themeKey: String = "themeKey"
    private static let widgetThemeKey: String = "widgetThemeKey"
    private static let migratedKey: String = "migratedKey"
    private static let wavesIntensityKey: String = "wavesIntensityKey"
    private static let customPresetSecondsKey: String = "customPresetSecondsKey"
    func color() -> NoiseColors {
        NoiseColors(rawValue: getSettings()[SettingsSource.colorKey] as? String ?? "") ?? .white
    }

    func fadeEnabled() -> Bool {
        getSettings()[SettingsSource.fadeKey] as? Bool ?? false
    }

    func timerSeconds() -> Double {
        getSettings()[SettingsSource.timerKey] as? Double ?? 0.0
    }

    func theme() -> Int {
        getSettings()[SettingsSource.themeKey] as? Int ?? 0
    }

    func widgetTheme() -> Int {
        getSettings()[SettingsSource.widgetThemeKey] as? Int ?? 0
    }

    func setTheme(_ theme: Int) {
        getSettingsObj().setValue(theme, forKey: SettingsSource.themeKey)
    }

    func setWidgetTheme(_ theme: Int) {
        let old = widgetTheme()
        getSettingsObj().setValue(theme, forKey: SettingsSource.widgetThemeKey)
        if old != theme {
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    func hasTheme() -> Bool {
        getSettings()[SettingsSource.themeKey] is Int
    }

    func hasLegacySettings() -> Bool {
        UserDefaults.standard.dictionaryRepresentation()[SettingsSource.colorKey] is String
    }

    func wavesIntensity() -> WavesIntensity {
        guard let raw = getSettings()[SettingsSource.wavesIntensityKey] as? String else {
            let legacyWavesEnabled = getSettings()[SettingsSource.wavesKey] as? Bool ?? false
            if legacyWavesEnabled {
                return .medium
            }
            return .off
        }
        return WavesIntensity(rawValue: raw) ?? .medium
    }

    func setWavesIntensity(_ intensity: WavesIntensity) {
        getSettingsObj().setValue(intensity.rawValue, forKey: SettingsSource.wavesIntensityKey)
    }

    func customPresetSeconds() -> Double? {
        let val = getSettings()[SettingsSource.customPresetSecondsKey] as? Double ?? 0
        return val > 0 ? val : nil
    }

    func setCustomPresetSeconds(_ seconds: Double) {
        getSettingsObj().setValue(seconds, forKey: SettingsSource.customPresetSecondsKey)
    }

    func setColor(_ color: NoiseColors) {
        let old = self.color()
        getSettingsObj().setValue(color.rawValue, forKey: SettingsSource.colorKey)
        if old != color {
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    func setFade(_ enabled: Bool) {
        let old = fadeEnabled()
        getSettingsObj().setValue(enabled, forKey: SettingsSource.fadeKey)
        if old != enabled {
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    func setTimer(_ seconds: Double?) {
        let old = timerSeconds()
        if let seconds {
            getSettingsObj().setValue(seconds, forKey: SettingsSource.timerKey)
        } else {
            getSettingsObj().removeObject(forKey: SettingsSource.timerKey)
        }
        if old != (seconds ?? 0.0) {
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    private func getSettings() -> [String: Any] {
        getSettingsObj().dictionaryRepresentation()
    }

    private func getSettingsObj() -> UserDefaults {
        userDefaults
    }
}
