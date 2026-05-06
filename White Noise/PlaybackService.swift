import Foundation

protocol PlaybackService: AnyObject {
    var isPlaying: Bool { get }
    var fadeSeconds: Int { get set }
    func play(color: NoiseColors, waves: Bool, fade: Bool)
    func pause()
    func setWaves(_ enabled: Bool)
    func setWavesIntensity(_ intensity: WavesIntensity)
    func setFade(_ enabled: Bool, seconds: Int)
    func reset(color: NoiseColors)
}
