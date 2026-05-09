import AVFoundation
import WidgetKit

class AudioManager {
    static let shared = AudioManager()

    private var player: AVAudioPlayer?
    private var crossfadeStartTime: Date?

    private var wavesIntensity = WavesIntensity.off
    private var fadingOut = false
    private var playPauseFading = false
    private var pendingFade: DispatchWorkItem?

    private var currentColor: NoiseColors?
    private var volumeTimer: Timer?

    private(set) var fadeEnabled = false
    private var volume: Float = 1.0
    private var maxVolume: Float = 1.0
    private var minVolume: Float = 0.2
    private var increasing = false
    var fadeSeconds: Int = 600

    private static let isPlayingKey = "isPlayingKey"
    private static let sharedDefaults = UserDefaults(suiteName: "group.com.dalbers.WhiteNoise")

    static let tickInterval: Double = 0.03
    static let crossfadeDuration: Double = 0.8
    private static let playPauseFadeDuration: Double = 1.0
    private let waveIncrement: Float = .init(AudioManager.tickInterval / 5)

    var isPlaying: Bool {
        !fadingOut && (player?.isPlaying ?? false)
    }

    private init() {}

    func play(color: NoiseColors, wavesIntensity _: WavesIntensity, fade: Bool) {
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {}

        if currentColor != color || player == nil {
            loadPlayer(color: color)
        }
        fadeEnabled = fade
        maxVolume = 1.0
        volume = maxVolume
        increasing = false

        fadingOut = false
        scheduleFade {
            self.playPauseFading = false
            self.player?.volume = self.volume
        }
        if !(player?.isPlaying ?? false) {
            player?.volume = 0
            player?.play()
        }
        player?.setVolume(1, fadeDuration: Self.playPauseFadeDuration)

        startVolumeTimer()
        Self.sharedDefaults?.set(true, forKey: Self.isPlayingKey)
        WidgetCenter.shared.reloadAllTimelines()
    }

    func pause() {
        guard player?.isPlaying == true else { return }
        fadingOut = true
        scheduleFade {
            guard self.fadingOut else { return }
            self.completePause()
        }
        player?.setVolume(0, fadeDuration: Self.playPauseFadeDuration)
        Self.sharedDefaults?.set(false, forKey: Self.isPlayingKey)
        WidgetCenter.shared.reloadAllTimelines()
    }

    func setWavesIntensity(_ intensity: WavesIntensity) {
        wavesIntensity = intensity
        if let vol = intensity.minVolume { minVolume = vol }
    }

    func setFade(_ enabled: Bool, seconds: Int) {
        fadeEnabled = enabled
        if enabled {
            fadeSeconds = seconds
        } else {
            maxVolume = 1.0
        }
    }

    func reset(color: NoiseColors) {
        guard isPlaying else { return }
        pendingFade?.cancel()
        pendingFade = nil
        playPauseFading = false
        fadingOut = false

        let outgoing = player
        outgoing?.setVolume(0, fadeDuration: Self.crossfadeDuration)
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.crossfadeDuration) {
            outgoing?.stop()
        }
        loadPlayer(color: color)
        player?.volume = 0
        player?.play()
        crossfadeStartTime = Date()
    }

    private func scheduleFade(completion: @escaping () -> Void) {
        pendingFade?.cancel()
        playPauseFading = true
        let work = DispatchWorkItem {
            completion()
            self.pendingFade = nil
        }
        pendingFade = work
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.playPauseFadeDuration, execute: work)
    }

    private func completePause() {
        stopVolumeTimer()
        player?.pause()
        fadingOut = false
        playPauseFading = false
        maxVolume = 1.0
        volume = maxVolume
        try? AVAudioSession.sharedInstance().setActive(false)
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
        if fadeEnabled { applyFade() }
        if playPauseFading { return }
        if wavesIntensity != .off { applyWave() }

        let crossfadeProgress: Float = crossfadeStartTime.map { start in
            let progress = min(
                Float(Date().timeIntervalSince(start)) / Float(Self.crossfadeDuration),
                1
            )
            if progress >= 1 { crossfadeStartTime = nil }
            return progress
        } ?? 1

        player?.volume = volume * crossfadeProgress
    }

    private func applyWave() {
        if increasing { volume += waveIncrement } else { volume -= waveIncrement }
        if volume <= minVolume {
            volume = minVolume
            increasing = true
        } else if volume >= maxVolume {
            increasing = false
            volume = maxVolume
        }
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

extension AudioManager: PlaybackService {}
