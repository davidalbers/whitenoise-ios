
import WidgetKit
import SwiftUI

struct Provider: IntentTimelineProvider {
    func getSnapshot(for configuration: PlayIntent, in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        let entry = SimpleEntry(date: Date(), color: "snapshot")
        completion(entry)
    }
    
    func getTimeline(for configuration: PlayIntent, in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        let currentDate = Date()
        let entry = SimpleEntry(date: currentDate, color: "timeline")

        let timeline = Timeline(entries: Array.init(arrayLiteral: entry), policy: .never)
        completion(timeline)
    }
    
    typealias Entry = SimpleEntry
    
    typealias Intent = PlayIntent
    
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), color: "placeholder")
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let color: String
}

struct widgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        Text(entry.color)
    }
}

@main
struct widget: Widget {
    let kind: String = "widget"
    var body: some WidgetConfiguration {
        return IntentConfiguration(
            kind: kind,
            intent: PlayIntent.self,
            provider: Provider()
        ) { entry in
            widgetEntryView(entry: entry)
        }
        .configurationDisplayName("Play")
    }
}
