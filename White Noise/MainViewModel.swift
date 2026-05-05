import MediaPlayer
import Observation
import SwiftUI
import UIKit

@Observable
final class MainViewModel {
    var isPlaying = false
    var currentColor: NoiseColors = .white
    var wavesEnabled = false
    var fadeEnabled = false
    var timerPickerSeconds: Double = 600
    var timerDisplayed = false
    var timerText = ""
    var colorScheme: ColorScheme?

    private var timerActive = false
    private var timeLeftSecs: Double = 0
    private var prevTime = 0
    private var tickTimer: Timer?

    private let audio: PlaybackService
    private let settings: SettingsSource

    init(audio: PlaybackService = AudioManager.shared, settings: SettingsSource = SettingsSource()) {
        self.audio = audio
        self.settings = settings
        colorScheme = Themer().getColorScheme()
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
    }

    func reloadTheme() {
        colorScheme = Themer().getColorScheme()
    }

    func playPause() {
        if isPlaying { pause() } else { play() }
    }

    func play() {
        saveState()
        startAudio()
    }

    func handleStartIntent(colorRaw: String, waves: Bool, fade: Bool) {
        currentColor = NoiseColors(rawValue: colorRaw) ?? .white
        wavesEnabled = waves
        fadeEnabled = fade
        if fade {
            let timerSeconds = settings.timerSeconds()
            if timerSeconds > 0 { audio.fadeSeconds = Int(timerSeconds) }
        }
        startAudio()
    }

    private func startAudio() {
        audio.play(color: currentColor, waves: wavesEnabled, fade: fadeEnabled)
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

    func setWaves(_ enabled: Bool) {
        wavesEnabled = enabled
        audio.setWaves(enabled)
    }

    func setFade(_ enabled: Bool) {
        fadeEnabled = enabled
        let seconds = timerActive && timeLeftSecs > 0 ? Int(timeLeftSecs) : 600
        audio.setFade(enabled, seconds: seconds)
    }

    func toggleTimer() {
        timerDisplayed = !timerDisplayed
        if timerDisplayed {
            timerActive = true
            timeLeftSecs = timerPickerSeconds
            if fadeEnabled { audio.fadeSeconds = Int(timeLeftSecs) }
            timerText = formattedTime(timeLeftSecs)
        } else {
            timerActive = false
            timeLeftSecs = 0
            timerText = ""
        }
        if isPlaying {
            saveState()
            updateNowPlaying()
        }
    }

    func setIntent(intent: PlayIntent) {
        let parser = IntentParser(intent: intent)
        if parser.playForIntentIfNeeded() {
            settings.setColor(parser.mapColor())
            settings.setTimer(parser.getMinutesFromIntent())
            settings.setWaves(parser.getWavesEnabledFromIntent())
            settings.setFade(parser.getFadingEnabledFromIntent())
        }
        loadSavedState()
        play()
    }

    func handlePauseIntent() {
        pause()
    }

    private func loadSavedState() {
        currentColor = settings.color()
        wavesEnabled = settings.wavesEnabled()
        fadeEnabled = settings.fadeEnabled()
        let savedSeconds = settings.timerSeconds()
        if savedSeconds > 0 {
            timerPickerSeconds = savedSeconds
            timerDisplayed = true
            timerActive = true
            timeLeftSecs = savedSeconds
            timerText = formattedTime(savedSeconds)
            if fadeEnabled { audio.fadeSeconds = Int(savedSeconds) }
        } else {
            timerDisplayed = false
            timerActive = false
            timeLeftSecs = 0
            timerText = ""
        }
    }

    private func saveState() {
        settings.setColor(currentColor)
        settings.setWaves(wavesEnabled)
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
        wavesEnabled = settings.wavesEnabled()
        fadeEnabled = settings.fadeEnabled()
        let savedSeconds = settings.timerSeconds()
        if savedSeconds == 0 {
            if timerActive {
                timerActive = false
                timerDisplayed = false
                timeLeftSecs = 0
                timerText = ""
            }
        } else if !timerActive || savedSeconds != timerPickerSeconds {
            timerPickerSeconds = savedSeconds
            timerActive = true
            timerDisplayed = true
            timeLeftSecs = savedSeconds
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
        if timerActive && timeLeftSecs > 0 {
            info[MPMediaItemPropertyPlaybackDuration] = timerPickerSeconds
            info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = timerPickerSeconds - timeLeftSecs
            info[MPNowPlayingInfoPropertyPlaybackRate] = 1.0
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    private func formattedTime(_ seconds: Double) -> String {
        let total = Int(seconds)
        let h = total / 3600
        let m = total / 60 % 60
        let s = total % 60
        return h > 0
            ? String(format: "%02i:%02i:%02i", h, m, s)
            : String(format: "%02i:%02i", m, s)
    }
}
