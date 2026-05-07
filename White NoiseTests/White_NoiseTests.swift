@testable import White_Noise
import XCTest

// MARK: - Mock

final class MockPlaybackService: PlaybackService {
    var isPlaying = false
    var fadeSeconds = 0

    private(set) var playCallCount = 0
    private(set) var pauseCallCount = 0
    private(set) var lastPlayColor: NoiseColors?
    private(set) var lastPlayWavesIntensity: WavesIntensity?
    private(set) var lastPlayFade = false
    private(set) var lastSetFadeEnabled: Bool?
    private(set) var lastSetFadeSeconds: Int?
    private(set) var lastResetColor: NoiseColors?

    func play(color: NoiseColors, wavesIntensity: WavesIntensity, fade: Bool) {
        isPlaying = true
        playCallCount += 1
        lastPlayColor = color
        lastPlayWavesIntensity = wavesIntensity
        lastPlayFade = fade
    }

    func pause() {
        isPlaying = false
        pauseCallCount += 1
    }

    func setWavesIntensity(_: WavesIntensity) {}

    func setFade(_ enabled: Bool, seconds: Int) {
        lastSetFadeEnabled = enabled
        lastSetFadeSeconds = seconds
    }

    func reset(color: NoiseColors) {
        lastResetColor = color
    }
}

// MARK: - Tests

final class MainViewModelTests: XCTestCase {
    var audio: MockPlaybackService!
    var settings: SettingsSource!
    var viewModel: MainViewModel!
    var suiteName: String!

    override func setUp() {
        super.setUp()
        suiteName = "test.whitenoise.\(UUID().uuidString)"
        audio = MockPlaybackService()
        settings = SettingsSource()
        settings.userDefaults = UserDefaults(suiteName: suiteName)!
        viewModel = MainViewModel(audio: audio, settings: settings)
    }

