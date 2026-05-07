import AppIntents
import WidgetKit


enum WidgetNoiseColor: String, AppEnum {
    case white, pink, brown

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Noise Color")
    static var caseDisplayRepresentations: [WidgetNoiseColor: DisplayRepresentation] = [
        .white: "White",
        .pink: "Pink",
        .brown: "Brown",
    ]

    func toNoiseColor() -> NoiseColors {
        switch self {
        case .pink:  return .pink
        case .brown: return .brown
        case .white: return .white
        }
    }
}

struct PlayWidgetIntent: AppIntent, WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Play White Noise"
    static var description = IntentDescription("Configure what white noise to play.")

    @Parameter(title: "Mirror App", default: true)
    var mirrorApp: Bool

    @Parameter(title: "Noise Color", default: .white)
    var color: WidgetNoiseColor

    @Parameter(title: "Waves", default: .off)
    var wavesIntensity: WavesIntensity

    @Parameter(title: "Fading Volume", default: false)
    var fade: Bool

    @Parameter(title: "Timer (minutes)", inclusiveRange: (1, 1440))
    var timerMinutes: Int?

    static var parameterSummary: some ParameterSummary {
        When(\.$mirrorApp, .equalTo, true) {
            Summary("Mirror app settings") {
                \.$mirrorApp
            }
        } otherwise: {
            Summary("Play \(\.$color) noise") {
                \.$mirrorApp
                \.$wavesIntensity
                \.$fade
                \.$timerMinutes
            }
        }
    }

    func perform() async throws -> some IntentResult { .result() }
}

struct StartPlayingIntent: AudioPlaybackIntent {
    static var title: LocalizedStringResource = "Start White Noise"
    static var playHandler: ((_ color: String, _ wavesIntensity: WavesIntensity, _ fade: Bool) -> Void)?

    @Parameter(title: "Mirror App") var mirrorApp: Bool
    @Parameter(title: "Color") var color: WidgetNoiseColor
    @Parameter(title: "Waves") var wavesIntensity: WavesIntensity
    @Parameter(title: "Fade")  var fade: Bool
    @Parameter(title: "Timer (minutes)", inclusiveRange: (1, 1440)) var timerMinutes: Int?

    init() {
        self.mirrorApp = true
        self.color = .white
        self.wavesIntensity = .off
        self.fade  = false
        self.timerMinutes = nil
    }

    init(config: PlayWidgetIntent) {
        self.mirrorApp = config.mirrorApp
        self.color = config.color
        self.wavesIntensity = config.wavesIntensity
        self.fade  = config.fade
        self.timerMinutes = config.timerMinutes
    }

    func perform() async throws -> some IntentResult {
        let colorRaw: String
        let intensityVal: WavesIntensity
        let fadeVal: Bool

        if mirrorApp {
            let settings = SettingsSource()
            colorRaw     = settings.color().rawValue
            intensityVal = settings.wavesIntensity()
            fadeVal      = settings.fadeEnabled()
        } else {
            let defaults = UserDefaults(suiteName: "group.com.dalbers.WhiteNoise")!
            defaults.set(color.rawValue,           forKey: "colorKey")
            defaults.set(wavesIntensity.rawValue,   forKey: "wavesIntensityKey")
            defaults.set(wavesIntensity != .off,    forKey: "wavesKey")
            defaults.set(fade,                      forKey: "fadeKey")
            if let mins = timerMinutes, mins > 0 {
                defaults.set(Double(mins) * 60.0, forKey: "timerKey")
            } else {
                defaults.removeObject(forKey: "timerKey")
            }
            colorRaw     = color.rawValue
            intensityVal = wavesIntensity
            fadeVal      = fade
        }

        await MainActor.run {
            Self.playHandler?(colorRaw, intensityVal, fadeVal)
        }

        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

struct StopPlayingIntent: AudioPlaybackIntent {
    static var title: LocalizedStringResource = "Stop White Noise"
    static var isDiscoverable: Bool = false
    static var stopHandler: (() -> Void)?

    func perform() async throws -> some IntentResult {
        await MainActor.run {
            Self.stopHandler?()
        }
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
