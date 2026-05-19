import SwiftUI

struct SettingsView: View {
    @State private var viewModel: SettingsViewModel
    @State private var bannerExpanded = false
    var dismissAction: () -> Void

    @Environment(ThemeColors.self) private var themeColors

    init(
        dismissAction: @escaping () -> Void,
        entitlements: EntitlementsManager,
        purchases: PurchaseManager,
        onThemeChanged: ((Themer.Theme, ColorScheme?) -> Void)? = nil
    ) {
        self.dismissAction = dismissAction
        _viewModel = State(initialValue: SettingsViewModel(
            entitlements: entitlements,
            purchases: purchases,
            onThemeChanged: onThemeChanged
        ))
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if !viewModel.hasPremium {
                        PremiumBannerView(
                            isInTrial: viewModel.isInTrial,
                            trialExpired: viewModel.trialExpired,
                            daysRemaining: viewModel.daysRemainingInTrial,
                            isExpanded: $bannerExpanded,
                            isPurchasing: viewModel.isPurchasing,
                            onStartTrial: viewModel.startTrial,
                            onBuy: viewModel.buy,
                            onRestore: viewModel.restore
                        )
                    }

                    ThemeCard(themes: viewModel.availableThemes, selected: viewModel.theme, onSelect: viewModel.setTheme)

                    WidgetThemeCard(
                        themes: viewModel.availableThemes,
                        widgetMirrorsApp: viewModel.widgetMirrorsApp,
                        widgetTheme: viewModel.widgetTheme,
                        onMirrorAppChanged: viewModel.setWidgetMirrorsApp,
                        onThemeChanged: viewModel.setWidgetTheme
                    )

                    if viewModel.hasPremiumAccess {
                        NightlightCard(
                            nightlightStyle: viewModel.nightlightStyle,
                            nightlightLength: viewModel.nightlightLength,
                            onStyleChanged: viewModel.setNightlightStyle,
                            onLengthChanged: viewModel.setNightlightLength
                        )
                    }

                    if viewModel.hasPremium {
                        PremiumThankYouView()
                    }
                }
                .padding(16)
            }
            .background(themeColors.background.ignoresSafeArea())
            .toolbarBackground(themeColors.background, for: .navigationBar)
            .toolbarColorScheme(viewModel.colorScheme, for: .navigationBar)
            .navigationTitle("Settings")
            .alert("Purchase Failed", isPresented: Binding(
                get: { viewModel.purchaseError != nil },
                set: { if !$0 { viewModel.purchaseError = nil } }
            )) {
                Button("OK") { viewModel.purchaseError = nil }
            } message: {
                Text(viewModel.purchaseError ?? "")
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done", action: dismissAction)
                        .foregroundColor(themeColors.text)
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .preferredColorScheme(viewModel.colorScheme)
    }
}

private struct SettingsCard<Content: View>: View {
    @ViewBuilder let content: Content

    @Environment(ThemeColors.self) private var themeColors

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            content
        }
        .padding(16)
        .background(themeColors.accent)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

private struct WidgetThemeCard: View {
    let themes: [Themer.Theme]
    let widgetMirrorsApp: Bool
    let widgetTheme: Themer.Theme
    let onMirrorAppChanged: (Bool) -> Void
    let onThemeChanged: (Themer.Theme) -> Void

    @Environment(ThemeColors.self) private var themeColors

    var body: some View {
        SettingsCard {
            HStack(alignment: .top) {
                Text("Widget theme")
                    .font(.headline)
                    .foregroundColor(themeColors.text)
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Mirror app")
                        .font(.caption)
                        .foregroundColor(themeColors.text)
                    Toggle("", isOn: .init(get: { widgetMirrorsApp }, set: onMirrorAppChanged))
                        .labelsHidden()
                }
            }

            if !widgetMirrorsApp {
                ThemeGrid(themes: themes, selected: widgetTheme, onSelect: onThemeChanged)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: widgetMirrorsApp)
    }
}

