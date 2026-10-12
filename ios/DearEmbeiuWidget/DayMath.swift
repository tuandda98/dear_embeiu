import Foundation

/// Day count + next milestone for the home-screen widget. Mirrors Dart
/// (`LoveTreeService.daysTogether`, `_getNextMilestone` / `_milestoneLabel` in
/// home_screen.dart) and `DayMath.kt` on Android — change all three together or
/// the widget drifts from the Home counter. Foundation only: also compiled by
/// scripts/check-widget-daymath.sh outside Xcode.
enum DayMath {
  static let milestones = [30, 50, 100, 180, 365, 500, 730, 1000, 1500, 2000, 3000]

  /// `YYYY-MM-DD` (the snapshot's `anniversary`) → year/month/day.
  static func parseDate(_ s: String) -> DateComponents? {
    let parts = s.split(separator: "-").compactMap { Int($0) }
    guard parts.count == 3 else { return nil }
    return DateComponents(year: parts[0], month: parts[1], day: parts[2])
  }

  /// Dart counts in the Gregorian calendar (DateTime). `Calendar.current` follows
  /// the device setting and can be Buddhist/Japanese, which would read "2023"
  /// as another year — so default to Gregorian in the device's time zone.
  static var gregorian: Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = .current
    return calendar
  }

  /// Calendar days from the anniversary to `today` — midnight to midnight in
  /// `calendar`, so a DST change never costs a day. Never below 0 (future date
  /// = day 0). Not `ordinality(of: .day, in: .era)`: that counts UTC day
  /// boundaries and is off by one for most of the local day.
  static func daysTogether(anniversary: String, today: Date, calendar: Calendar = DayMath.gregorian) -> Int {
    guard let components = parseDate(anniversary),
          let start = calendar.date(from: components) else { return 0 }
    let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: start),
                                       to: calendar.startOfDay(for: today)).day ?? 0
    return max(0, days)
  }

  static func nextMilestone(_ days: Int) -> Int {
    milestones.first { days < $0 } ?? ((days / 500) + 1) * 500
  }

  /// The Home progress bar: days / next, clamped to 0…1.
  static func progress(days: Int, next: Int) -> Double {
    guard next > 0 else { return 0 }
    return min(1, max(0, Double(days) / Double(next)))
  }

  /// "6 tháng" / "1 năm" / "1.500 ngày" from the snapshot's templates.
  static func milestoneLabel(_ next: Int, monthsOne: String, monthsFmt: String,
                             yearsOne: String, yearsFmt: String, daysFmt: String,
                             number: (Int) -> String) -> String {
    if next % 365 == 0 {
      let n = next / 365
      return n == 1 ? yearsOne : yearsFmt.replacingOccurrences(of: "{count}", with: number(n))
    }
    if next < 365 && next % 30 == 0 {
      let n = next / 30
      return n == 1 ? monthsOne : monthsFmt.replacingOccurrences(of: "{count}", with: number(n))
    }
    return daysFmt.replacingOccurrences(of: "{count}", with: number(next))
  }

  /// Grouped integer in the app's language (vi → 1.500, en → 1,500).
  static func format(_ n: Int, lang: String) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.locale = Locale(identifier: lang == "vi" ? "vi_VN" : "en_US")
    return formatter.string(from: NSNumber(value: n)) ?? String(n)
  }
}
