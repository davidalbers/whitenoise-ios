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
        case .pink:  return .Pink
        case .brown: return .Brown
        case .white: return .White
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

    @Parameter(title: "Wavy Volume", default: false)
    var waves: Bool

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
                \.$waves
                \.$fade
                \.$timerMinutes
            }
        }
    }

    func perform() async throws -> some IntentResult { .result() }
}

struct StartPlayingIntent: AudioPlaybackIntent {
    static var title: LocalizedStringResource = "Start White Noise"
    static var playHandler: ((_ color: String, _ waves: Bool, _ fade: Bool) -> Void)?

    @Parameter(title: "Mirror App") var mirrorApp: Bool
    @Parameter(title: "Color") var color: WidgetNoiseColor
    @Parameter(title: "Waves") var waves: Bool
    @Parameter(title: "Fade")  var fade: Bool
    @Parameter(title: "Timer (minutes)", inclusiveRange: (1, 1440)) var timerMinutes: Int?

    init() {
        self.mirrorApp = true
        self.color = .white
        self.waves = false
        self.fade  = false
        self.timerMinutes = nil
    }

    init(config: PlayWidgetIntent) {
        self.mirrorApp = config.mirrorApp
        self.color = config.color
        self.waves = config.waves
        self.fade  = config.fade
        self.timerMinutes = config.timerMinutes
    }

    func perform() async throws -> some IntentResult {
        let colorRaw: String
        let wavesVal: Bool
        let fadeVal: Bool

        if mirrorApp {
            let settings = SettingsSource()
            colorRaw = settings.color().rawValue
            wavesVal = settings.wavesEnabled()
            fadeVal  = settings.fadeEnabled()
        } else {
            let defaults = UserDefaults(suiteName: "group.com.dalbers.WhiteNoise")!
            defaults.set(color.rawValue, forKey: "colorKey")
            defaults.set(waves,          forKey: "wavesKey")
            defaults.set(fade,           forKey: "fadeKey")
            if let mins = timerMinutes, mins > 0 {
                defaults.set(Double(mins) * 60.0, forKey: "timerKey")
            } else {
                defaults.removeObject(forKey: "timerKey")
            }
            colorRaw = color.rawValue
            wavesVal = waves
            fadeVal  = fade
        }

        await MainActor.run {
            Self.playHandler?(colorRaw, wavesVal, fadeVal)
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
