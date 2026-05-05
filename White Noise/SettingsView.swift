import SwiftUI

struct SettingsView: View {
    @State private var theme: Int
    @State private var colorScheme: ColorScheme?
    @State private var widgetTheme: Int
    var onThemeChanged: ((ColorScheme?) -> Void)?
    var dismissAction: () -> Void
    var themer = Themer()
    var settingsSource = SettingsSource()

    init(dismissAction: @escaping (() -> Void), onThemeChanged: ((ColorScheme?) -> Void)? = nil) {
        self.dismissAction = dismissAction
        self.onThemeChanged = onThemeChanged
        _theme = State(initialValue: themer.getTheme().rawValue)
        _widgetTheme = State(initialValue: settingsSource.widgetTheme())
        _colorScheme = State(initialValue: themer.getColorScheme())
    }

    func themeChanged(_ index: Int) {
        themer.saveTheme(Themer.Theme(rawValue: index))
        colorScheme = themer.getColorScheme()
        onThemeChanged?(colorScheme)
    }

    var body: some View {
        NavigationView {
            Form {
                Section {
                    Text("Theme")
                    Picker(selection: $theme, label: Text("theme")) {
                        Text("Auto").tag(0)
                        Text("Dark").tag(1)
                        Text("Light").tag(2)
                    }.pickerStyle(SegmentedPickerStyle())
                        .onChange(of: theme) { _, newValue in
                            themeChanged(newValue)
                        }
                }
                Section {
                    Text("Widget theme")
                    Picker(selection: $widgetTheme, label: Text("widget theme")) {
                        Text("Auto").tag(0)
                        Text("Dark").tag(1)
                        Text("Light").tag(2)
                    }.pickerStyle(SegmentedPickerStyle())
                        .onChange(of: widgetTheme) { _, newValue in
                            settingsSource.setWidgetTheme(newValue)
                        }
                }
            }
            .navigationBarTitle("Settings")
            .navigationBarItems(trailing: Button(action: dismissAction, label: {
                Text("Done")
            }))
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .colorScheme(colorScheme)
    }
}

public extension View {
    func colorScheme(_ colorScheme: ColorScheme?) -> some View {
        Group {
            if colorScheme != nil {
                self.environment(\.colorScheme, colorScheme!)
            } else {
                self
            }
        }
    }
}
