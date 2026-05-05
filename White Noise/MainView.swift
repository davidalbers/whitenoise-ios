import SwiftUI

struct MainView: View {
    @Bindable var viewModel: MainViewModel
    @State private var settingsPresented = false
    @State private var pulseScale: CGFloat = 1.0

    private var accentColor: Color {
        switch viewModel.currentColor {
        case .white: Color("darkGrey")
        case .pink: Color("pink")
        case .brown: Color("brown")
        }
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Button { settingsPresented = true } label: {
                Image(systemName: "gear")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundColor(Color("text"))
                    .padding()
            }

            VStack {
                Picker("Color", selection: Binding(
                    get: { viewModel.currentColor },
                    set: { viewModel.changeColor($0) }
                )) {
                    Text("White").tag(NoiseColors.white)
                    Text("Pink").tag(NoiseColors.pink)
                    Text("Brown").tag(NoiseColors.brown)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 64)

                Toggle(isOn: Binding(
                    get: { viewModel.wavesEnabled },
                    set: { viewModel.setWaves($0) }
                )) {
                    Text("Waves")
                }
                .tint(accentColor)
                .padding(.horizontal)
                .padding(.top, 16)

                Toggle(isOn: Binding(
                    get: { viewModel.fadeEnabled },
                    set: { viewModel.setFade($0) }
                )) {
                    Text("Fade")
                }
                .tint(accentColor)
                .padding(.horizontal)
                .padding(.top, 16)

                DurationPicker(duration: $viewModel.timerPickerSeconds, isEnabled: !viewModel.timerDisplayed)
                    .padding(.top, 16)

                HStack(spacing: 16) {
                    let canAdd = viewModel.timerDisplayed || viewModel.timerPickerSeconds > 0
                    Button(action: viewModel.toggleTimer) {
                        Image(viewModel.timerDisplayed ? "delete" : "add")
                            .renderingMode(.template)
                            .foregroundColor(Color("text"))
                            .opacity(canAdd ? 1.0 : 0.35)
                    }
                    .disabled(!canAdd)
                    if !viewModel.timerText.isEmpty {
                        Text(viewModel.timerText)
                            .foregroundColor(Color("text"))
                            .transition(.opacity)
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: viewModel.timerDisplayed)
                .padding(.top, 16)

                Spacer()

                Group {
                    Button(action: viewModel.playPause) {
                        Image(viewModel.isPlaying ? "pause" : "play")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 72, height: 72)
                            .foregroundColor(Color("text"))
                    }
                    .animation(.easeInOut(duration: 0.3), value: viewModel.isPlaying)
                }
                .scaleEffect(pulseScale)
                .onAppear {
                    guard viewModel.isPlaying else { return }
                    withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                        pulseScale = 1.08
                    }
                }
                .onChange(of: viewModel.isPlaying) { _, playing in
                    if playing {
                        withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                            pulseScale = 1.08
                        }
                    } else {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            pulseScale = 1.0
                        }
                    }
                }
                .padding(.bottom, 64)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sensoryFeedback(.impact(weight: .medium), trigger: viewModel.isPlaying) { _, new in new }
        .sensoryFeedback(.impact(weight: .light), trigger: viewModel.isPlaying) { _, new in !new }
        .sensoryFeedback(.selection, trigger: viewModel.currentColor)
        .sensoryFeedback(.impact(weight: .medium), trigger: viewModel.timerDisplayed) { _, new in new }
        .sensoryFeedback(.impact(weight: .light), trigger: viewModel.timerDisplayed) { _, new in !new }
        }
        .preferredColorScheme(viewModel.colorScheme)
        .sheet(isPresented: $settingsPresented) {
            SettingsView(dismissAction: { settingsPresented = false }, onThemeChanged: { cs in
                viewModel.colorScheme = cs
            })
        }
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
            let h = total / 3600
            let m = (total % 3600) / 60
            if hours != h { hours = h }
            if minutes != m { minutes = m }
        }
    }

    private func sync() {
        duration = TimeInterval(hours * 3600 + minutes * 60)
    }
}
