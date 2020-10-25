//
//  SettingsSource.swift
//  White Noise
//
//  Created by David Albers on 10/23/20.
//  Copyright © 2020 David Albers. All rights reserved.
//

import Foundation

class SettingsSource {
    private static let colorKey : String = "colorKey"
    private static let wavesKey : String = "wavesKey"
    private static let fadeKey : String = "fadeKey"
    private static let timerKey : String = "timerKey"
    private static let themeKey : String = "themeKey"
    private static let widgetThemeKey : String = "widgetThemeKey"

    
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
        getSettingsObj().setValue(theme, forKey: SettingsSource.widgetThemeKey)
    }
    
    public func hasTheme() -> Bool {
        return getSettings()[SettingsSource.themeKey] as? Int != nil
    }
    
    public func hasAnySettings() -> Bool {
        return getSettings()[SettingsSource.colorKey] as? String != nil
    }
    
    public func setColor(_ color: NoiseColors) {
        getSettingsObj().setValue(color.rawValue, forKey: SettingsSource.colorKey)
    }
    
    public func setWaves(_ enabled: Bool) {
        getSettingsObj().setValue(enabled, forKey: SettingsSource.wavesKey)
    }
    
    public func setFade(_ enabled: Bool) {
        getSettingsObj().setValue(enabled, forKey: SettingsSource.fadeKey)
    }
    
    public func setTimer(_ seconds: Double?) {
        if seconds != nil {
            getSettingsObj().setValue(seconds as Any, forKey: SettingsSource.timerKey)
        }
    }
    
    private func getSettings() -> [String : Any] {
        return UserDefaults(suiteName: "group.com.dalbers.WhiteNoise")!.dictionaryRepresentation()
    }
    
    private func getSettingsObj() -> UserDefaults {
        return UserDefaults(suiteName: "group.com.dalbers.WhiteNoise")!
    }
}
