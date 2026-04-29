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
    func color() -> NoiseColors {
        NoiseColors(rawValue: getSettings()[SettingsSource.colorKey] as? String ?? "") ?? .white
    }

    func wavesEnabled() -> Bool {
        getSettings()[SettingsSource.wavesKey] as? Bool ?? false
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
        getSettings()[SettingsSource.themeKey] as? Int != nil
    }

    func hasLegacySettings() -> Bool {
        UserDefaults.standard.dictionaryRepresentation()[SettingsSource.colorKey] as? String != nil
    }

    func setColor(_ color: NoiseColors) {
        let old = self.color()
        getSettingsObj().setValue(color.rawValue, forKey: SettingsSource.colorKey)
        if old != color {
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    func setWaves(_ enabled: Bool) {
        let old = wavesEnabled()
        getSettingsObj().setValue(enabled, forKey: SettingsSource.wavesKey)
        if old != enabled {
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

    func setMigrated(_ migrated: Bool) {
        getSettingsObj().setValue(migrated, forKey: SettingsSource.migratedKey)
    }

    func migrated() -> Bool {
        getSettings()[SettingsSource.migratedKey] as? Bool ?? false
    }

    private func getSettings() -> [String: Any] {
        getSettingsObj().dictionaryRepresentation()
    }

    private func getSettingsObj() -> UserDefaults {
        userDefaults
    }
}
