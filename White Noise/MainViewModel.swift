import MediaPlayer
import Observation
import SwiftUI
import UIKit

@Observable
final class MainViewModel {
    var isPlaying = false
    var currentColor: NoiseColors = .white
    var wavesIntensity: WavesIntensity = .medium
    var fadeEnabled = false
    var timerPickerSeconds: Double = 600
    var timerDisplayed = false
    var timerText = ""
    var selectedTimerPreset: TimerPreset?
    var customPresetSeconds: Double?
    var theme: Themer.Theme
    var colorScheme: ColorScheme?
    var nightlightEnabled = false
    var nightlightBrightness: Double = 0.0

    private var timerActive = false
    private var timeLeftSecs: Double = 0
    private var prevTime = 0
    private var tickTimer: Timer?
    private var nightlightTimer: Timer?
    private var nightlightElapsedSecs: Double = 0
    private let nightlightDuration: Double = 600

    private let audio: PlaybackService
    private let settings: SettingsSource

    init(audio: PlaybackService = AudioManager.shared, settings: SettingsSource = SettingsSource()) {
        self.audio = audio
        self.settings = settings
        let themer = Themer()
        theme = themer.getTheme()
        colorScheme = themer.getColorScheme()
        loadSavedState()
        setupRemoteCommandCenter()
        setupForegroundObserver()
        if audio.isPlaying {
            isPlaying = true
            startTickTimer()
            updateNowPlaying()
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        tickTimer?.invalidate()
        nightlightTimer?.invalidate()
    }

    func reloadTheme() {
        let themer = Themer()
        theme = themer.getTheme()
        colorScheme = themer.getColorScheme()
    }

    func playPause() {
        if isPlaying { pause() } else { play() }
    }

    func play() {
        saveState()
        startAudio()
    }

    func handleStartIntent(colorRaw: String, wavesIntensity: WavesIntensity, fade: Bool) {
        currentColor = NoiseColors(rawValue: colorRaw) ?? .white
        self.wavesIntensity = wavesIntensity
        if wavesIntensity != .off { audio.setWavesIntensity(wavesIntensity) }
        fadeEnabled = fade
        if fade {
            let timerSeconds = settings.timerSeconds()
            if timerSeconds > 0 { audio.fadeSeconds = Int(timerSeconds) }
        }
        startAudio()
    }

    private func startAudio() {
        audio.play(color: currentColor, wavesIntensity: wavesIntensity, fade: fadeEnabled)
        updateNowPlaying()
        startTickTimer()
        isPlaying = true
    }

    func pause() {
        stopTickTimer()
        audio.pause()
        isPlaying = false
    }

    func changeColor(_ color: NoiseColors) {
        guard currentColor != color else { return }
        currentColor = color
        audio.reset(color: color)
        if isPlaying { updateNowPlaying() }
    }

    func setWavesIntensity(_ intensity: WavesIntensity) {
        wavesIntensity = intensity
        audio.setWavesIntensity(intensity)
        settings.setWavesIntensity(intensity)
    }

    func setFade(_ enabled: Bool) {
        fadeEnabled = enabled
        let seconds = timerActive && timeLeftSecs > 0 ? Int(timeLeftSecs) : 600
        audio.setFade(enabled, seconds: seconds)
    }

    func setNightlight(_ enabled: Bool) {
        nightlightEnabled = enabled
        UIApplication.shared.isIdleTimerDisabled = enabled
        if enabled {
            nightlightElapsedSecs = 0
            nightlightBrightness = 1.0
            startNightlightTimer()
        } else {
            stopNightlightTimer()
            nightlightBrightness = 0.0
        }
    }

    private func startNightlightTimer() {
        stopNightlightTimer()
        nightlightTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.nightlightTick()
        }
    }

    private func stopNightlightTimer() {
        nightlightTimer?.invalidate()
        nightlightTimer = nil
    }

    private func nightlightTick() {
        nightlightElapsedSecs += 1
        nightlightBrightness = max(0.0, 1.0 - nightlightElapsedSecs / nightlightDuration)
        if nightlightBrightness == 0.0 { setNightlight(false) }
    }

    func setTimerPreset(_ preset: TimerPreset?) {
        selectedTimerPreset = preset
        guard let preset else {
            deactivateTimer()
            return
        }
        timerPickerSeconds = preset.seconds
        activateTimer()
    }

    func confirmCustomTimer() {
        guard let preset = TimerPreset.from(seconds: timerPickerSeconds) else { return }
        customPresetSeconds = timerPickerSeconds
        settings.setCustomPresetSeconds(timerPickerSeconds)
        setTimerPreset(preset)
    }

    func toggleTimer() {
        if timerDisplayed {
            setTimerPreset(nil)
        } else {
            setTimerPreset(TimerPreset.from(seconds: timerPickerSeconds))
        }
    }

    func setIntent(intent: PlayIntent) {
        let parser = IntentParser(intent: intent)
        if parser.playForIntentIfNeeded() {
            settings.setColor(parser.mapColor())
            settings.setTimer(parser.getMinutesFromIntent())
            settings.setFade(parser.getFadingEnabledFromIntent())
        }
        loadSavedState()
        play()
    }

