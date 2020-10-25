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
    @State private var theme = 0
    @State private var widgetTheme = 0
    var rootVc: UIViewController? = nil
    var dismissAction: (() -> Void)
    var themer = Themer()

    func getColorScheme() -> ColorScheme? {
        if theme == 1 {
            return ColorScheme.dark
        } else if theme == 2 {
            return ColorScheme.light
        } else {
            return nil
        }
    }
    
    func themeChanged(_ index: Int) {
        themer.saveTheme(Themer.Theme.init(rawValue: index))
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
                        themeChanged(theme)
                    }
                }
                Section {
                    Text("Widget theme")
                    Picker(selection: $widgetTheme, label: Text("widget theme")) {
                        Text("Auto").tag(0)
                        Text("Dark").tag(1)
                        Text("Light").tag(2)
                    }.pickerStyle(SegmentedPickerStyle())
                }
            }
            .navigationBarTitle("Settings")
            .navigationBarItems(trailing: Button(action: self.dismissAction, label: {
                Text("Done")
            }))
        }.colorScheme(getColorScheme())
        .onAppear {
            theme = themer.getTheme().rawValue
//            updateThemeForViewController(self)
        }
    }
}

@available(iOS 13.0, *)
extension View {
    // If condition is met, apply modifier, otherwise, leave the view untouched
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
