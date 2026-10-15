import Foundation

/// Feature sleep (motion fallback): pure span-building logic behind the
/// `motionStillSpans` channel call, kept free of Core Motion types so
/// `scripts/check-sleep-motion.sh` can compile and check it without a simulator.
struct MotionActivity {
  let start: Date
  let stationary: Bool
  let lowConfidence: Bool
  let unknown: Bool
  let moving: Bool  // walking / running / cycling / automotive
}

enum MotionSpanBuilder {
  /// Flat Int64 [startMs, endMs, …] of stationary spans inside [from, to].
  /// iOS keeps only 7 days of history, so `from` is clamped to now − 7 days
  /// and `to` to now.
  static func spans(activities: [MotionActivity], from: Date, to: Date, now: Date) -> [Int64] {
    let start = max(from, now.addingTimeInterval(-7 * 86400))
    let end = min(to, now)
    guard start < end else { return [] }
    var flat: [Int64] = []
    var open: Date?
    func close(_ at: Date) {
      if let s = open, at > s {
        flat.append(Int64(s.timeIntervalSince1970 * 1000))
        flat.append(Int64(at.timeIntervalSince1970 * 1000))
      }
      open = nil
    }
    for a in activities {
      if a.moving {
        close(a.start)
      } else if a.stationary && !a.lowConfidence && !a.unknown {
        if open == nil { open = max(a.start, start) }
      } else if !(a.stationary || a.unknown) {
        close(a.start)
      }
      // Low-confidence stationary / unknown: neutral, the span stays as is.
    }
    close(end)
    return flat
  }
}
