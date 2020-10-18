//
//  SettingsSource.swift
//  White Noise
//
//  Created by David Albers on 10/23/20.
//  Copyright © 2020 David Albers. All rights reserved.
//

import Foundation

class SettingsSource {
    var userDefaults = UserDefaults(suiteName: "group.com.dalbers.WhiteNoise")!
    private static let colorKey : String = "colorKey"
    private static let wavesKey : String = "wavesKey"
    private static let fadeKey : String = "fadeKey"
    private static let timerKey : String = "timerKey"
    private static let themeKey : String = "themeKey"
    private static let widgetThemeKey : String = "widgetThemeKey"
    private static let migratedKey : String = "migratedKey"
    private let widgetUpdater = WidgetUpdater()
    
    public func color() -> NoiseColors {
        return NoiseColors(rawValue: getSettings()[SettingsSource.colorKey] as? String ?? "") ?? .White
    }
    
    public func wavesEnabled() -> Bool {
        return getSettings()[SettingsSource.wavesKey] as? Bool ?? false
    }
    
    public func fadeEnabled() -> Bool {
        return getSettings()[SettingsSource.fadeKey] as? Bool ?? false
    }
    
    public func timerSeconds() -> Double {
        return getSettings()[SettingsSource.timerKey] as? Double ?? 0.0
    }
    
    public func theme() -> Int {
        return getSettings()[SettingsSource.themeKey] as? Int ?? 0
    }
    
    public func widgetTheme() -> Int {
        return getSettings()[SettingsSource.widgetThemeKey] as? Int ?? 0
    }
    
    public func setTheme(_ theme: Int) {
        getSettingsObj().setValue(theme, forKey: SettingsSource.themeKey)
    }

    public func setWidgetTheme(_ theme: Int) {
        let old = widgetTheme()
        getSettingsObj().setValue(theme, forKey: SettingsSource.widgetThemeKey)
        if old != theme {
            widgetUpdater.update()
        }
    }
    
    public func hasTheme() -> Bool {
        return getSettings()[SettingsSource.themeKey] as? Int != nil
    }
    
    public func hasLegacySettings() -> Bool {
        return UserDefaults.standard.dictionaryRepresentation()[SettingsSource.colorKey] as? String != nil
    }
    
    public func setColor(_ color: NoiseColors) {
        let old = self.color()
        getSettingsObj().setValue(color.rawValue, forKey: SettingsSource.colorKey)
        if old != color {
            widgetUpdater.update()
        }
    }
    
    public func setWaves(_ enabled: Bool) {
        let old = self.wavesEnabled()
        getSettingsObj().setValue(enabled, forKey: SettingsSource.wavesKey)
        if old != enabled {
            widgetUpdater.update()
        }
    }
    
    public func setFade(_ enabled: Bool) {
        let old = self.fadeEnabled()
        getSettingsObj().setValue(enabled, forKey: SettingsSource.fadeKey)
        if old != enabled {
            widgetUpdater.update()
        }
    }
    
    public func setTimer(_ seconds: Double?) {
        let old = self.timerSeconds()
        if seconds != nil {
            getSettingsObj().setValue(seconds as Any, forKey: SettingsSource.timerKey)
        }
        if old != seconds {
            widgetUpdater.update()
        }
    }
    
    public func setMigrated(_ migrated: Bool) {
        getSettingsObj().setValue(migrated, forKey: SettingsSource.migratedKey)
    }
    
    public func migrated() -> Bool {
        return getSettings()[SettingsSource.migratedKey] as? Bool ?? false
    }
    
    private func getSettings() -> [String : Any] {
        return getSettingsObj().dictionaryRepresentation()
    }
    
    private func getSettingsObj() -> UserDefaults {
        return userDefaults
    }
}
