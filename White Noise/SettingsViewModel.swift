import SwiftUI

@MainActor
@Observable
final class SettingsViewModel {
    var theme: Themer.Theme
    var colorScheme: ColorScheme?
    var widgetTheme: Themer.Theme
    var widgetMirrorsApp: Bool
    var nightlightStyle: NightlightStyle
    var nightlightLength: NightlightLength
    var hasPremium: Bool {
        entitlements.hasPremium
    }

    var hasPremiumAccess: Bool {
        entitlements.hasPremiumAccess
    }

    var isInTrial: Bool {
        entitlements.isInTrial
    }

    var trialExpired: Bool {
        entitlements.trialExpired
    }

    var trialStartDate: Date? {
        entitlements.trialStartDate
    }

    var daysRemainingInTrial: Int? {
        entitlements.daysRemainingInTrial
    }

    var availableThemes: [Themer.Theme] {
        [.auto, .dark, .light, .dusk, .midnight, .green].filter { !$0.isPremium || hasPremiumAccess }
    }

    var isPurchasing: Bool {
        purchases.isPurchasing
    }

    var purchaseError: String? {
        get { purchases.purchaseError }
        set { purchases.purchaseError = newValue }
    }

    var onThemeChanged: ((Themer.Theme, ColorScheme?) -> Void)?

    private let themer: Themer
    private let settings: SettingsSource
    private let entitlements: EntitlementsManager
    private let purchases: PurchaseManager

    init(
        entitlements: EntitlementsManager,
        purchases: PurchaseManager,
        themer: Themer = Themer(),
        settings: SettingsSource = SettingsSource(),
        onThemeChanged: ((Themer.Theme, ColorScheme?) -> Void)? = nil
    ) {
        self.entitlements = entitlements
        self.purchases = purchases
        self.themer = themer
        self.settings = settings
        self.onThemeChanged = onThemeChanged
        theme = themer.getTheme()
        colorScheme = themer.getColorScheme()
        widgetTheme = Themer.Theme(rawValue: settings.widgetTheme()) ?? .auto
        widgetMirrorsApp = settings.widgetMirrorsApp()
        nightlightStyle = settings.nightlightStyle()
        nightlightLength = settings.nightlightLength()
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
        entitlements.startTrial()
    }

    func buy() {
        Task { await purchases.purchase() }
    }

    func restore() {
        Task { await purchases.restore() }
    }
}
