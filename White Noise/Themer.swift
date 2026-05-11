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

    func getWidgetColorScheme() -> ColorScheme? {
        getColorScheme(theme: Theme(rawValue: settingsSource.widgetTheme()) ?? Theme.auto)
    }

    private func getColorScheme(theme: Theme) -> ColorScheme? {
        switch theme {
        case .dark, .dusk, .midnight, .green: ColorScheme.dark
        case .light: ColorScheme.light
        default: nil
        }
    }
}
