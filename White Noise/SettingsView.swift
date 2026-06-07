import SwiftUI

struct SettingsView: View {
    @State private var viewModel: SettingsViewModel
    var dismissAction: () -> Void

    @Environment(ThemeColors.self) private var themeColors

    init(
        dismissAction: @escaping () -> Void,
        onThemeChanged: ((Themer.Theme, ColorScheme?) -> Void)? = nil
    ) {
        self.dismissAction = dismissAction
        _viewModel = State(initialValue: SettingsViewModel(onThemeChanged: onThemeChanged))
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ThemeCard(themes: viewModel.availableThemes, selected: viewModel.theme, onSelect: viewModel.setTheme)

                    WidgetThemeCard(
                        themes: viewModel.availableThemes,
                        widgetMirrorsApp: viewModel.widgetMirrorsApp,
                        widgetTheme: viewModel.widgetTheme,
                        onMirrorAppChanged: viewModel.setWidgetMirrorsApp,
                        onThemeChanged: viewModel.setWidgetTheme
                    )

                    LinksCard()
                }
                .padding(16)
            }
            .background(themeColors.background.ignoresSafeArea())
            .toolbarBackground(themeColors.background, for: .navigationBar)
            .toolbarColorScheme(viewModel.colorScheme, for: .navigationBar)
            .navigationTitle("Settings")
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

struct SettingsCard<Content: View>: View {
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

struct WidgetThemeCard: View {
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

struct ThemeCard: View {
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

struct ThemeGrid: View {
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

struct ThemeCell: View {
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

struct AutoThemeIcon: View {
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

struct ThemeIcon: View {
    let theme: Themer.Theme

    @Environment(ThemeColors.self) private var themeColors

    private var fillColor: Color {
        switch theme {
        case .auto: .clear
        case .dark: Color("darkBackground")
        case .light: Color("lightBackground")
        case .dusk: Color(UIColor(named: "duskBackground")!.lightened(by: 0.15))
        case .midnight: Color("midnightBackground")
        case .green: Color(UIColor(named: "greenBackground")!.lightened(by: 0.15))
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

// MARK: - Links Card

struct LinksCard: View {
    @Environment(ThemeColors.self) private var themeColors

    var body: some View {
        SettingsCard {
            Link(destination: URL(string: "https://davidalbers.github.io/whitenoise/index.html")!) {
                HStack {
                    Image(systemName: "globe")
                    Text("Visit website")
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                }
                .font(.subheadline)
                .foregroundColor(themeColors.text)
            }

            Divider()
                .background(themeColors.text.opacity(0.2))

            Link(destination: URL(string: "mailto:davidgalbers@gmail.com")!) {
                HStack {
                    Image(systemName: "envelope")
                    Text("Get help: davidgalbers@gmail.com")
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                }
                .font(.subheadline)
                .foregroundColor(themeColors.text)
            }
        }
    }
}

// MARK: - Extensions

extension Themer.Theme {
    var displayName: String {
        switch self {
        case .auto: "Auto"
        case .dark: "Dark"
        case .light: "Light"
        case .dusk: "Rust"
        case .midnight: "Midnight"
        case .green: "Matcha"
        }
    }
}
