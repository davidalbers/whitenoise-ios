import SwiftUI
import UIKit

struct MainView: View {
    @Bindable var viewModel: MainViewModel
    @State private var settingsPresented = false
    @State private var customTimerPresented = false
    @State private var themeColors: ThemeColors
    @Environment(\.colorScheme) private var colorScheme

    init(viewModel: MainViewModel) {
        self.viewModel = viewModel
        let colors = ThemeColors()
        colors.apply(viewModel.theme)
        _themeColors = State(initialValue: colors)
    }

    var body: some View {
        ZStack {
            themeColors.background.ignoresSafeArea()

            GradientView(accentColor: viewModel.currentColor.toColor())

            ScrollView {
                VStack {
                    TopRowView { settingsPresented = true }
                        .padding(.horizontal, 16)

                    NoiseSelectorView(
                        availableColors: viewModel.availableColors,
                        currentColor: viewModel.currentColor
                    ) {
                        viewModel.changeColor($0)
                    }
                    .background(themeColors.background)
                    .cornerRadius(12)
                    .padding(.top, 20)

                    WavesCardView(
                        intensity: Binding(
                            get: { viewModel.wavesIntensity },
                            set: { viewModel.setWavesIntensity($0) }
                        )
                    )
                    .padding(16)
                    .background(themeColors.accent)
                    .cornerRadius(12)
                    .padding(.top, 8)
                    .padding(.horizontal, 16)

                    FadeCardView(
                        fadeEnabled: Binding(
                            get: { viewModel.fadeEnabled },
                            set: { viewModel.setFade($0) }
                        ),
                        accentColor: viewModel.currentColor.toColor()
                    )
                    .padding(16)
                    .background(themeColors.accent)
                    .cornerRadius(12)
                    .padding(.top, 8)
                    .padding(.horizontal, 16)

                    TimerSectionView(
                        selectedPreset: viewModel.selectedTimerPreset,
                        customPresetSeconds: viewModel.customPresetSeconds,
                        onSelectPreset: { viewModel.setTimerPreset($0) },
                        onCustomTapped: { customTimerPresented = true }
                    )
                    .padding(16)
                    .background(themeColors.accent)
                    .cornerRadius(12)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 140)
                }
            }

            VStack {
                Spacer()
                PlayAndTimeView(
                    isPlaying: viewModel.isPlaying,
                    timerText: viewModel.timerText
                ) {
                    viewModel.playPause()
                }
                .padding(.bottom, 24)
            }
        }
        .environment(themeColors)
        .preferredColorScheme(viewModel.colorScheme)
        .onAppear { themeColors.apply(viewModel.theme) }
        .sheet(isPresented: $settingsPresented) {
            SettingsView(
                dismissAction: { settingsPresented = false },
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
    var availableColors: [NoiseColors]
    var currentColor: NoiseColors
    var colorSelected: (NoiseColors) -> Void

    @State private var scrollAtStart = true
    @State private var scrollAtEnd = false
    @Environment(ThemeColors.self) private var themeColors

    var body: some View {
        Group {
            if availableColors.count > 3 {
                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 24) {
                            ForEach(availableColors, id: \.self) { color in
                                NoiseOrbView(color: color, isSelected: currentColor == color, isCompact: true)
                                    .id(color)
                                    .onTapGesture { colorSelected(color) }
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    .onScrollGeometryChange(for: Bool.self) { geo in
                        geo.contentOffset.x <= 1
                    } action: { _, atStart in
                        withAnimation(.easeInOut(duration: 0.2)) { scrollAtStart = atStart }
                    }
                    .onScrollGeometryChange(for: Bool.self) { geo in
                        geo.contentOffset.x >= geo.contentSize.width - geo.containerSize.width - 1
                    } action: { _, atEnd in
                        withAnimation(.easeInOut(duration: 0.2)) { scrollAtEnd = atEnd }
                    }
                    .overlay(alignment: .leading) {
                        LinearGradient(
                            colors: [themeColors.background, themeColors.background.opacity(0)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: 64)
                        .opacity(scrollAtStart ? 0 : 1)
                        .allowsHitTesting(false)
                    }
                    .overlay(alignment: .trailing) {
                        LinearGradient(
                            colors: [themeColors.background.opacity(0), themeColors.background],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: 64)
                        .opacity(scrollAtEnd ? 0 : 1)
                        .allowsHitTesting(false)
                    }
                    .onAppear {
                        proxy.scrollTo(currentColor, anchor: .center)
                    }
                }
            } else {
                HStack(spacing: 24) {
                    ForEach(availableColors, id: \.self) { color in
                        NoiseOrbView(color: color, isSelected: currentColor == color, isCompact: false)
                            .id(color)
                            .onTapGesture { colorSelected(color) }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 24)
            }
        }
        .sensoryFeedback(.selection, trigger: currentColor)
    }
}

struct NoiseOrbView: View {
    let color: NoiseColors
    let isSelected: Bool
    var isCompact: Bool = false

    private var orbGradient: RadialGradient {
        let colors: [Color] = switch color {
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
            startRadius: isCompact ? 6 : 8,
            endRadius: isCompact ? 37 : 46
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
                    .frame(width: isCompact ? 70 : 88, height: isCompact ? 70 : 88)
                Circle()
                    .fill(orbGradient)
                    .frame(width: isCompact ? 64 : 80, height: isCompact ? 64 : 80)
                    .shadow(color: ringColor.opacity(isSelected ? 0.3 : 0.15), radius: 8, x: 2, y: 4)
            }
            .frame(width: isCompact ? 74 : 92, height: isCompact ? 74 : 92)
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

private extension NoiseColors {
    func toColor() -> Color {
        switch self {
        case .white: Color("darkGrey")
        case .pink: Color("pink")
        case .brown: Color("brown")
        }
    }
}
