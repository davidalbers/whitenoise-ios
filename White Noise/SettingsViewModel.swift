import SwiftUI

@MainActor
@Observable
final class SettingsViewModel {
    var theme: Themer.Theme
    var colorScheme: ColorScheme?
    var widgetTheme: Themer.Theme
    var widgetMirrorsApp: Bool

    var availableThemes: [Themer.Theme] {
        [.auto, .dark, .light]
    }

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
        theme = themer.getTheme()
        colorScheme = themer.getColorScheme()
        widgetTheme = Themer.Theme(rawValue: settings.widgetTheme()) ?? .auto
        widgetMirrorsApp = settings.widgetMirrorsApp()
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
}
