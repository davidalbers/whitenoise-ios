import Foundation

class SettingsMigrater {
    private let legacySettingsSource = SettingsSource()
    private let settingsSource = SettingsSource()
    public func migrate() {
        if (settingsSource.hasLegacySettings() && !settingsSource.migrated()) {
            legacySettingsSource.userDefaults = UserDefaults.standard
            settingsSource.setColor(legacySettingsSource.color())
            settingsSource.setWaves(legacySettingsSource.wavesEnabled())
            settingsSource.setFade(legacySettingsSource.fadeEnabled())
            settingsSource.setTimer(legacySettingsSource.timerSeconds())
        }
        settingsSource.setMigrated(true)
    }
}
