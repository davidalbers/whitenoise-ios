import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Timeline provider

struct Provider: AppIntentTimelineProvider {
    let grey  = Color(UIColor(named: "widgetGrey")  ?? UIColor.black)
    let pink  = Color(UIColor(named: "widgetPink")  ?? UIColor.systemPink)
    let brown = Color(UIColor(named: "widgetBrown") ?? UIColor.brown)

    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(
            date: Date(),
            displayString: "White noise",
            color: grey,
            colorScheme: .dark,
            isPlaying: false,
            startIntent: StartPlayingIntent(),
            stopIntent: StopPlayingIntent()
        )
    }

    func snapshot(for configuration: PlayWidgetIntent, in context: Context) async -> SimpleEntry {
        intentToEntry(configuration)
    }

    func timeline(for configuration: PlayWidgetIntent, in context: Context) async -> Timeline<SimpleEntry> {
        Timeline(entries: [intentToEntry(configuration)], policy: .never)
    }

    private func intentToEntry(_ intent: PlayWidgetIntent) -> SimpleEntry {
        let color: WidgetNoiseColor
        let waves: Bool
        let fade: Bool
        let timerMinutes: Int?

        if intent.mirrorApp {
            let settings = SettingsSource()
            color = WidgetNoiseColor(rawValue: settings.color().rawValue) ?? .white
            waves = settings.wavesEnabled()
            fade  = settings.fadeEnabled()
            timerMinutes = nil
        } else {
            color = intent.color
            waves = intent.waves
            fade  = intent.fade
            timerMinutes = intent.timerMinutes
        }

        var backgroundColor = grey
        switch color {
        case .pink:  backgroundColor = pink
        case .brown: backgroundColor = brown
        case .white: backgroundColor = grey
        }

        var mod = ""
        if waves && fade {
            mod += "wavy and fading "
        } else if waves {
            mod += "wavy "
        } else if fade {
            mod += "fading "
        }
        mod += "\(color.rawValue) noise"

        if let mins = timerMinutes, mins > 0 {
            mod += " for \(formatMinutes(mins))"
        }

        let isPlaying = UserDefaults(suiteName: "group.com.dalbers.WhiteNoise")?.bool(forKey: "isPlayingKey") ?? false

        return SimpleEntry(
            date: Date(),
            displayString: mod.capitalizingFirstLetter(),
            color: backgroundColor,
            colorScheme: Themer().getWidgetColorScheme(),
            isPlaying: isPlaying,
            startIntent: StartPlayingIntent(config: intent),
            stopIntent: StopPlayingIntent()
        )
    }
}

// MARK: - Entry

struct SimpleEntry: TimelineEntry {
    let date: Date
    let displayString: String
    let color: Color
    let colorScheme: ColorScheme?
    let isPlaying: Bool
    let startIntent: StartPlayingIntent
    let stopIntent: StopPlayingIntent
}

// MARK: - Root view

struct RootWidget: View {
    @Environment(\.widgetFamily) var family
    var entry: Provider.Entry

    var body: some View {
        switch family {
        case .accessoryRectangular:
            PlayWidget(entry: entry)
        case .accessoryCircular:
            IconWidget(entry: entry)
        default:
            FullSizeWidget(entry: entry)
        }
    }
}

// MARK: - Lock-screen rectangular widget

struct PlayWidget: View {
    var entry: Provider.Entry

    var body: some View {
        Group {
            if entry.isPlaying {
                Button(intent: entry.stopIntent) {
                    HStack {
                        Image(systemName: "pause.fill")
                            .resizable()
                            .frame(width: 16, height: 16)
                        Text(entry.displayString)
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                    }
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .center)
                }
                .buttonStyle(.plain)
            } else {
                Button(intent: entry.startIntent) {
                    HStack {
                        Image(systemName: "play.fill")
                            .resizable()
                            .frame(width: 16, height: 16)
                        Text(entry.displayString)
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                    }
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .center)
                }
                .buttonStyle(.plain)
            }
        }
        .widgetBackground(Color.white.opacity(0.20))
        .cornerRadius(16)
    }
}

// MARK: - Lock-screen circular widget (interactive buttons not supported here)

struct IconWidget: View {
    var entry: Provider.Entry

    var body: some View {
        Image("iconHighRes")
            .resizable()
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .center)
            .widgetBackground(Color.white)
    }
}

// MARK: - Home-screen widget (small / medium / large)

struct FullSizeWidget: View {
    var entry: Provider.Entry
    let padding: CGFloat = 14

    var body: some View {
        VStack {
            HStack(alignment: .top) {
                Group {
                    if entry.isPlaying {
                        Button(intent: entry.stopIntent) {
                            Image("pause")
                                .resizable()
                                .frame(width: 48.0, height: 48.0)
                        }
                        .buttonStyle(.plain)
                    } else {
                        Button(intent: entry.startIntent) {
                            Image("play")
                                .resizable()
                                .frame(width: 48.0, height: 48.0)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top, padding)
                Spacer()
                Image("icon")
                    .resizable()
                    .frame(width: 24.0, height: 24.0)
                    .padding(.top, padding)
                    .padding(.trailing, padding)
            }
            Spacer()
            Text(entry.displayString)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                .padding(.leading, padding)
                .padding(.trailing, padding)
                .padding(.bottom, padding)
                .foregroundColor(.white)
        }
        .frame(minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
        .widgetBackground(entry.color)
        .colorScheme(entry.colorScheme)
    }
}

// MARK: - Widget declaration

@main
struct WhiteNoiseWidget: Widget {
    let kind: String = "widget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: PlayWidgetIntent.self,
            provider: Provider()
        ) { entry in
            RootWidget(entry: entry)
        }
        .configurationDisplayName("Play")
        .supportedFamilies([
            .systemSmall, .systemMedium, .systemLarge,
            .accessoryRectangular, .accessoryCircular,
        ])
        .contentMarginsDisabled()
    }
}

// MARK: - Helpers

private func formatMinutes(_ minutes: Int) -> String {
    if minutes < 60 { return "\(minutes)m" }
    let h = minutes / 60
    let m = minutes % 60
    return m == 0 ? "\(h)h" : "\(h)h \(m)m"
}

extension String {
    func capitalizingFirstLetter() -> String {
        prefix(1).uppercased() + self.lowercased().dropFirst()
    }
}

extension View {
    // https://nemecek.be/blog/192/hotfixing-widgets-for-ios-17-containerbackground-padding
    func widgetBackground(_ backgroundView: some View) -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            return containerBackground(for: .widget) { backgroundView }
        } else {
            return background(backgroundView)
        }
    }
}
