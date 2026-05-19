import SwiftUI
import UIKit

struct MainView: View {
    @Bindable var viewModel: MainViewModel
    @State private var settingsPresented = false
    @State private var customTimerPresented = false
    @State private var themeColors = ThemeColors()
    @Environment(\.colorScheme) private var colorScheme
    @Environment(EntitlementsManager.self) private var entitlements
    @Environment(PurchaseManager.self) private var purchases

    private var nightlightBackgroundActive: Bool {
        viewModel.nightlightEnabled && colorScheme == .dark
    }

    private var nightlightBrightness: Double? {
        nightlightBackgroundActive ? viewModel.nightlightBrightness : nil
    }

    var body: some View {
        ZStack {
            Background(
                nightlightBrightness: nightlightBrightness,
                nightlightBackgroundActive: nightlightBackgroundActive
            )

            GradientView(accentColor: viewModel.currentColor.toColor())

            VStack {
                TopRowView { settingsPresented = true }
                    .padding(.horizontal, 16)

                NoiseSelectorView(
                    currentColor: viewModel.currentColor
                ) {
                    viewModel.changeColor($0)
                }
                .nightlightBackground(nightlightBrightness, baseColor: .clear)
                .cornerRadius(12)
                .padding(.top, 20)

                WavesCardView(
                    intensity: Binding(
                        get: { viewModel.wavesIntensity },
                        set: { viewModel.setWavesIntensity($0) }
                    )
                )
                .padding(16)
                .nightlightBackground(nightlightBrightness, baseColor: themeColors.accent)
                .cornerRadius(12)
                .padding(.top, 8)
                .padding(.horizontal, 16)

                HStack(spacing: 8) {
                    FadeCardView(
                        fadeEnabled: Binding(
                            get: { viewModel.fadeEnabled },
                            set: { viewModel.setFade($0) }
                        ),
                        accentColor: viewModel.currentColor.toColor()
                    )
                    .padding(16)
                    .nightlightBackground(nightlightBrightness, baseColor: themeColors.accent)
                    .cornerRadius(12)
                    .frame(maxWidth: .infinity)

                    if entitlements.hasPremiumAccess {
                        NightlightCardView(
                            nightlightEnabled: Binding(
                                get: { viewModel.nightlightEnabled },
                                set: { viewModel.setNightlight($0) }
                            ),
                            accentColor: viewModel.currentColor.toColor()
                        )
                        .padding(16)
                        .nightlightBackground(nightlightBrightness, baseColor: themeColors.accent)
                        .cornerRadius(12)
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                TimerSectionView(
                    selectedPreset: viewModel.selectedTimerPreset,
                    customPresetSeconds: viewModel.customPresetSeconds,
                    onSelectPreset: { viewModel.setTimerPreset($0) },
                    onCustomTapped: { customTimerPresented = true }
                )
                .padding(16)
                .nightlightBackground(nightlightBrightness, baseColor: themeColors.accent)
                .cornerRadius(12)
                .padding(.horizontal, 16)
                .padding(.top, 8)

                Spacer()

                PlayAndTimeView(
                    isPlaying: viewModel.isPlaying,
                    timerText: viewModel.timerText
                ) {
                    viewModel.playPause()
                }.padding(.bottom, 32)
            }
        }
        .environment(themeColors)
        .preferredColorScheme(viewModel.colorScheme)
        .onAppear { themeColors.apply(viewModel.theme) }
        .sheet(isPresented: $settingsPresented) {
            SettingsView(
                dismissAction: { settingsPresented = false },
                entitlements: entitlements,
                purchases: purchases,
                onThemeChanged: { theme, colorScheme in
                    viewModel.theme = theme
                    viewModel.colorScheme = colorScheme
                    themeColors.apply(theme)
                }
            )
            .environment(themeColors)
        }
        .sheet(isPresented: $customTimerPresented) {
            CustomTimerSheet(
                duration: $viewModel.timerPickerSeconds,
                onSet: {
                    viewModel.confirmCustomTimer()
                    customTimerPresented = false
                },
                onCancel: { customTimerPresented = false }
            )
            .environment(themeColors)
        }
    }
}

struct GradientView: View {
    var accentColor: Color

    @Environment(ThemeColors.self) private var themeColors

    var body: some View {
        let actualColor = themeColors.noiseColorOverride ?? accentColor
        VStack {
            Spacer()
            RadialGradient(
                colors: [actualColor.opacity(0.75), .clear],
                center: UnitPoint(x: 0.5, y: 1.25),
                startRadius: 0,
                endRadius: 340
            )
            .frame(height: 340)
            .allowsHitTesting(false)
            .animation(.easeInOut(duration: 0.6), value: accentColor)
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

struct TopRowView: View {
    var settingsPresented: () -> Void

    @Environment(ThemeColors.self) private var themeColors

    var body: some View {
        HStack {
            Spacer()
            Button(
                action: settingsPresented,
                label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(themeColors.text)
                        .frame(width: 34, height: 34)
                        .overlay(Circle().stroke(themeColors.text.opacity(0.18), lineWidth: 1))
                }
            )
        }
    }
}

struct NoiseSelectorView: View {
    var currentColor: NoiseColors
    var colorSelected: (NoiseColors) -> Void

    var body: some View {
        HStack(spacing: 24) {
            ForEach([NoiseColors.white, .pink, .brown], id: \.self) { color in
                NoiseOrbView(color: color, isSelected: currentColor == color)
                    .onTapGesture { colorSelected(color) }
            }
        }
        .sensoryFeedback(.selection, trigger: currentColor)
    }
}

struct NoiseOrbView: View {
    let color: NoiseColors
    let isSelected: Bool

    private var orbGradient: RadialGradient {
        let colors = switch color {
        case .white:
            [
                Color(UIColor(named: "lightGrey")!.lightened(by: 0.32)),
                Color(UIColor(named: "lightGrey")!.lightened(by: 0.25)),
            ]
        case .pink:
            [Color(UIColor(named: "pink")!.lightened(by: 0.25)), Color("pink")]
        case .brown:
            [Color(UIColor(named: "brown")!.lightened(by: 0.18)), Color("brown")]
        }

        return RadialGradient(
            colors: colors,
            center: UnitPoint(x: 0.38, y: 0.32),
            startRadius: 8,
            endRadius: 46
        )
    }

    private var ringColor: Color {
        switch color {
        case .white: Color("lightGrey")
        case .pink: Color("pink")
        case .brown: Color("brown")
        }
    }

    private var label: String {
        switch color {
        case .white: "White"
        case .pink: "Pink"
        case .brown: "Brown"
        }
    }

    @Environment(ThemeColors.self) private var themeColors

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(ringColor, lineWidth: isSelected ? 2.5 : 0)
                    .frame(width: 88, height: 88)
                Circle()
                    .fill(orbGradient)
                    .frame(width: 80, height: 80)
                    .shadow(color: ringColor.opacity(isSelected ? 0.3 : 0.15), radius: 8, x: 2, y: 4)
            }
            .frame(width: 92, height: 92)
            .animation(.easeInOut(duration: 0.2), value: isSelected)

            Text(label)
                .font(.callout)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(themeColors.text)
        }
    }
}

struct WavesCardView: View {
    @Binding var intensity: WavesIntensity

