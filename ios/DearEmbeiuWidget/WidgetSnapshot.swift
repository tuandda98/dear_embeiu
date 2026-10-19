import Foundation
import UIKit

/// The map Flutter pushes over `dear_embeiu/widget` (key list:
/// lib/services/home_widget_snapshot.dart). The app stores it in the shared
/// App Group; the widget reads it at render time.
struct WidgetSnapshot {
  static let storeKey = "widget_snapshot"
  let raw: [String: String]

  subscript(_ key: String) -> String { raw[key] ?? "" }
  var isCounter: Bool { self["state"] == "counter" }
  var lang: String { self["lang"].isEmpty ? "vi" : self["lang"] }

  /// `AppGroupId` in Info.plist = `$(APP_GROUP_ID)` build setting, so the dev
  /// and prod apps never read each other's store.
  static var groupId: String? {
    Bundle.main.object(forInfoDictionaryKey: "AppGroupId") as? String
  }

  /// The CounterCard photo the app wrote via `setPhoto` (HomeWidgetChannel).
  static func loadPhoto() -> UIImage? {
    guard let group = groupId,
          let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: group)?
            .appendingPathComponent("widget_photo.png") else { return nil }
    return UIImage(contentsOfFile: url.path)
  }

  static func load() -> WidgetSnapshot? {
    guard let group = groupId,
          let defaults = UserDefaults(suiteName: group),
          let raw = defaults.dictionary(forKey: storeKey) as? [String: String] else { return nil }
    return WidgetSnapshot(raw: raw)
  }

  /// Widget gallery preview only — fixed 1247 days, strings from the
  /// extension's Localizable.strings (the one place native holds copy, D4).
  static var preview: WidgetSnapshot {
    func s(_ key: String) -> String { NSLocalizedString(key, comment: "") }
    let calendar = DayMath.gregorian // the snapshot date is Gregorian (Dart parity)
    let start = calendar.date(byAdding: .day, value: -1247, to: Date()) ?? Date()
    let c = calendar.dateComponents([.year, .month, .day], from: start)
    let anniversary = String(format: "%04d-%02d-%02d", c.year ?? 2023, c.month ?? 5, c.day ?? 14)
    return WidgetSnapshot(raw: [
      "state": "counter", "lang": s("preview_lang"), "anniversary": anniversary,
      "name1": s("preview_name1"), "name2": s("preview_name2"),
      "daysLabel": s("preview_days_label"), "milestoneFmt": s("preview_milestone_fmt"),
      "daysLeftOne": s("preview_days_left_one"), "daysLeftFmt": s("preview_days_left_fmt"),
      "todayLabel": "", "monthsOne": "", "monthsFmt": "{count}", "yearsOne": "", "yearsFmt": "{count}",
      "daysFmt": s("preview_days_fmt"), "sinceText": s("preview_since"),
    ])
  }
}

/// The "hôm nay" line (feature widget-today, D6), stored apart from the
/// snapshot by HomeWidgetChannel `updateStatus`. Keys:
/// lib/services/home_widget_status.dart.
struct WidgetStatus {
  static let storeKey = "widget_status"
  let raw: [String: String]

  subscript(_ key: String) -> String { raw[key] ?? "" }
  /// Medium widget.
  var text: String { self["statusText"] }
  /// Small widget (D14); falls back to the full line.
  var shortText: String { self["statusTextShort"].isEmpty ? text : self["statusTextShort"] }

  static func load() -> WidgetStatus? {
    guard let group = WidgetSnapshot.groupId,
          let defaults = UserDefaults(suiteName: group),
          let raw = defaults.dictionary(forKey: storeKey) as? [String: String] else { return nil }
    return WidgetStatus(raw: raw)
  }

  /// Itself when it is the line of `day` and has text, else nil (D4.1): the
  /// timeline entry of 0:00 onwards therefore draws no line by itself.
  func shown(on day: Date) -> WidgetStatus? {
    self["todayDate"] == DayMath.dateKey(day) && !text.isEmpty ? self : nil
  }
}

/// Everything the view prints, computed once per timeline entry.
struct DayModel {
  let name1: String
  let name2: String
  let daysText: String
  let daysLabel: String
  let milestoneText: String
  let daysLeftText: String
  let sinceText: String
  let progress: Double

  init(snapshot s: WidgetSnapshot, today: Date) {
    let days = DayMath.daysTogether(anniversary: s["anniversary"], today: today)
    let next = DayMath.nextMilestone(days)
    let number = { (n: Int) in DayMath.format(n, lang: s.lang) }
    let label = DayMath.milestoneLabel(next, monthsOne: s["monthsOne"], monthsFmt: s["monthsFmt"],
                                       yearsOne: s["yearsOne"], yearsFmt: s["yearsFmt"],
                                       daysFmt: s["daysFmt"], number: number)
    let left = next - days
    name1 = s["name1"]
    name2 = s["name2"]
    daysText = number(days)
    daysLabel = s["daysLabel"]
    milestoneText = s["milestoneFmt"].replacingOccurrences(of: "{label}", with: label)
    daysLeftText = left <= 0 ? s["todayLabel"]
      : left == 1 ? s["daysLeftOne"]
      : s["daysLeftFmt"].replacingOccurrences(of: "{count}", with: number(left))
    sinceText = s["sinceText"]
    progress = DayMath.progress(days: days, next: next)
  }
}
