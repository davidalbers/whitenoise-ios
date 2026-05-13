import SwiftUI

struct SettingsView: View {
    @State private var viewModel: SettingsViewModel
    var dismissAction: () -> Void

    @Environment(ThemeColors.self) private var themeColors

    init(dismissAction: @escaping () -> Void, onThemeChanged: ((Themer.Theme, ColorScheme?) -> Void)? = nil) {
        self.dismissAction = dismissAction
        _viewModel = State(initialValue: SettingsViewModel(onThemeChanged: onThemeChanged))
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ThemeCard(selected: viewModel.theme, onSelect: viewModel.setTheme)

                    WidgetThemeCard(
                        widgetMirrorsApp: viewModel.widgetMirrorsApp,
                        widgetTheme: viewModel.widgetTheme,
                        onMirrorAppChanged: viewModel.setWidgetMirrorsApp,
                        onThemeChanged: viewModel.setWidgetTheme
                    )
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
                    ThemeGrid(selected: widgetTheme, onSelect: onThemeChanged)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .animation(.easeInOut(duration: 0.25), value: widgetMirrorsApp)
        }
    }

private struct ThemeCard: View {
    let selected: Themer.Theme
    let onSelect: (Themer.Theme) -> Void

    @Environment(ThemeColors.self) private var themeColors

    var body: some View {
        SettingsCard {
            Text("Theme")
                .font(.headline)
                .foregroundColor(themeColors.text)
            ThemeGrid(selected: selected, onSelect: onSelect)
        }
    }
}

private struct ThemeGrid: View {
    let selected: Themer.Theme
    let onSelect: (Themer.Theme) -> Void

    private let themes: [Themer.Theme] = [.auto, .dark, .light, .dusk, .midnight, .green]
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