    func handlePauseIntent() {
        pause()
    }

    private func activateTimer() {
        timerDisplayed = true
        timerActive = true
        timeLeftSecs = timerPickerSeconds
        if fadeEnabled { audio.fadeSeconds = Int(timeLeftSecs) }
        timerText = formattedTime(timeLeftSecs)
        if isPlaying {
            saveState()
            updateNowPlaying()
        }
    }

    private func deactivateTimer() {
        timerDisplayed = false
        timerActive = false
        timeLeftSecs = 0
        timerText = ""
        if isPlaying {
            saveState()
            updateNowPlaying()
        }
    }

    private func loadSavedState() {
        customPresetSeconds = settings.customPresetSeconds()
        currentColor = settings.color()
        wavesIntensity = settings.wavesIntensity()
        if wavesIntensity != .off { audio.setWavesIntensity(wavesIntensity) }
        fadeEnabled = settings.fadeEnabled()
        let savedSeconds = settings.timerSeconds()
        if savedSeconds > 0 {
            timerPickerSeconds = savedSeconds
            selectedTimerPreset = TimerPreset.from(seconds: savedSeconds)
            timerDisplayed = true
            timerActive = true
            timeLeftSecs = savedSeconds
            timerText = formattedTime(savedSeconds)
            if fadeEnabled { audio.fadeSeconds = Int(savedSeconds) }
        } else {
            selectedTimerPreset = nil
            timerDisplayed = false
            timerActive = false
            timeLeftSecs = 0
            timerText = ""
        }
    }

    private func saveState() {
        settings.setColor(currentColor)
        settings.setFade(fadeEnabled)
        settings.setTimer(timerActive && timeLeftSecs > 0 ? timeLeftSecs : nil)
    }

    private func startTickTimer() {
        stopTickTimer()
        tickTimer = Timer.scheduledTimer(withTimeInterval: AudioManager.tickInterval, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    private func stopTickTimer() {
        tickTimer?.invalidate()
        tickTimer = nil
    }

    func tick() {
        guard timerActive else { return }
        if Int(timeLeftSecs) != 0 {
            timeLeftSecs -= AudioManager.tickInterval
            let nowSec = Int(timeLeftSecs)
            if nowSec != prevTime {
                prevTime = nowSec
                timerText = formattedTime(timeLeftSecs)
            }
        } else {
            timerText = ""
            timerDisplayed = false
            timerActive = false
            selectedTimerPreset = nil
            pause()
        }
    }

    private func setupRemoteCommandCenter() {
        UIApplication.shared.beginReceivingRemoteControlEvents()
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.pause()
            return .success
        }
        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.play()
            return .success
        }
    }

    private func setupForegroundObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: NSNotification.Name.UIApplicationWillEnterForeground,
            object: nil
        )
    }

    @objc func appWillEnterForeground() {
        if audio.isPlaying, !isPlaying {
            isPlaying = true
            startTickTimer()
        } else if !audio.isPlaying, isPlaying {
            isPlaying = false
            stopTickTimer()
        }
        guard audio.isPlaying else { return }
        currentColor = settings.color()
        wavesIntensity = settings.wavesIntensity()
        fadeEnabled = settings.fadeEnabled()
        let savedSeconds = settings.timerSeconds()
        if savedSeconds == 0 {
            if timerActive {
                timerActive = false
                timerDisplayed = false
                timeLeftSecs = 0
                timerText = ""
                selectedTimerPreset = nil
            }
        } else if !timerActive || savedSeconds != timerPickerSeconds {
            timerPickerSeconds = savedSeconds
            timerActive = true
            timerDisplayed = true
            timeLeftSecs = savedSeconds
            selectedTimerPreset = TimerPreset.from(seconds: savedSeconds)
            timerText = formattedTime(savedSeconds)
            if fadeEnabled { audio.fadeSeconds = Int(savedSeconds) }
        }
    }

    private func updateNowPlaying() {
        let title = switch currentColor {
        case .brown: "Brown Noise"
        case .pink: "Pink Noise"
        default: "White Noise"
        }
        guard let image = UIImage(named: "darkIcon") else { return }
        let artwork = MPMediaItemArtwork(boundsSize: image.size, requestHandler: { _ in image })
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: title,
            MPMediaItemPropertyArtwork: artwork,
        ]
        if timerActive, timeLeftSecs > 0 {
            info[MPMediaItemPropertyPlaybackDuration] = timerPickerSeconds
            info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = timerPickerSeconds - timeLeftSecs
            info[MPNowPlayingInfoPropertyPlaybackRate] = 1.0
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    private func formattedTime(_ seconds: Double) -> String {
        let total = Int(seconds)
        let hours = total / 3600
        let minutes = total / 60 % 60
        let secs = total % 60
        return hours > 0
            ? String(format: "%02i:%02i:%02i", hours, minutes, secs)
            : String(format: "%02i:%02i", minutes, secs)
    }
}