    override func tearDown() {
        UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    // MARK: Play / pause

    func testPlay_setsIsPlayingAndCallsAudio() {
        viewModel.play()
        XCTAssertTrue(viewModel.isPlaying)
        XCTAssertEqual(audio.playCallCount, 1)
        XCTAssertEqual(audio.lastPlayColor, .white)
    }

    func testPause_clearsIsPlayingAndCallsAudio() {
        viewModel.play()
        viewModel.pause()
        XCTAssertFalse(viewModel.isPlaying)
        XCTAssertEqual(audio.pauseCallCount, 1)
    }

    func testPlayPause_playsWhenPaused() {
        viewModel.playPause()
        XCTAssertTrue(viewModel.isPlaying)
    }

    func testPlayPause_pausesWhenPlaying() {
        viewModel.play()
        viewModel.playPause()
        XCTAssertFalse(viewModel.isPlaying)
    }

    // MARK: Color

    func testChangeColor_updatesCurrentColor() {
        viewModel.changeColor(.pink)
        XCTAssertEqual(viewModel.currentColor, .pink)
        XCTAssertEqual(audio.lastResetColor, .pink)
    }

    func testChangeColor_noopIfSameColor() {
        viewModel.changeColor(.white)
        XCTAssertNil(audio.lastResetColor)
    }

    func testPlay_usesCurrentColor() {
        viewModel.changeColor(.pink)
        viewModel.play()
        XCTAssertEqual(audio.lastPlayColor, .pink)
    }

    // MARK: Waves / Fade

    func testSetWavesIntensity_updatesStateAndCallsAudio() {
        viewModel.setWavesIntensity(.medium)
        XCTAssertEqual(viewModel.wavesIntensity, .medium)
    }

    func testSetFade_updatesStateAndCallsAudio() {
        viewModel.setFade(true)
        XCTAssertTrue(viewModel.fadeEnabled)
        XCTAssertEqual(audio.lastSetFadeEnabled, true)
    }

    // MARK: Timer

    func testToggleTimer_showsTimer() {
        viewModel.timerPickerSeconds = 300
        viewModel.toggleTimer()
        XCTAssertTrue(viewModel.timerDisplayed)
        XCTAssertFalse(viewModel.timerText.isEmpty)
    }

    func testToggleTimer_cancelsActiveTimer() {
        viewModel.timerPickerSeconds = 300
        viewModel.toggleTimer()
        viewModel.toggleTimer()
        XCTAssertFalse(viewModel.timerDisplayed)
        XCTAssertTrue(viewModel.timerText.isEmpty)
    }

    func testToggleTimer_persistsTimerWhenPlaying() {
        viewModel.play()
        viewModel.timerPickerSeconds = 300
        viewModel.toggleTimer()
        let vm2 = MainViewModel(audio: audio, settings: settings)
        XCTAssertTrue(vm2.timerDisplayed)
        XCTAssertEqual(vm2.timerPickerSeconds, 300)
    }

    func testToggleTimer_persistsCancelWhenPlaying() {
        viewModel.play()
        viewModel.timerPickerSeconds = 300
        viewModel.toggleTimer()
        viewModel.toggleTimer()
        let vm2 = MainViewModel(audio: audio, settings: settings)
        XCTAssertFalse(vm2.timerDisplayed)
    }

    func testToggleTimer_doesNotSaveWhenNotPlaying() {
        viewModel.timerPickerSeconds = 300
        viewModel.toggleTimer()
        let vm2 = MainViewModel(audio: audio, settings: settings)
        XCTAssertFalse(vm2.timerDisplayed)
    }

    func testTimerText_formatsMinutesAndSeconds() {
        viewModel.timerPickerSeconds = 90
        viewModel.toggleTimer()
        XCTAssertEqual(viewModel.timerText, "01:30")
    }

    func testTimerText_includesHoursWhenSet() {
        viewModel.timerPickerSeconds = 3661
        viewModel.toggleTimer()
        XCTAssertEqual(viewModel.timerText, "01:01:01")
    }

    func testTimerExpiry_pausesPlaybackAndHidesTimer() {
        viewModel.timerPickerSeconds = AudioManager.tickInterval
        viewModel.play()
        viewModel.toggleTimer()
        XCTAssertTrue(viewModel.isPlaying)
        XCTAssertTrue(viewModel.timerDisplayed)

        viewModel.tick()
        XCTAssertFalse(viewModel.isPlaying)
        XCTAssertFalse(viewModel.timerDisplayed)
        XCTAssertTrue(viewModel.timerText.isEmpty)
    }

    // MARK: Intent handling

    func testHandleStartIntent_updatesStateAndPlays() {
        viewModel.handleStartIntent(colorRaw: "pink", waves: true, fade: false)
        XCTAssertEqual(viewModel.currentColor, .pink)
        XCTAssertNotEqual(viewModel.wavesIntensity, .off)
        XCTAssertTrue(viewModel.isPlaying)
        XCTAssertEqual(audio.lastPlayColor, .pink)
        XCTAssertNotEqual(audio.lastPlayWavesIntensity, .off)
    }

    func testHandleStartIntent_unknownColorDefaultsToWhite() {
        viewModel.handleStartIntent(colorRaw: "invalid", waves: false, fade: false)
        XCTAssertEqual(viewModel.currentColor, .white)
    }

    func testHandlePauseIntent_pauses() {
        viewModel.play()
        viewModel.handlePauseIntent()
        XCTAssertFalse(viewModel.isPlaying)
    }

    func testIntent_overridesSettings() {
        settings.setColor(.brown)
        settings.setFade(true)
        let viewModel = MainViewModel(audio: audio, settings: settings)
        viewModel.handleStartIntent(colorRaw: "pink", waves: true, fade: false)
        XCTAssertEqual(viewModel.currentColor, .pink)
        XCTAssertNotEqual(viewModel.wavesIntensity, .off)
        XCTAssertEqual(viewModel.fadeEnabled, false)
    }

    // MARK: Saved state

    func testInit_restoresSavedColor() {
        settings.setColor(.brown)
        let viewModel = MainViewModel(audio: audio, settings: settings)
        XCTAssertEqual(viewModel.currentColor, .brown)
    }

    func testInit_restoresSavedWavesAndFade() {
        settings.setWaves(true)
        settings.setFade(true)
        let viewModel = MainViewModel(audio: audio, settings: settings)
        XCTAssertNotEqual(viewModel.wavesIntensity, .off)
        XCTAssertTrue(viewModel.fadeEnabled)
    }

    func testInit_restoresSavedTimer() {
        settings.setTimer(600)
        let viewModel = MainViewModel(audio: audio, settings: settings)
        XCTAssertTrue(viewModel.timerDisplayed)
        XCTAssertEqual(viewModel.timerPickerSeconds, 600)
        XCTAssertEqual(viewModel.timerText, "10:00")
    }

    func testInit_noTimerWhenNotSaved() {
        let viewModel = MainViewModel(audio: audio, settings: settings)
        XCTAssertFalse(viewModel.timerDisplayed)
        XCTAssertTrue(viewModel.timerText.isEmpty)
    }

    // MARK: Foreground sync

    func testForeground_beginsPlayingWhenAudioAlreadyRunning() {
        audio.isPlaying = true
        viewModel.appWillEnterForeground()
        XCTAssertTrue(viewModel.isPlaying)
    }

    func testForeground_stopsPlayingWhenAudioStopped() {
        viewModel.play()
        audio.isPlaying = false
        viewModel.appWillEnterForeground()
        XCTAssertFalse(viewModel.isPlaying)
    }

    func testForeground_syncsColorFromSettingsWhenPlaying() {
        viewModel.isPlaying = true
        audio.isPlaying = true
        settings.setColor(.brown)
        viewModel.appWillEnterForeground()
        XCTAssertEqual(viewModel.currentColor, .brown)
    }

    func testForeground_clearsTimerRemovedExternally() {
        viewModel.isPlaying = true
        audio.isPlaying = true
        viewModel.timerPickerSeconds = 300
        viewModel.toggleTimer()
        settings.setTimer(nil)
        viewModel.appWillEnterForeground()
        XCTAssertFalse(viewModel.timerDisplayed)
        XCTAssertTrue(viewModel.timerText.isEmpty)
    }

    func testForeground_restoresTimerSetExternally() {
        viewModel.isPlaying = true
        audio.isPlaying = true
        settings.setTimer(600)
        viewModel.appWillEnterForeground()
        XCTAssertTrue(viewModel.timerDisplayed)
        XCTAssertEqual(viewModel.timerPickerSeconds, 600)
        XCTAssertEqual(viewModel.timerText, "10:00")
    }

    func testForeground_isTriggeredByNotification() {
        audio.isPlaying = true
        NotificationCenter.default.post(name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        XCTAssertTrue(viewModel.isPlaying)
    }
}
