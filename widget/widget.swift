
import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), color: "placeholder")
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), color: "snapshot")
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let currentDate = Date()
        let entry = SimpleEntry(date: currentDate, color: "timeline")

        let timeline = Timeline(entries: Array.init(arrayLiteral: entry), policy: .never)
        completion(timeline)
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
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            widgetEntryView(entry: entry)
        }
        .configurationDisplayName("My Widget")
        .description("This is an example widget.")
//
    
//        IntentConfiguration(
//            kind: kind,
//            intent: PlayIntent.self,
//            provider: Provider(),
//            placeholder: Provider()
//        ) { entry in
//            widgetEntryView(entry: entry)
//        }
//        .configurationDisplayName("A Repo's Latest Commit")
//        .description("Shows the last commit at the a repo/branch combination.")
    }
}

struct widget_Previews: PreviewProvider {
    static var previews: some View {
        widgetEntryView(entry: SimpleEntry(date: Date(), color: "previews"))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
