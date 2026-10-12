import Foundation

// Feature home-widget: the widget's DayMath.swift must match Dart
// (LoveTreeService.daysTogether + _getNextMilestone in home_screen.dart) and
// the Kotlin DayMathTest — same vectors in all three. Run via
// scripts/check-widget-daymath.sh.

var failures = 0
func check(_ ok: Bool, _ what: String) {
  if !ok { failures += 1; print("FAIL: \(what)") }
}

var hcm = Calendar(identifier: .gregorian)
hcm.timeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh")!
let today = hcm.date(from: DateComponents(year: 2026, month: 10, day: 12, hour: 0, minute: 30))!

check(DayMath.daysTogether(anniversary: "2026-10-12", today: today, calendar: hcm) == 0, "same day = 0")
check(DayMath.daysTogether(anniversary: "2026-10-11", today: today, calendar: hcm) == 1, "yesterday = 1 even at 00:30")
check(DayMath.daysTogether(anniversary: "2025-10-12", today: today, calendar: hcm) == 365, "one year = 365")
check(DayMath.daysTogether(anniversary: "2023-05-14", today: today, calendar: hcm) == 1247, "mock couple = 1247")
check(DayMath.daysTogether(anniversary: "2026-10-13", today: today, calendar: hcm) == 0, "future date = 0, not -1")
check(DayMath.daysTogether(anniversary: "garbage", today: today, calendar: hcm) == 0, "bad input = 0")

var berlin = Calendar(identifier: .gregorian)
berlin.timeZone = TimeZone(identifier: "Europe/Berlin")!
let afterDst = berlin.date(from: DateComponents(year: 2026, month: 3, day: 30, hour: 0, minute: 30))!
check(DayMath.daysTogether(anniversary: "2026-03-29", today: afterDst, calendar: berlin) == 1, "DST change costs no day")

let table: [(Int, Int)] = [(0, 30), (29, 30), (30, 50), (364, 365), (365, 500), (1247, 1500),
                           (2999, 3000), (3000, 3500), (3499, 3500), (3500, 4000)]
for (days, next) in table { check(DayMath.nextMilestone(days) == next, "next(\(days)) == \(next)") }

check(abs(DayMath.progress(days: 1247, next: 1500) - 0.8313) < 0.001, "progress = days / next")
check(DayMath.progress(days: 10, next: 5) == 1, "progress clamps to 1")
check(DayMath.format(1500, lang: "vi") == "1.500", "vi groups with a dot")
check(DayMath.format(1500, lang: "en") == "1,500", "en groups with a comma")

func label(_ n: Int) -> String {
  DayMath.milestoneLabel(n, monthsOne: "1 tháng", monthsFmt: "{count} tháng",
                         yearsOne: "1 năm", yearsFmt: "{count} năm", daysFmt: "{count} ngày",
                         number: { DayMath.format($0, lang: "vi") })
}
check(label(30) == "1 tháng", "30 → 1 tháng")
check(label(180) == "6 tháng", "180 → 6 tháng")
check(label(365) == "1 năm", "365 → 1 năm")
check(label(730) == "2 năm", "730 → 2 năm")
check(label(1500) == "1.500 ngày", "1500 → 1.500 ngày")
check(label(50) == "50 ngày", "50 → 50 ngày")

if failures > 0 { print("\(failures) check(s) failed"); exit(1) }
print("OK DayMath — \(table.count + 17) checks")
