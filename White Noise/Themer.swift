import Foundation
import SwiftUI
import UIKit

class Themer {
    let settingsSource = SettingsSource()

    enum Theme: Int {
        case auto = 0
        case dark = 1
        case light = 2
    }

    func saveTheme(_ theme: Theme?) {
        settingsSource.setTheme((theme ?? Theme.auto).rawValue)
    }

    func getTheme() -> Theme {
        if settingsSource.hasTheme() {
            let themeString = settingsSource.theme()
            let savedTheme = Theme(rawValue: themeString)
            return savedTheme ?? Theme.auto
        } else if settingsSource.hasLegacySettings() {
            // The app used only a dark theme in iOS 12. Keep using dark for people
            // who installed it then since that's what they expect.
            return Theme.dark
        } else {
            return Theme.auto
        }
    }

    @available(iOS 12.0, *)
    func getUIUserInterfaceStyle() -> UIUserInterfaceStyle {
        switch getTheme() {
        case nil: UIUserInterfaceStyle.unspecified
        case .auto: UIUserInterfaceStyle.unspecified
        case .dark: UIUserInterfaceStyle.dark
        case .light: UIUserInterfaceStyle.light
        }
    }

    func getStatusBarStyle() -> UIStatusBarStyle {
        if #available(iOS 13.0, *) {
            switch getTheme() {
            case nil: return UIStatusBarStyle.default
            case .auto: return UIStatusBarStyle.default
            case .dark: return UIStatusBarStyle.lightContent
            case .light: return UIStatusBarStyle.darkContent
            }
        }
        return UIStatusBarStyle.default
    }

    @available(iOS 13.0, *)
    func getColorScheme() -> ColorScheme? {
        getColorScheme(theme: getTheme())
    }

    @available(iOS 13.0, *)
    func getWidgetColorScheme() -> ColorScheme? {
        getColorScheme(theme: Theme(rawValue: settingsSource.widgetTheme()) ?? Theme.auto)
    }

    @available(iOS 13.0, *)
    private func getColorScheme(theme: Theme) -> ColorScheme? {
        switch theme {
        case .dark: ColorScheme.dark
        case .light: ColorScheme.light
        default: nil
        }
    }
}
