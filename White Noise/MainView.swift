import SwiftUI
import UIKit

private extension UIColor {
    func lightened(by amount: CGFloat = 0.18) -> UIColor {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return UIColor(hue: h, saturation: max(0, s - amount * 0.5), brightness: min(1, b + amount), alpha: a)
    }
}

struct MainView: View {
    @Bindable var viewModel: MainViewModel
    @State private var settingsPresented = false
    @State private var customTimerPresented = false
    @State private var pulseScale: CGFloat = 1.0

    private var accentColor: Color {
        switch viewModel.currentColor {
        case .white: Color("darkGrey")
        case .pink: Color("pink")
        case .brown: Color("brown")
        }
    }

    var body: some View {
        ZStack {
            Color(uiColor: .systemBackground).ignoresSafeArea()

            VStack {
                Spacer()
                RadialGradient(
                    colors: [accentColor.opacity(0.38), .clear],
                    center: UnitPoint(x: 0.5, y: 1.1),
                    startRadius: 0,
                    endRadius: 340
                )
                .frame(height: 340)
                .allowsHitTesting(false)
                .animation(.easeInOut(duration: 0.6), value: viewModel.currentColor)
            }
            .ignoresSafeArea(edges: .bottom)

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button { settingsPresented = true } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 15))
                            .foregroundColor(Color("text"))
                            .frame(width: 34, height: 34)
                            .overlay(Circle().stroke(Color("text").opacity(0.18), lineWidth: 1))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                HStack(spacing: 24) {
                    ForEach([NoiseColors.white, .pink, .brown], id: \.self) { color in
                        NoiseOrbView(color: color, isSelected: viewModel.currentColor == color)
                            .onTapGesture { viewModel.changeColor(color) }
                    }
                }
                .padding(.top, 28)

                VStack(spacing: 8) {
                    WavesCardView(
                        intensity: Binding(
                            get: { viewModel.wavesIntensity },
                            set: { viewModel.setWavesIntensity($0) }
                        )
                    )

                    FadeCardView(
                        fadeEnabled: Binding(
                            get: { viewModel.fadeEnabled },
                            set: { viewModel.setFade($0) }
                        ),
                        accentColor: accentColor
                    )

                    TimerSectionView(
                        selectedPreset: viewModel.selectedTimerPreset,
                        customPresetSeconds: viewModel.customPresetSeconds,
                        onSelectPreset: { viewModel.setTimerPreset($0) },
                        onCustomTapped: { customTimerPresented = true }
                    )
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)



                Spacer()

                VStack(spacing: 12) {
                    Button(action: viewModel.playPause) {
                        ZStack {
                            Circle()
                                .fill(Color("text"))
                                .frame(width: 84, height: 84)
                            Image(viewModel.isPlaying ? "pause" : "play")
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 30, height: 30)
                                .foregroundColor(Color(uiColor: .systemBackground))
                        }
                    }
                    .scaleEffect(pulseScale)
                    .onAppear {
                        guard viewModel.isPlaying else { return }
                        withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                            pulseScale = 1.05
                        }
                    }
                    .onChange(of: viewModel.isPlaying) { _, playing in
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

                    Text(viewModel.timerText)
                        .font(.callout)
                        .foregroundColor(.secondary)
                        .contentTransition(.numericText())
                        .animation(.easeInOut(duration: 0.25), value: viewModel.timerText)
                        .opacity(viewModel.isPlaying && !viewModel.timerText.isEmpty ? 1 : 0)
                        .animation(.easeInOut(duration: 0.4), value: viewModel.isPlaying)
                        .frame(height: 20)
                }
                .padding(.bottom, 52)
            }
        }
        .preferredColorScheme(viewModel.colorScheme)
        .sensoryFeedback(.impact(weight: .medium), trigger: viewModel.isPlaying) { _, new in new }
        .sensoryFeedback(.impact(weight: .light), trigger: viewModel.isPlaying) { _, new in !new }
        .sensoryFeedback(.selection, trigger: viewModel.currentColor)
        .sensoryFeedback(.selection, trigger: viewModel.selectedTimerPreset)
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

// MARK: - Noise Orb

struct NoiseOrbView: View {
    let color: NoiseColors
    let isSelected: Bool

