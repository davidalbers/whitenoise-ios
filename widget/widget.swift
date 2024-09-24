
import WidgetKit
import SwiftUI

struct Provider: IntentTimelineProvider {
    let grey = Color(UIColor(named: "widgetGrey") ?? UIColor.black)
    let pink = Color(UIColor(named: "widgetPink") ?? UIColor.systemPink)
    let brown = Color(UIColor(named: "widgetBrown") ?? UIColor.brown)
    
    func getSnapshot(for configuration: PlayIntent, in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        completion(intentToEntry(configuration))
    }
    
    func getTimeline(for configuration: PlayIntent, in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        let timeline = Timeline(entries: Array.init(arrayLiteral: intentToEntry(configuration)), policy: .never)
        completion(timeline)
    }
    
    typealias Entry = SimpleEntry
    
    typealias Intent = PlayIntent
    
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), displayString: "Rainbow", color: grey, colorScheme: .dark)
    }
        
    private func intentToEntry(_ intent: PlayIntent) -> SimpleEntry {
        let intentParser = IntentParser(intent: intent)

        var colorString = intentParser.mapColor()
        var waves = intentParser.getWavesEnabledFromIntent()
        var fade = intentParser.getFadingEnabledFromIntent()
        var minutes = (intentParser.getMinutesFromIntent() ?? 0.0) / 60.0
        if (!intentParser.playForIntentIfNeeded()) {
            colorString = SettingsSource().color()
            waves = SettingsSource().wavesEnabled()
            fade = SettingsSource().fadeEnabled()
            minutes = SettingsSource().timerSeconds() / 60.0
        }
        let hours = Int(minutes) / 60
        let mins = Int(minutes) % 60
        var timeString = ""
        if hours > 0 && mins > 0 {
            timeString = " for \(hours)h \(mins)m"
        } else if hours > 0 {
            timeString = " for \(hours)h"
        } else if (mins > 0) {
            timeString = " for \(mins)m"
        }
        
        var mod = ""
        if waves && fade {
            mod += "wavy and fading "
        } else if waves {
            mod += "wavy "
        } else if fade {
            mod += "fading "
        }
        
        var backgroundColor = grey
        
        switch colorString {
        case .Pink:
            backgroundColor = pink
        case .Brown:
            backgroundColor = brown
        default:
            backgroundColor = grey
        }
        
        mod += "\(colorString.rawValue) noise\(timeString)"
        let colorScheme = Themer().getWidgetColorScheme()
        return SimpleEntry(
            date: Date(),
            displayString: mod.capitalizingFirstLetter(),
            color: backgroundColor,
            colorScheme: colorScheme
        )
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let displayString: String
    let color: Color
    let colorScheme: ColorScheme?
}

struct RootWidget : View {
    @Environment(\.widgetFamily) var family
    var entry: Provider.Entry
    var body: some View {
        switch family {
        case .accessoryRectangular:
            PlayWidget(entry: entry)
        case .accessoryCircular:
            IconWidget(entry: entry)
        case .systemLarge, .systemMedium, .systemSmall:
            FullSizeWidget(entry: entry)
        default:
            Text("Unknown widget family")
        }
    }
}

struct PlayWidget: View {
    var entry: Provider.Entry

    var body: some View {
        HStack {
            Image(systemName: "play.fill")
                .resizable()
                .frame(width: 16, height: 16)
            Text(entry.displayString)
                .font(.system(size: 16))
                .foregroundColor(Color.white)
        }.frame(
            minWidth: 0,
            maxWidth: .infinity,
            minHeight: 0,
            maxHeight: .infinity,
            alignment: .center
        )
        .widgetBackground(Color.white.opacity(0.20))
        .cornerRadius(16)
    }
}

struct IconWidget: View {
    var entry: Provider.Entry

    var body: some View {
        Image("iconHighRes")
            .resizable()
            .frame(
                minWidth: 0,
                maxWidth: .infinity,
                minHeight: 0,
                maxHeight: .infinity,
                alignment: .center
            )
            .widgetBackground(Color.white)
    }
}

struct FullSizeWidget : View {
    var entry: Provider.Entry
    let padding: CGFloat = 14

    
    var body: some View {
        VStack {
            HStack (alignment: .top) {
                Image("play")
                    .resizable()
                    .frame(width: 48.0, height: 48.0)
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
                .foregroundColor(Color.white)
        }.frame(
            minHeight: 0,
            maxHeight: .infinity,
            alignment: .topLeading
        )
        .widgetBackground(entry.color)
        .colorScheme(entry.colorScheme)
    }
}


@main
struct WhiteNoiseWidget: Widget {
    let kind: String = "widget"
    var body: some WidgetConfiguration {
        var families = [WidgetFamily.systemSmall, WidgetFamily.systemMedium, WidgetFamily.systemLarge]
        if #available(iOSApplicationExtension 16.0, *) {
            families.append(contentsOf: [WidgetFamily.accessoryRectangular, WidgetFamily.accessoryCircular])
        }
        return IntentConfiguration(
            kind: kind,
            intent: PlayIntent.self,
            provider: Provider()
        ) { entry in
            RootWidget(entry: entry)
        }
        .configurationDisplayName("Play")
        .supportedFamilies(families)
        .contentMarginsDisabled()
    }
}

extension String {
    func capitalizingFirstLetter() -> String {
      return prefix(1).uppercased() + self.lowercased().dropFirst()
    }

    mutating func capitalizeFirstLetter() {
      self = self.capitalizingFirstLetter()
    }
}

extension View {
    // Handle a new required API
    // https://nemecek.be/blog/192/hotfixing-widgets-for-ios-17-containerbackground-padding
    func widgetBackground(_ backgroundView: some View) -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            return containerBackground(for: .widget) {
                backgroundView
            }
        } else {
            return background(backgroundView)
        }
    }
}
