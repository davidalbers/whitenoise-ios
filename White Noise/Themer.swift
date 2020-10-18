import Foundation
import UIKit

class Themer {
    public enum Theme: Int {
        case auto = 0
        case dark = 1
        case light = 2
    }
    
    private let themeKey : String = "themeKey"

    func saveTheme(_ theme: Theme?) {
        UserDefaults.standard.setValue((theme ?? Theme.auto).rawValue, forKey: themeKey)
    }
    
    func getTheme() -> Theme {
        let usersSetTheme = UserDefaults.standard.string(forKey: themeKey) != nil
        // The app used only a dark theme in iOS 12. Keep using dark for people
        // who installed it then since that's what they expect.
        let grandfatheredInToDarkTheme = UserDefaults.standard.string(forKey: MainPresenter.colorKey)

        if usersSetTheme {
            let themeString = UserDefaults.standard.integer(forKey: themeKey)
            let savedTheme = Theme.init(rawValue: (themeString))
            return savedTheme ?? Theme.auto
        } else if grandfatheredInToDarkTheme != nil {
            return Theme.dark
        } else {
            return Theme.auto
        }
    }
    
    @available(iOS 12.0, *)
    func getUIUserInterfaceStyle() -> UIUserInterfaceStyle {
        switch getTheme() {
        case nil: return UIUserInterfaceStyle.unspecified
        case .auto: return UIUserInterfaceStyle.unspecified
        case .dark: return UIUserInterfaceStyle.dark
        case .light: return UIUserInterfaceStyle.light
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
}
