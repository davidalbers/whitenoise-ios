import SwiftUI
import UIKit

struct MainView: View {
    @Bindable var viewModel: MainViewModel
    @State private var settingsPresented = false
    @State private var customTimerPresented = false

    var body: some View {
        ZStack {
            Color("background").ignoresSafeArea()

            GradientView(accentColor: viewModel.currentColor.toColor())

            VStack {
                TopRowView { settingsPresented = true }
                    .padding(.horizontal, 16)

                NoiseSelectorView(currentColor: viewModel.currentColor) {
                    viewModel.changeColor($0)

                }
                .padding(.top, 20)

                WavesCardView(
                    intensity: Binding(
                        get: { viewModel.wavesIntensity },
                        set: { viewModel.setWavesIntensity($0) }
                    )
                )
                .padding(.horizontal, 16)
                .padding(.top, 20)

                FadeCardView(
                    fadeEnabled: Binding(
                        get: { viewModel.fadeEnabled },
                        set: { viewModel.setFade($0) }
                    ),
                    accentColor: viewModel.currentColor.toColor()
                )
                .padding(.horizontal, 16)
                .padding(.top, 8)

                TimerSectionView(
                    selectedPreset: viewModel.selectedTimerPreset,
                    customPresetSeconds: viewModel.customPresetSeconds,
                    onSelectPreset: { viewModel.setTimerPreset($0) },
                    onCustomTapped: { customTimerPresented = true }
                )
                .padding(.horizontal, 16)
                .padding(.top, 8)

                Spacer()

                PlayAndTimeView(
                    isPlaying: viewModel.isPlaying,
                    timerText: viewModel.timerText
                ) {
                    viewModel.playPause()
                }.padding(.bottom, 52)
            }
        }
        .preferredColorScheme(viewModel.colorScheme)
        .sheet(isPresented: $settingsPresented) {
            SettingsView(
                dismissAction: { settingsPresented = false },
                onThemeChanged: { colorScheme in viewModel.colorScheme = colorScheme }
            )
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
        }
    }
}

struct GradientView: View {
    var accentColor: Color

    var body: some View {
        VStack {
            Spacer()
            RadialGradient(
                colors: [accentColor.opacity(0.75), .clear],
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

    var body: some View {
        HStack {
            Spacer()
            Button(
                action: settingsPresented,
                label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(Color("text"))
                        .frame(width: 34, height: 34)
                        .overlay(Circle().stroke(Color("text").opacity(0.18), lineWidth: 1))
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
        }.sensoryFeedback(.selection, trigger: currentColor)
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
                Color(UIColor(named: "lightGrey")!.lightened(by: 0.25))
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
                .foregroundColor(isSelected ? Color("text") : .secondary)
        }
    }
}

struct WavesCardView: View {
    @Binding var intensity: WavesIntensity

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Waves")
                .font(.body).fontWeight(.medium)
                .foregroundColor(Color("text"))

            ChipFlowLayout(spacing: 8) {
                ForEach(WavesIntensity.allCases, id: \.self) { level in
                    TimerChipView(label: level.rawValue, isSelected: intensity == level) {
                        intensity = level
                    }
                }
            }
        }
        .padding(16)
        .background(Color("accent"))
        .cornerRadius(12)
        .sensoryFeedback(.selection, trigger: intensity)
    }
}

struct FadeCardView: View {
    @Binding var fadeEnabled: Bool
    let accentColor: Color

    var body: some View {
        HStack {
            Text("Fade")
                .font(.body).fontWeight(.medium)
                .foregroundColor(Color("text"))
            Spacer()
            Toggle("", isOn: $fadeEnabled)
                .tint(accentColor)
                .labelsHidden()
        }
        .padding(16)
        .background(Color("accent"))
        .cornerRadius(12)
    }
}

struct TimerSectionView: View {
    let selectedPreset: TimerPreset?
    let customPresetSeconds: Double?
    let onSelectPreset: (TimerPreset?) -> Void
    let onCustomTapped: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Timer")
                .font(.body).fontWeight(.medium)
                .foregroundColor(Color("text"))

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
        .padding(16)
        .background(Color("accent"))
        .cornerRadius(12)
        .sensoryFeedback(.selection, trigger: selectedPreset)
    }
}

struct TimerChipView: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.body).fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? Color(uiColor: .systemBackground) : Color("text"))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? Color("text") : Color("accent"))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color("text").opacity(isSelected ? 0 : 0.12), lineWidth: 1)
                )
        }
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

struct ChipFlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let rows = computeRows(maxWidth: proposal.width ?? .infinity, subviews: subviews)
        let height = rows.reduce(0.0) { total, row in
            total + (row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0)
        } + CGFloat(max(rows.count - 1, 0)) * spacing
        return CGSize(width: proposal.width ?? 0, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        let rows = computeRows(maxWidth: bounds.width, subviews: subviews)
        var y = bounds.minY
        for row in rows {
            var x = bounds.minX
            let rowHeight = row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
            for subview in row {
                let size = subview.sizeThatFits(.unspecified)
                subview.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
                x += size.width + spacing
            }
            y += rowHeight + spacing
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

    var body: some View {
        VStack(spacing: 12) {
            Button(action: onPlay) {
                ZStack {
                    Circle()
                        .fill(Color("text"))
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
        return Int(self) / 3600
    }

    func secondsToMins() -> Int {
        return (Int(self) % 3600) / 60
    }
}

private extension UIColor {
    func lightened(by amount: CGFloat = 0.18) -> UIColor {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return UIColor(hue: h, saturation: max(0, s - amount * 0.5), brightness: min(1, b + amount), alpha: a)
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