private struct NightlightCard: View {
    let nightlightStyle: NightlightStyle
    let nightlightLength: NightlightLength
    let onStyleChanged: (NightlightStyle) -> Void
    let onLengthChanged: (NightlightLength) -> Void

    @Environment(ThemeColors.self) private var themeColors

    var body: some View {
        SettingsCard {
            Text("Nightlight")
                .font(.headline)
                .foregroundColor(themeColors.text)
            Text("Keep screen on with a soft glow for a few minutes while you fall asleep.")
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 4)

            HStack {
                Text("Style")
                    .font(.body)
                    .foregroundColor(themeColors.text)
                Spacer()
                Picker("Style", selection: .init(get: { nightlightStyle }, set: onStyleChanged)) {
                    Text("Fade out").tag(NightlightStyle.fadeOut)
                    Text("Consistent").tag(NightlightStyle.consistent)
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
            }

            HStack {
                Text("Length")
                    .font(.body)
                    .foregroundColor(themeColors.text)
                Spacer()
                Picker("Length", selection: .init(get: { nightlightLength }, set: onLengthChanged)) {
                    Text("5m").tag(NightlightLength.five)
                    Text("10m").tag(NightlightLength.ten)
                    Text("15m").tag(NightlightLength.fifteen)
                }
                .pickerStyle(.segmented)
                .frame(width: 180)
            }
        }
    }
}

// MARK: - Premium Card

private struct PremiumCard<Trailing: View, Footer: View>: View {
    let subtitle: String
    @ViewBuilder let trailing: Trailing
    @ViewBuilder let footer: Footer

    @Environment(ThemeColors.self) private var themeColors

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: "star.circle.fill")
                    .font(.title2)
                    .foregroundColor(themeColors.text)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Premium")
                        .font(.headline)
                        .foregroundColor(themeColors.text)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(themeColors.text)
                }
                Spacer()
                trailing
            }
            .padding(16)
            footer
        }
        .background(themeColors.accent)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .clipped()
    }
}

extension PremiumCard where Trailing == EmptyView, Footer == EmptyView {
    init(subtitle: String) {
        self.init(subtitle: subtitle, trailing: { EmptyView() }, footer: { EmptyView() })
    }
}

// MARK: - Premium Banner

private struct PremiumBannerView: View {
    let isInTrial: Bool
    let trialExpired: Bool
    let daysRemaining: Int?
    @Binding var isExpanded: Bool
    let isPurchasing: Bool
    let onStartTrial: () -> Void
    let onBuy: () -> Void
    let onRestore: () -> Void

    @Environment(ThemeColors.self) private var themeColors

    private var subtitle: String {
        if trialExpired { return "Trial ended" }
        if let days = daysRemaining { return "\(days) days left in trial" }
        return "More sounds, nightlight, and themes"
    }

    private var actionLabel: String {
        (isInTrial || trialExpired) ? "Buy for $3" : "Try free"
    }

    var body: some View {
        PremiumCard(subtitle: subtitle, trailing: {
            if isInTrial, isPurchasing {
                ProgressView()
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
            } else {
                Button(action: (isInTrial || trialExpired) ? onBuy : onStartTrial) {
                    Text(actionLabel)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(themeColors.text)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(themeColors.background)
                        .clipShape(Capsule())
                }
                .disabled(isPurchasing)
            }
        }, footer: {
            if !isExpanded {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.25)) { isExpanded.toggle() }
                }) {
                    HStack(spacing: 4) {
                        Text("See full features list")
                            .font(.subheadline)
                            .foregroundColor(themeColors.text)
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                            .foregroundColor(themeColors.text.opacity(0.8))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 12)
                }
            }
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Pay once to unlock all these features:")
                        .font(.subheadline)
                        .foregroundColor(themeColors.text)
                    BulletRow("3 new sounds: rain, fan, fireplace")
                    BulletRow("Turn your phone into a nightlight while sounds play")
                    BulletRow("New themes for app and widget")
                    Button(action: onRestore) {
                        Text("Restore purchase")
                            .font(.subheadline)
                    }
                    .padding(.vertical, 12)
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.25)) { isExpanded.toggle() }
                    }) {
                        HStack(spacing: 4) {
                            Text("Show less")
                                .font(.subheadline)
                                .foregroundColor(themeColors.text)
                            Image(systemName: "chevron.up")
                                .font(.caption2)
                                .foregroundColor(themeColors.text)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        })
    }
}

