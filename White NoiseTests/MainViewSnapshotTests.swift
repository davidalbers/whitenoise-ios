import SnapshotTesting
import SwiftUI
import UIKit
@testable import White_Noise
import XCTest

@MainActor
final class MainViewSnapshotTests: XCTestCase {
    // MARK: - Helper

    private func assertView(
        _ view: some View,
        width: CGFloat = 390,
        height: CGFloat,
        file: StaticString = #file,
        testName: String = #function,
        line: UInt = #line
    ) {
        let vc = UIHostingController(rootView: view.environment(ThemeColors()))
        assertSnapshot(
            of: vc,
            as: .image(on: ViewImageConfig(size: CGSize(width: width, height: height))),
            record: false,
            file: file,
            testName: testName,
            line: line
        )
    }

    // MARK: - NoiseOrbView

    func testNoiseOrbView_unselected() {
        assertView(NoiseOrbView(color: .pink, isSelected: false).padding(16), height: 130)
    }

    func testNoiseOrbView_selected() {
        assertView(NoiseOrbView(color: .pink, isSelected: true).padding(16), height: 130)
    }

    // MARK: - NoiseSelectorView

    func testNoiseSelectorView_threeColors_whiteSelected() {
        assertView(
            NoiseSelectorView(
                availableColors: [.white, .pink, .brown],
                currentColor: .white,
                colorSelected: { _ in }
            ),
            height: 130
        )
    }

    func testNoiseSelectorView_threeColors_pinkSelected() {
        assertView(
            NoiseSelectorView(
                availableColors: [.white, .pink, .brown],
                currentColor: .pink,
                colorSelected: { _ in }
            ),
            height: 130
        )
    }

    // MARK: - WavesCardView

    func testWavesCardView_off() {
        assertView(WavesCardView(intensity: .constant(.off)).padding(16), height: 100)
    }

    func testWavesCardView_low() {
        assertView(WavesCardView(intensity: .constant(.low)).padding(16), height: 100)
    }

    func testWavesCardView_medium() {
        assertView(WavesCardView(intensity: .constant(.medium)).padding(16), height: 100)
    }

    func testWavesCardView_high() {
        assertView(WavesCardView(intensity: .constant(.high)).padding(16), height: 100)
    }

    // MARK: - FadeCardView

    func testFadeCardView_off() {
        assertView(FadeCardView(fadeEnabled: .constant(false), accentColor: Color("pink")).padding(16), height: 70)
    }

    func testFadeCardView_on() {
        assertView(FadeCardView(fadeEnabled: .constant(true), accentColor: Color("pink")).padding(16), height: 70)
    }

    // MARK: - TimerSectionView

    func testTimerSectionView_noPreset() {
        assertView(
            TimerSectionView(
                selectedPreset: nil,
                customPresetSeconds: nil,
                onSelectPreset: { _ in },
                onCustomTapped: {}
            )
            .padding(16),
            height: 160
        )
    }

    func testTimerSectionView_thirtyMinutesSelected() {
        let preset = TimerPreset(hours: 0, minutes: 30)
        assertView(
            TimerSectionView(
                selectedPreset: preset,
                customPresetSeconds: nil,
                onSelectPreset: { _ in },
                onCustomTapped: {}
            )
            .padding(16),
            height: 160
        )
    }

    func testTimerSectionView_customPresetSelected() {
        let preset = TimerPreset(hours: 2, minutes: 45)
        assertView(
            TimerSectionView(
                selectedPreset: preset,
                customPresetSeconds: preset.seconds,
                onSelectPreset: { _ in },
                onCustomTapped: {}
            )
            .padding(16),
            height: 160
        )
    }

    // MARK: - PlayAndTimeView

    func testPlayAndTimeView_paused() {
        assertView(PlayAndTimeView(isPlaying: false, timerText: "") {}, height: 140)
    }

    func testPlayAndTimeView_playing() {
        assertView(PlayAndTimeView(isPlaying: true, timerText: "") {}, height: 140)
    }

    func testPlayAndTimeView_playing_withTimer() {
        assertView(PlayAndTimeView(isPlaying: true, timerText: "01:00:00") {}, height: 140)
    }

    // MARK: - TimerChipView

    func testTimerChipView_unselected() {
        assertView(TimerChipView(label: "30m", isSelected: false) {}.padding(16), height: 60)
    }

    func testTimerChipView_selected() {
        assertView(TimerChipView(label: "30m", isSelected: true) {}.padding(16), height: 60)
    }

    // MARK: - TopRowView

    func testTopRowView() {
        assertView(TopRowView(settingsPresented: {}).padding(.horizontal, 16), height: 50)
    }

    // MARK: - GradientView

    func testGradientView_pink() {
        assertView(GradientView(accentColor: Color("pink")), height: 360)
    }

    func testGradientView_brown() {
        assertView(GradientView(accentColor: Color("brown")), height: 360)
    }

    // MARK: - MainView helpers

    private func assertMainView(
        on config: ViewImageConfig = .iPhone13Pro,
        named name: String? = nil,
        configure: (MainViewModel) -> Void = { _ in },
        file: StaticString = #file,
        testName: String = #function,
        line: UInt = #line
    ) {
        let suiteName = "test.whitenoise.\(UUID().uuidString)"
        let settings = SettingsSource()
        settings.userDefaults = UserDefaults(suiteName: suiteName)!
        let vm = MainViewModel(audio: MockPlaybackService(), settings: settings)
        configure(vm)
        let view = MainView(viewModel: vm)
            .environment(ThemeColors())
        let vc = UIHostingController(rootView: view)
        vc.overrideUserInterfaceStyle = switch vm.colorScheme {
        case .light: .light
        case .dark: .dark
        default: .unspecified
        }
        assertSnapshot(
            of: vc,
            as: .image(on: config),
            named: name,
            record: false,
            file: file,
            testName: testName,
            line: line
        )
    }

    // MARK: - MainView

    func testMainView_paused() {
        assertMainView()
    }

    func testMainView_playing() {
        assertMainView { $0.isPlaying = true }
    }

    func testMainView_brownSelected() {
        assertMainView { $0.currentColor = .brown }
    }

    func testMainView_playing_withTimer() {
        assertMainView { vm in
            vm.isPlaying = true
            vm.selectedTimerPreset = TimerPreset(hours: 0, minutes: 30)
            vm.timerText = "29:59"
            vm.timerDisplayed = true
        }
    }

    func testMainView_playing_withTimer_themes() {
        let themes: [(String, Themer.Theme)] = [
            ("auto", .auto),
            ("dark", .dark),
            ("light", .light),
        ]
        for (name, theme) in themes {
            assertMainView(named: name) { vm in
                vm.isPlaying = true
                vm.selectedTimerPreset = TimerPreset(hours: 0, minutes: 30)
                vm.timerText = "29:59"
                vm.timerDisplayed = true
                vm.theme = theme
            }
        }
    }

    func testMainView_playing_withTimer_deviceSizes() {
        let devices: [(String, ViewImageConfig)] = [
            ("small-iPhone", .iPhoneSe),
            ("large-iPhone", .iPhone13ProMax),
            ("iPad", .iPadPro11),
        ]
        for (name, config) in devices {
            assertMainView(on: config, named: name) { vm in
                vm.isPlaying = true
                vm.selectedTimerPreset = TimerPreset(hours: 0, minutes: 30)
                vm.timerText = "29:59"
                vm.timerDisplayed = true
            }
        }
    }
}
