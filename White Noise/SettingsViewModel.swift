import SwiftUI

@Observable
final class SettingsViewModel {
    var theme: Themer.Theme
    var colorScheme: ColorScheme?
    var widgetTheme: Themer.Theme
    var widgetMirrorsApp: Bool
    var nightlightStyle: NightlightStyle
    var nightlightLength: NightlightLength
    var premiumState: PremiumState
    var trialStartDate: Date?

    var onThemeChanged: ((Themer.Theme, ColorScheme?) -> Void)?

    private let themer: Themer
    private let settings: SettingsSource

    init(
        themer: Themer = Themer(),
        settings: SettingsSource = SettingsSource(),
        onThemeChanged: ((Themer.Theme, ColorScheme?) -> Void)? = nil
    ) {
        self.themer = themer
        self.settings = settings
        self.onThemeChanged = onThemeChanged
        self.theme = themer.getTheme()
        self.colorScheme = themer.getColorScheme()
        self.widgetTheme = Themer.Theme(rawValue: settings.widgetTheme()) ?? .auto
        self.widgetMirrorsApp = settings.widgetMirrorsApp()
        self.nightlightStyle = settings.nightlightStyle()
        self.nightlightLength = settings.nightlightLength()
        self.premiumState = settings.premiumState()
        self.trialStartDate = settings.trialStartDate()
    }

    var daysRemainingInTrial: Int? {
        guard premiumState == .trial, let start = trialStartDate else { return nil }
        let elapsed = Date().timeIntervalSince(start)
        return max(0, 30 - Int(elapsed / 86400))
    }

    func setTheme(_ newTheme: Themer.Theme) {
        theme = newTheme
        themer.saveTheme(newTheme)
        colorScheme = themer.getColorScheme()
        onThemeChanged?(newTheme, colorScheme)
    }

    func setWidgetTheme(_ newTheme: Themer.Theme) {
        widgetTheme = newTheme
        settings.setWidgetTheme(newTheme.rawValue)
    }

    func setWidgetMirrorsApp(_ mirrors: Bool) {
        widgetMirrorsApp = mirrors
        settings.setWidgetMirrorsApp(mirrors)
    }

    func setNightlightStyle(_ style: NightlightStyle) {
        nightlightStyle = style
        settings.setNightlightStyle(style)
    }

    func setNightlightLength(_ length: NightlightLength) {
        nightlightLength = length
        settings.setNightlightLength(length)
    }

    func label(for length: NightlightLength) -> String {
        "\(length.seconds / 60)m"
    }

    func startTrial() {
        guard premiumState == .none else { return }
        let now = Date()
        settings.setPremiumState(.trial)
        settings.setTrialStartDate(now)
        premiumState = .trial
        trialStartDate = now
    }
}