// MARK: - Premium Thank You

private struct PremiumThankYouView: View {
    var body: some View {
        PremiumCard(subtitle: "Thank you for supporting this app")
    }
}

private struct BulletRow: View {
    let text: String
    @Environment(ThemeColors.self) private var themeColors

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Circle()
                .frame(width: 5, height: 5)
                .foregroundColor(themeColors.text)
                .padding(.top, 6)
            Text(text)
                .font(.subheadline)
                .foregroundColor(themeColors.text)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct ThemeCard: View {
    let themes: [Themer.Theme]
    let selected: Themer.Theme
    let onSelect: (Themer.Theme) -> Void

    @Environment(ThemeColors.self) private var themeColors

    var body: some View {
        SettingsCard {
            Text("Theme")
                .font(.headline)
                .foregroundColor(themeColors.text)
            ThemeGrid(themes: themes, selected: selected, onSelect: onSelect)
        }
    }
}

private struct ThemeGrid: View {
    let themes: [Themer.Theme]
    let selected: Themer.Theme
    let onSelect: (Themer.Theme) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)

    @Environment(ThemeColors.self) private var themeColors

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(themes, id: \.rawValue) { theme in
                ThemeCell(theme: theme, isSelected: selected == theme) { onSelect(theme) }
            }
        }
        .sensoryFeedback(.selection, trigger: selected)
    }
}

private struct ThemeCell: View {
    let theme: Themer.Theme
    let isSelected: Bool
    let action: () -> Void

    @Environment(ThemeColors.self) private var themeColors

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ThemeIcon(theme: theme)
                    .frame(width: 60, height: 60)
                Text(theme.displayName)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? themeColors.text : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(uiColor: .systemBackground).opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(themeColors.text, lineWidth: isSelected ? 2 : 0)
                    )
            )
        }
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

private struct AutoThemeIcon: View {
    var body: some View {
        Circle().fill(Color(white: 0.92))
            .overlay(
                GeometryReader { geo in
                    Path { path in
                        let width = geo.size.width, height = geo.size.height
                        path.move(to: CGPoint(x: width, y: 0))
                        path.addLine(to: CGPoint(x: width, y: height))
                        path.addLine(to: CGPoint(x: 0, y: height))
                        path.closeSubpath()
                    }
                    .fill(Color(white: 0.14))
                }
                .clipShape(Circle())
            )
    }
}

private struct ThemeIcon: View {
    let theme: Themer.Theme

    @Environment(ThemeColors.self) private var themeColors

    private var fillColor: Color {
        switch theme {
        case .auto: .clear
        case .dark: Color(white: 0x1F / 255)
        case .light: Color(white: 0xF9 / 255)
        case .dusk: Color("duskBackground")
        case .midnight: Color("midnightBackground")
        case .green: Color("greenBackground")
        }
    }

    var body: some View {
        Group {
            switch theme {
            case .auto: AutoThemeIcon()
            default: Circle().fill(fillColor)
            }
        }
        .overlay(Circle().stroke(themeColors.text, lineWidth: 1.5))
    }
}

// MARK: - Extensions

private extension Themer.Theme {
    var displayName: String {
        switch self {
        case .auto: "Auto"
        case .dark: "Dark"
        case .light: "Light"
        case .dusk: "Dusk"
        case .midnight: "Midnight"
        case .green: "Green"
        }
    }
}
