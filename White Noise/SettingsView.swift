//
//  SettingsView.swift
//  White Noise
//
//  Created by David Albers on 10/25/20.
//  Copyright © 2020 David Albers. All rights reserved.
//

import SwiftUI

@available(iOS 14.0, *)
struct SettingsView: View {
    @State private var theme: Int
    @State private var colorScheme: ColorScheme?
    @State private var widgetTheme: Int
    var rootVc: UIViewController? = nil
    var dismissAction: (() -> Void)
    var themer = Themer()
    var settingsSource = SettingsSource()
    
    init(dismissAction: @escaping (() -> Void)) {
        self.dismissAction = dismissAction
        _theme = State(initialValue: themer.getTheme().rawValue)
        _widgetTheme = State(initialValue: settingsSource.widgetTheme())
        _colorScheme = State(initialValue: themer.getColorScheme())
    }

    func themeChanged(_ index: Int) {
        themer.saveTheme(Themer.Theme.init(rawValue: index))
        colorScheme = themer.getColorScheme()
        if let vc = rootVc { updateThemeForViewController(vc) }
    }
    
    private func updateThemeForViewController(_ viewController: UIViewController) {
        viewController.overrideUserInterfaceStyle = themer.getUIUserInterfaceStyle()
        viewController.setNeedsStatusBarAppearanceUpdate()
        viewController.view.setNeedsDisplay()
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
                    .onChange(of: theme) { value in
                        themeChanged(value)
                    }
                }
                Section {
                    Text("Widget theme")
                    Picker(selection: $widgetTheme, label: Text("widget theme")) {
                        Text("Auto").tag(0)
                        Text("Dark").tag(1)
                        Text("Light").tag(2)
                    }.pickerStyle(SegmentedPickerStyle())
                    .onChange(of: widgetTheme) { value in
                        settingsSource.setWidgetTheme(value)
                    }
                }
            }
            .navigationBarTitle("Settings")
            .navigationBarItems(trailing: Button(action: self.dismissAction, label: {
                Text("Done")
            }))
        }.colorScheme(colorScheme)
    }
}

@available(iOS 13.0, *)
extension View {
    public func colorScheme(_ colorScheme: ColorScheme?) -> some View {
        Group {
            if colorScheme != nil {
                self.environment(\.colorScheme, colorScheme!)
            } else {
                self
            }
        }
    }
}
