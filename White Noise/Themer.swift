import Foundation
import SwiftUI
import UIKit

class Themer {
    let settingsSource = SettingsSource()

    enum Theme: Int {
        case auto = 0
        case dark = 1
        case light = 2
        case dusk = 3
        case midnight = 4
        case green = 5
    }

    func saveTheme(_ theme: Theme?) {
        settingsSource.setTheme((theme ?? Theme.auto).rawValue)
    }

    func getTheme() -> Theme {
        if settingsSource.hasTheme() {
            let themeString = settingsSource.theme()
            let savedTheme = Theme(rawValue: themeString)
            return savedTheme ?? Theme.auto
        } else {
            return Theme.auto
        }
    }

    func getUIUserInterfaceStyle() -> UIUserInterfaceStyle {
        switch getTheme() {
        case .auto: UIUserInterfaceStyle.unspecified
        case .dark, .dusk, .midnight, .green: UIUserInterfaceStyle.dark
        case .light: UIUserInterfaceStyle.light
        }
    }

    func getStatusBarStyle() -> UIStatusBarStyle {
        switch getTheme() {
        case .auto: .default
        case .dark, .dusk, .midnight, .green: .lightContent
        case .light: .darkContent
        }
    }

    func getColorScheme() -> ColorScheme? {
        getColorScheme(theme: getTheme())
    }

    func getEffectiveWidgetTheme() -> Theme {
        if settingsSource.widgetMirrorsApp() {
            return getTheme()
        }
        return Theme(rawValue: settingsSource.widgetTheme()) ?? .auto
    }

    func getWidgetColorScheme() -> ColorScheme? {
        getColorScheme(theme: getEffectiveWidgetTheme())
    }

    func widgetThemeAccent() -> Color {
        switch getEffectiveWidgetTheme() {
        case .dusk: Color("duskText")
        case .midnight: Color("midnightText")
        default: Color("text")
        }
    }

    func widgetThemeText() -> Color {
        switch getEffectiveWidgetTheme() {
        case .dusk: Color("duskText")
        case .midnight: Color("midnightText")
        default: Color.primary
        }
    }

    func widgetThemeBackground() -> Color? {
        switch getEffectiveWidgetTheme() {
        case .dusk: Color("duskBackground")
        case .midnight: Color("midnightBackground")
        case .green: Color("greenBackground")
        case .dark: Color("darkBackground")
        case .light: Color("lightBackground")
        default: nil
        }
    }

    private func getColorScheme(theme: Theme) -> ColorScheme? {
        switch theme {
        case .dark, .dusk, .midnight, .green: ColorScheme.dark
        case .light: ColorScheme.light
        default: nil
        }
    }
}