    @Environment(ThemeColors.self) private var themeColors

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Waves")
                .font(.body).fontWeight(.medium)
                .foregroundColor(themeColors.text)

            ChipFlowLayout(spacing: 8) {
                ForEach(WavesIntensity.allCases, id: \.self) { level in
                    TimerChipView(label: level.rawValue, isSelected: intensity == level) {
                        intensity = level
                    }
                }
            }
        }
        .sensoryFeedback(.selection, trigger: intensity)
    }
}

struct FadeCardView: View {
    @Binding var fadeEnabled: Bool
    let accentColor: Color

    @Environment(ThemeColors.self) private var themeColors

    var body: some View {
        HStack {
            Text("Fade")
                .font(.body).fontWeight(.medium)
                .foregroundColor(themeColors.text)
            Spacer()
            Toggle("", isOn: $fadeEnabled)
                .tint(themeColors.noiseColorOverride ?? accentColor)
                .labelsHidden()
        }
    }
}

struct NightlightCardView: View {
    @Binding var nightlightEnabled: Bool
    let accentColor: Color

    @Environment(ThemeColors.self) private var themeColors

    var body: some View {
        HStack {
            Text("Nightlight")
                .font(.body).fontWeight(.medium)
                .foregroundColor(themeColors.text)
            Spacer()
            Toggle("", isOn: $nightlightEnabled)
                .tint(themeColors.noiseColorOverride ?? accentColor)
                .labelsHidden()
        }
    }
}

