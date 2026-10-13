import SwiftUI
import WidgetKit

struct DayEntry: TimelineEntry {
  let date: Date
  let snapshot: WidgetSnapshot?
}

/// One entry now + one per midnight for the next 7 days: the count ticks over
/// at 0:00 without the app running. `.atEnd` asks WidgetKit for 7 more then.
struct DayProvider: TimelineProvider {
  func placeholder(in context: Context) -> DayEntry {
    DayEntry(date: Date(), snapshot: .preview)
  }

  func getSnapshot(in context: Context, completion: @escaping (DayEntry) -> Void) {
    completion(DayEntry(date: Date(), snapshot: context.isPreview ? .preview : WidgetSnapshot.load()))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<DayEntry>) -> Void) {
    let snapshot = WidgetSnapshot.load()
    let calendar = Calendar.current
    var entries = [DayEntry(date: Date(), snapshot: snapshot)]
    var day = calendar.startOfDay(for: Date())
    for _ in 0..<7 {
      guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
      day = next
      entries.append(DayEntry(date: day, snapshot: snapshot))
    }
    completion(Timeline(entries: entries, policy: .atEnd))
  }
}

@main
struct DayCounterWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "DayCounter", provider: DayProvider()) { entry in
      DayCounterView(entry: entry)
    }
    .configurationDisplayName(LocalizedStringKey("widget_display_name"))
    .description(LocalizedStringKey("widget_description"))
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}
