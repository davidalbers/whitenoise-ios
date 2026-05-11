import SwiftUI

@Observable
final class ThemeColors {
    var accent: Color = .init("accent")
    var background: Color = .init("background")
    var text: Color = .init("text")
    var noiseColorOverride: Color?

    func apply(_ theme: Themer.Theme) {
        switch theme {
        case .auto, .light, .dark:
            accent = Color("accent")
            background = Color("background")
            text = Color("text")
            noiseColorOverride = nil
        case .dusk:
            accent = Color("duskAccent")
            background = Color("duskBackground")
            text = Color("duskText")
            noiseColorOverride = Color("text")
        case .midnight:
            accent = Color("midnightAccent")
            background = Color("midnightBackground")
            text = Color("midnightText")
            noiseColorOverride = Color("midnightBackground")
        case .green:
            accent = Color("greenAccent")
            background = Color("greenBackground")
            text = Color("text")
            noiseColorOverride = Color("text")
        }
    }
}
