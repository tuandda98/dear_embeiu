import Foundation

// Feature sleep (motion fallback): MotionSpanBuilder.spans of ios/Runner.
// Run via scripts/check-sleep-motion.sh.

var failures = 0
func check(_ ok: Bool, _ what: String) {
  if !ok { failures += 1; print("FAIL: \(what)") }
}

let now = Date(timeIntervalSince1970: 1_800_000_000)
func t(_ h: Double) -> Date { now.addingTimeInterval(h * 3600) }  // h hours from now
func ms(_ h: Double) -> Int64 { Int64(t(h).timeIntervalSince1970 * 1000) }
func still(_ h: Double, low: Bool = false) -> MotionActivity {
  MotionActivity(start: t(h), stationary: true, lowConfidence: low, unknown: false, moving: false)
}
func walk(_ h: Double) -> MotionActivity {
  MotionActivity(start: t(h), stationary: false, lowConfidence: false, unknown: false, moving: true)
}
func unknown(_ h: Double) -> MotionActivity {
  MotionActivity(start: t(h), stationary: false, lowConfidence: false, unknown: true, moving: false)
}
func spans(_ a: [MotionActivity], to: Double = 0) -> [Int64] {
  MotionSpanBuilder.spans(activities: a, from: t(-48), to: t(to), now: now)
}

check(spans([]).isEmpty, "empty activities = no spans")
check(spans([still(-10), walk(-6)]) == [ms(-10), ms(-6)], "stationary closed by walking")
check(spans([still(-10)]) == [ms(-10), ms(0)], "open span closes at min(to, now) = now")
check(spans([still(-10)], to: -4) == [ms(-10), ms(-4)], "open span closes at `to` when before now")
check(spans([still(-10)], to: 5) == [ms(-10), ms(0)], "`to` in the future is clamped to now")
check(spans([still(-10), still(-8), walk(-6)]) == [ms(-10), ms(-6)], "two stationary in a row = one span")
check(spans([still(-10), still(-8, low: true), walk(-6)]) == [ms(-10), ms(-6)], "low-confidence stationary is neutral")
check(spans([still(-10), unknown(-8), walk(-6)]) == [ms(-10), ms(-6)], "unknown is neutral")
check(spans([still(-10, low: true), walk(-6)]).isEmpty, "low-confidence alone never opens a span")
check(spans([unknown(-10), walk(-6)]).isEmpty, "unknown alone never opens a span")
check(spans([walk(-10), still(-8), walk(-6), still(-4)]) == [ms(-8), ms(-6), ms(-4), ms(0)], "two spans around a walk")
check(MotionSpanBuilder.spans(activities: [still(-1)], from: t(-1), to: t(-1), now: now).isEmpty, "from == to = nothing")
// 7-day clamp: a span opened before now-7d starts at now-7d.
check(MotionSpanBuilder.spans(activities: [still(-200), walk(-6)], from: t(-300), to: t(0), now: now)
  == [Int64(t(-168).timeIntervalSince1970 * 1000), ms(-6)], "history clamped to 7 days")

if failures > 0 { print("\(failures) failure(s)"); exit(1) }
print("sleep motion: all checks passed")
