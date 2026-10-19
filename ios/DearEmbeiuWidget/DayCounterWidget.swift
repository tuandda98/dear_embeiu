import SwiftUI
import WidgetKit

struct DayEntry: TimelineEntry {
  let date: Date
  let snapshot: WidgetSnapshot?
  /// Today's line for THIS entry's day only (nil in the gallery preview).
  var status: WidgetStatus? = nil
}

/// One entry now + one per midnight for the next 7 days: the count ticks over
/// at 0:00 without the app running. `.atEnd` asks WidgetKit for 7 more then.
struct DayProvider: TimelineProvider {
  func placeholder(in context: Context) -> DayEntry {
    DayEntry(date: Date(), snapshot: .preview)
  }

  func getSnapshot(in context: Context, completion: @escaping (DayEntry) -> Void) {
    if context.isPreview {
      completion(DayEntry(date: Date(), snapshot: .preview))
      return
    }
    let snapshot = WidgetSnapshot.load()
    completion(DayEntry(date: Date(), snapshot: snapshot, status: Self.status(snapshot, WidgetStatus.load(), Date())))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<DayEntry>) -> Void) {
    let snapshot = WidgetSnapshot.load()
    let status = WidgetStatus.load()
    let calendar = Calendar.current
    var entries = [DayEntry(date: Date(), snapshot: snapshot, status: Self.status(snapshot, status, Date()))]
    var day = calendar.startOfDay(for: Date())
    for _ in 0..<7 {
      guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
      day = next
      entries.append(DayEntry(date: day, snapshot: snapshot, status: Self.status(snapshot, status, day)))
    }
    completion(Timeline(entries: entries, policy: .atEnd))
  }

  /// A line only on the counter, and only on its own day (widget-today D4.1).
  private static func status(_ snapshot: WidgetSnapshot?, _ status: WidgetStatus?, _ day: Date) -> WidgetStatus? {
    (snapshot?.isCounter ?? false) ? status?.shown(on: day) : nil
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