struct TimerSectionView: View {
    let selectedPreset: TimerPreset?
    let customPresetSeconds: Double?
    let onSelectPreset: (TimerPreset?) -> Void
    let onCustomTapped: () -> Void

    @Environment(ThemeColors.self) private var themeColors

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Timer")
                .font(.body).fontWeight(.medium)
                .foregroundColor(themeColors.text)

            ChipFlowLayout(spacing: 8) {
                TimerChipView(label: "Off", isSelected: selectedPreset == nil) {
                    onSelectPreset(nil)
                }
                ForEach(TimerPreset.standard, id: \.self) { preset in
                    TimerChipView(label: preset.label, isSelected: selectedPreset == preset) {
                        onSelectPreset(preset)
                    }
                }
                if let preset = customPresetSeconds.flatMap(TimerPreset.from), preset.isCustom {
                    TimerChipView(label: preset.label, isSelected: selectedPreset == preset) {
                        onSelectPreset(preset)
                    }
                }
                TimerChipView(label: "Custom ›", isSelected: false) {
                    onCustomTapped()
                }
            }
        }
        .sensoryFeedback(.selection, trigger: selectedPreset)
    }
}

struct Background: View {
    var nightlightBrightness: Double?
    var nightlightBackgroundActive: Bool = false

    @Environment(ThemeColors.self) private var themeColors

    var body: some View {
        themeColors.background.ignoresSafeArea()

        Color.nightlight(brightness: nightlightBrightness ?? 0.0)
            .ignoresSafeArea()
            .opacity(nightlightBackgroundActive ? 1.0 : 0.0)
            .animation(.easeInOut(duration: 2.0), value: nightlightBackgroundActive)
            .animation(.linear(duration: 1.0), value: nightlightBrightness)
    }
}

struct TimerChipView: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    @Environment(ThemeColors.self) private var themeColors

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.body).fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? Color(uiColor: .systemBackground) : themeColors.text)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12).fill(isSelected ? themeColors.text : themeColors.accent)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(themeColors.text.opacity(isSelected ? 0 : 0.12), lineWidth: 1)
                )
        }
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

struct ChipFlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache _: inout Void) -> CGSize {
        let rows = computeRows(maxWidth: proposal.width ?? .infinity, subviews: subviews)
        let height = rows.reduce(0.0) { total, row in
            total + (row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0)
        } + CGFloat(max(rows.count - 1, 0)) * spacing
        return CGSize(width: proposal.width ?? 0, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal _: ProposedViewSize, subviews: Subviews, cache _: inout Void) {
        let rows = computeRows(maxWidth: bounds.width, subviews: subviews)
        var yPos = bounds.minY
        for row in rows {
            var xPos = bounds.minX
            let rowHeight = row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
            for subview in row {
                let size = subview.sizeThatFits(.unspecified)
                subview.place(at: CGPoint(x: xPos, y: yPos), proposal: .unspecified)
                xPos += size.width + spacing
            }
            yPos += rowHeight + spacing
        }
    }

    private func computeRows(maxWidth: CGFloat, subviews: Subviews) -> [[LayoutSubview]] {
        var rows: [[LayoutSubview]] = [[]]
        var rowWidth: CGFloat = 0
        for subview in subviews {
            let width = subview.sizeThatFits(.unspecified).width
            if rowWidth + width > maxWidth, !rows[rows.endIndex - 1].isEmpty {
                rows.append([])
                rowWidth = 0
            }
            rows[rows.endIndex - 1].append(subview)
            rowWidth += width + spacing
        }
        return rows
    }
}

struct PlayAndTimeView: View {
    var isPlaying: Bool
    var timerText: String
    var onPlay: () -> Void

    @State private var pulseScale: CGFloat = 1.0
    @Environment(ThemeColors.self) private var themeColors

