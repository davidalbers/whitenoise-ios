import AVFoundation
import WidgetKit

class AudioManager {
    static let shared = AudioManager()

    private var player: AVAudioPlayer?
    private var currentColor: NoiseColors?
    private var volumeTimer: Timer?

    private(set) var wavesEnabled: Bool = false
    private(set) var fadeEnabled: Bool = false
    private var volume: Float = 1.0
    private var maxVolume: Float = 1.0
    private let minVolume: Float = 0.2
    private var increasing: Bool = false
    var fadeSeconds: Int = 600

    private static let isPlayingKey = "isPlayingKey"
    private static let sharedDefaults = UserDefaults(suiteName: "group.com.dalbers.WhiteNoise")

    private static let tickInterval: Double = MainPresenter.tickInterval
    private let waveIncrement: Float = Float(MainPresenter.tickInterval / 5)

    var isPlaying: Bool { player?.isPlaying ?? false }

    private init() {}

    func play(color: NoiseColors, waves: Bool, fade: Bool) {
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {}

        if currentColor != color || player == nil {
            loadPlayer(color: color)
        }
        wavesEnabled = waves
        fadeEnabled = fade
        maxVolume = 1.0
        volume = maxVolume
        increasing = false
        player?.volume = volume
        player?.play()
        startVolumeTimer()
        Self.sharedDefaults?.set(true, forKey: Self.isPlayingKey)
        WidgetCenter.shared.reloadAllTimelines()
    }

    func pause() {
        stopVolumeTimer()
        player?.pause()
        maxVolume = 1.0
        volume = maxVolume
        try? AVAudioSession.sharedInstance().setActive(false)
        Self.sharedDefaults?.set(false, forKey: Self.isPlayingKey)
        WidgetCenter.shared.reloadAllTimelines()
    }

    func setWaves(_ enabled: Bool) {
        wavesEnabled = enabled
        if !enabled { volume = maxVolume }
    }

    func setFade(_ enabled: Bool, seconds: Int) {
        fadeEnabled = enabled
        if enabled { fadeSeconds = seconds }
        else { maxVolume = 1.0 }
    }

    func reset(color: NoiseColors, restart: Bool) {
        if currentColor == color {
            if !restart { pause() }
            return
        }
        stopVolumeTimer()
        player?.pause()
        loadPlayer(color: color)
        if restart {
            maxVolume = 1.0
            volume = maxVolume
            increasing = false
            player?.volume = volume
            player?.play()
            startVolumeTimer()
        }
    }

    private func startVolumeTimer() {
        stopVolumeTimer()
        volumeTimer = Timer.scheduledTimer(
            withTimeInterval: Self.tickInterval,
            repeats: true
        ) { [weak self] _ in self?.tick() }
    }

    private func stopVolumeTimer() {
        volumeTimer?.invalidate()
        volumeTimer = nil
    }

    private func tick() {
        if fadeEnabled  { applyFade() }
        if wavesEnabled { applyWave() }
        player?.volume = volume
    }

    private func applyWave() {
        if increasing { volume += waveIncrement } else { volume -= waveIncrement }
        if volume <= minVolume { volume = minVolume; increasing = true }
        else if volume >= maxVolume { increasing = false; volume = maxVolume }
    }

    private func applyFade() {
        let totalTicks = Float(fadeSeconds) / Float(Self.tickInterval)
        let delta = (1.0 - minVolume) / totalTicks
        if maxVolume > minVolume {
            maxVolume -= delta
            if volume > maxVolume { volume = maxVolume }
        }
    }

    private func loadPlayer(color: NoiseColors) {
        guard let url = Bundle.main.url(forResource: color.rawValue, withExtension: "mp3") else { return }
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.numberOfLoops = -1
            currentColor = color
        } catch {}
    }
}