    private var orbGradient: RadialGradient {
        switch color {
        case .white:
            RadialGradient(
                colors: [Color(UIColor(named: "darkGrey")!.lightened(by: 0.32)), Color(UIColor(named: "darkGrey")!.lightened(by: 0.25))],
                center: UnitPoint(x: 0.38, y: 0.32),
                startRadius: 8,
                endRadius: 46
            )
        case .pink:
            RadialGradient(
                colors: [Color(UIColor(named: "pink")!.lightened(by: 0.25)), Color("pink")],
                center: UnitPoint(x: 0.38, y: 0.32),
                startRadius: 8,
                endRadius: 46
            )
        case .brown:
            RadialGradient(
                colors: [Color(UIColor(named: "brown")!.lightened(by: 0.18)), Color("brown")],
                center: UnitPoint(x: 0.38, y: 0.32),
                startRadius: 8,
                endRadius: 46
            )
        }
    }

    private var ringColor: Color {
        switch color {
        case .white: Color("darkGrey")
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
                .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? Color("text") : .secondary)
        }
    }
}

// MARK: - Waves Card

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
        .padding(14)
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Fade Card

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
        .padding(14)
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Timer Section

struct TimerSectionView: View {
    let selectedPreset: TimerPreset?
    let customPresetSeconds: Double?
    let onSelectPreset: (TimerPreset?) -> Void
    let onCustomTapped: () -> Void

    private func formatDuration(_ seconds: Double) -> String {
        let total = Int(seconds)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        if hours > 0 && minutes > 0 { return "\(hours)h \(minutes)m" }
        if hours > 0 { return "\(hours)h" }
        return "\(minutes)m"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Timer")
                .font(.body).fontWeight(.medium)
                .foregroundColor(Color("text"))

            ChipFlowLayout(spacing: 8) {
                TimerChipView(label: "Off", isSelected: selectedPreset == nil) {
                    onSelectPreset(nil)
                }
                ForEach([TimerPreset.min15, .min30, .hour1, .hour4], id: \.rawValue) { preset in
                    TimerChipView(label: preset.rawValue, isSelected: selectedPreset == preset) {
                        onSelectPreset(preset)
                    }
                }
                if let secs = customPresetSeconds,
                   ![TimerPreset.min15, .min30, .hour1, .hour4].map(\.seconds).contains(secs) {
                    TimerChipView(label: formatDuration(secs), isSelected: selectedPreset == .custom) {
                        onSelectPreset(.custom)
                    }
                }
                TimerChipView(label: "Custom ›", isSelected: false) {
                    onCustomTapped()
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(12)
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
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 11)
                        .fill(isSelected ? Color("text") : Color(uiColor: .secondarySystemBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 11)
                        .stroke(Color("text").opacity(isSelected ? 0 : 0.12), lineWidth: 1)
                )
        }
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

// MARK: - Custom Timer Sheet

struct CustomTimerSheet: View {
    @Binding var duration: TimeInterval
    let onSet: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color(uiColor: .systemFill))
                .frame(width: 36, height: 5)
                .padding(.top, 8)
                .padding(.bottom, 16)

            Text("Sleep timer")
                .font(.title3).fontWeight(.semibold)
                .foregroundColor(Color("text"))
                .padding(.bottom, 8)

            DurationPicker(duration: $duration, isEnabled: true)
                .frame(height: 200)
                .padding(.horizontal, 16)

            HStack(spacing: 12) {
                Button(action: onCancel) {
                    Text("Cancel")
                        .font(.body).fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(uiColor: .secondarySystemBackground))
                        .cornerRadius(12)
                        .foregroundColor(Color("text"))
                }
                Button(action: onSet) {
                    Text("Set timer")
                        .font(.body).fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color("text"))
                        .cornerRadius(12)
                        .foregroundColor(Color(uiColor: .systemBackground))
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .presentationDetents([.height(440)])
        .presentationDragIndicator(.hidden)
    }
}

// MARK: - Flow Layout

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

// MARK: - Duration Picker (used in Custom Timer Sheet)

struct DurationPicker: View {
    @Binding var duration: TimeInterval
    var isEnabled: Bool = true

    @State private var hours: Int
    @State private var minutes: Int

    init(duration: Binding<TimeInterval>, isEnabled: Bool = true) {
        _duration = duration
        self.isEnabled = isEnabled
        let total = Int(duration.wrappedValue)
        _hours = State(initialValue: total / 3600)
        _minutes = State(initialValue: (total % 3600) / 60)
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
            let total = Int(duration)
            let hrs = total / 3600
            let mins = (total % 3600) / 60
            if hours != hrs { hours = hrs }
            if minutes != mins { minutes = mins }
        }
    }

    private func sync() {
        duration = TimeInterval(hours * 3600 + minutes * 60)
    }
}