    var body: some View {
        VStack(spacing: 12) {
            Button(action: onPlay) {
                ZStack {
                    Circle()
                        .fill(themeColors.text)
                        .frame(width: 84, height: 84)
                    Image(isPlaying ? "pause" : "play")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 48, height: 48)
                        .foregroundColor(Color(uiColor: .systemBackground))
                }
            }
            .scaleEffect(pulseScale)
            .onAppear {
                guard isPlaying else { return }
                withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                    pulseScale = 1.05
                }
            }
            .onChange(of: isPlaying) { _, playing in
                if playing {
                    withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                        pulseScale = 1.05
                    }
                } else {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        pulseScale = 1.0
                    }
                }
            }

            Text(timerText)
                .font(.callout)
                .foregroundColor(.secondary)
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.25), value: timerText)
                .opacity(isPlaying && !timerText.isEmpty ? 1 : 0)
                .animation(.easeInOut(duration: 0.4), value: isPlaying)
                .frame(height: 20)
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: isPlaying) { _, new in new }
        .sensoryFeedback(.impact(weight: .light), trigger: isPlaying) { _, new in !new }
    }
}

struct DurationPicker: View {
    @Binding var duration: TimeInterval
    var isEnabled: Bool = true

    @State private var hours: Int
    @State private var minutes: Int

    init(duration: Binding<TimeInterval>, isEnabled: Bool = true) {
        _duration = duration
        self.isEnabled = isEnabled
        _hours = State(initialValue: duration.wrappedValue.secondsToHours())
        _minutes = State(initialValue: duration.wrappedValue.secondsToMins())
    }

    var body: some View {
        HStack(spacing: 0) {
            Picker("Hours", selection: $hours) {
                ForEach(0 ..< 24, id: \.self) { Text("\($0) hr").tag($0) }
            }
            .pickerStyle(.wheel)

            Picker("Minutes", selection: $minutes) {
                ForEach(0 ..< 60, id: \.self) { Text("\($0) min").tag($0) }
            }
            .pickerStyle(.wheel)
        }
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1.0 : 0.35)
        .onChange(of: hours) { sync() }
        .onChange(of: minutes) { sync() }
        .onChange(of: duration) {
            let hrs = duration.secondsToHours()
            let mins = duration.secondsToMins()
            if hours != hrs { hours = hrs }
            if minutes != mins { minutes = mins }
        }
    }

    private func sync() {
        duration = TimeInterval(hours * 3600 + minutes * 60)
    }
}

private extension Double {
    func secondsToHours() -> Int {
        Int(self) / 3600
    }

    func secondsToMins() -> Int {
        (Int(self) % 3600) / 60
    }
}

private extension View {
    func nightlightBackground(_ brightness: Double?, baseColor: Color) -> some View {
        background(
            ZStack {
                baseColor
                Color.nightlightAccent(brightness: brightness ?? 1.0)
                    .opacity(brightness != nil ? 1.0 : 0.0)
                    .animation(.easeInOut(duration: 2.0), value: brightness == nil)
                    .animation(.linear(duration: 1.0), value: brightness)
            }
        )
    }
}

private extension Color {
    static func nightlight(brightness: Double) -> Color {
        scaled(asset: "nightlightStart", by: brightness)
    }

    static func nightlightAccent(brightness: Double) -> Color {
        scaled(asset: "nightlightAccentStart", by: brightness)
    }

    private static func scaled(asset name: String, by brightness: Double) -> Color {
        guard let base = UIColor(named: name) else { return .clear }
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        base.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return Color(red: red * brightness, green: green * brightness, blue: blue * brightness)
    }
}

private extension UIColor {
    func lightened(by amount: CGFloat = 0.18) -> UIColor {
        var hue: CGFloat = 0, saturation: CGFloat = 0, brightness: CGFloat = 0, alpha: CGFloat = 0
        getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        return UIColor(hue: hue, saturation: max(0, saturation - amount * 0.5), brightness: min(1, brightness + amount), alpha: alpha)
    }
}

private extension NoiseColors {
    func toColor() -> Color {
        switch self {
        case .white: Color("darkGrey")
        case .pink: Color("pink")
        case .brown: Color("brown")
        }
    }
}
