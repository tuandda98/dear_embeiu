import 'dart:math' as math;

/// Vietnamese lunar calendar (âm lịch) — a self-contained, offline port of Hồ
/// Ngọc Đức's algorithm (timezone UTC+7). Used by the (account-gated) lunar
/// reminder feature to show today's lunar date and to find the upcoming
/// mồng-một (lunar day 1) / ngày-rằm (lunar day 15) dates to schedule on.
///
/// Reference: https://www.informatik.uni-leipzig.de/~duc/amlich/
class LunarDate {
  const LunarDate({
    required this.day,
    required this.month,
    required this.year,
    required this.isLeapMonth,
  });

  final int day;
  final int month;
  final int year;
  final bool isLeapMonth;
}

/// A future lunar event the reminder cares about: the Gregorian [date] of a
/// lunar day-1 ([isFirstDay] == true) or day-15 (full moon, false).
typedef LunarEvent = ({DateTime date, bool isFirstDay});

class LunarCalendar {
  const LunarCalendar._();

  /// Vietnam standard time offset (hours) the lunar months are computed against.
  static const double _timeZone = 7.0;

  static const List<String> _can = [
    'Giáp',
    'Ất',
    'Bính',
    'Đinh',
    'Mậu',
    'Kỷ',
    'Canh',
    'Tân',
    'Nhâm',
    'Quý',
  ];
  static const List<String> _chi = [
    'Tý',
    'Sửu',
    'Dần',
    'Mão',
    'Thìn',
    'Tỵ',
    'Ngọ',
    'Mùi',
    'Thân',
    'Dậu',
    'Tuất',
    'Hợi',
  ];

  /// Can-Chi name of a lunar year, e.g. 2024 → "Giáp Thìn".
  static String canChiYear(int lunarYear) =>
      '${_can[(lunarYear + 6) % 10]} ${_chi[(lunarYear + 8) % 12]}';

  /// Converts a Gregorian [date] to its Vietnamese lunar date.
  static LunarDate fromSolar(DateTime date) {
    final r = _convertSolar2Lunar(date.day, date.month, date.year, _timeZone);
    return LunarDate(
      day: r[0],
      month: r[1],
      year: r[2],
      isLeapMonth: r[3] == 1,
    );
  }

  /// The next [count] Gregorian dates at or after [from] whose lunar day-of-month
  /// is in [days] (e.g. {1, 15}), chronological. Iterates day by day — scanning
  /// ~420 days comfortably collects a half-year of monthly events.
  static List<({DateTime date, int lunarDay})> nextLunarDays(
    DateTime from,
    Set<int> days,
    int count,
  ) {
    final out = <({DateTime date, int lunarDay})>[];
    if (days.isEmpty || count <= 0) {
      return out;
    }
    var d = DateTime(from.year, from.month, from.day);
    for (var i = 0; i < 420 && out.length < count; i++) {
      final lunar = fromSolar(d);
      if (days.contains(lunar.day)) {
        out.add((date: d, lunarDay: lunar.day));
      }
      d = d.add(const Duration(days: 1));
    }
    return out;
  }

  /// Convenience for the canonical mồng-1 / ngày-rằm pair (used by the summary
  /// card). [isFirstDay] marks day-1 vs day-15.
  static List<LunarEvent> nextOneAndFifteen(DateTime from, int count) =>
      nextLunarDays(
        from,
        const {1, 15},
        count,
      ).map((e) => (date: e.date, isFirstDay: e.lunarDay == 1)).toList();

  // ── Hồ Ngọc Đức algorithm ───────────────────────────────────────────────────

  static int _jdFromDate(int dd, int mm, int yy) {
    final a = (14 - mm) ~/ 12;
    final y = yy + 4800 - a;
    final m = mm + 12 * a - 3;
    var jd =
        dd +
        (153 * m + 2) ~/ 5 +
        365 * y +
        y ~/ 4 -
        y ~/ 100 +
        y ~/ 400 -
        32045;
    if (jd < 2299161) {
      jd = dd + (153 * m + 2) ~/ 5 + 365 * y + y ~/ 4 - 32083;
    }
    return jd;
  }

  static int _getNewMoonDay(int k, double timeZone) {
    final t = k / 1236.85;
    final t2 = t * t;
    final t3 = t2 * t;
    const dr = math.pi / 180;
    var jd1 =
        2415020.75933 + 29.53058868 * k + 0.0001178 * t2 - 0.000000155 * t3;
    jd1 = jd1 + 0.00033 * math.sin((166.56 + 132.87 * t - 0.009173 * t2) * dr);
    final m = 359.2242 + 29.10535608 * k - 0.0000333 * t2 - 0.00000347 * t3;
    final mpr = 306.0253 + 385.81691806 * k + 0.0107306 * t2 + 0.00001236 * t3;
    final f = 21.2964 + 390.67050646 * k - 0.0016528 * t2 - 0.00000239 * t3;
    var c1 =
        (0.1734 - 0.000393 * t) * math.sin(m * dr) +
        0.0021 * math.sin(2 * dr * m);
    c1 = c1 - 0.4068 * math.sin(mpr * dr) + 0.0161 * math.sin(dr * 2 * mpr);
    c1 = c1 - 0.0004 * math.sin(dr * 3 * mpr);
    c1 = c1 + 0.0104 * math.sin(dr * 2 * f) - 0.0051 * math.sin(dr * (m + mpr));
    c1 =
        c1 -
        0.0074 * math.sin(dr * (m - mpr)) +
        0.0004 * math.sin(dr * (2 * f + m));
    c1 =
        c1 -
        0.0004 * math.sin(dr * (2 * f - m)) -
        0.0006 * math.sin(dr * (2 * f + mpr));
    c1 =
        c1 +
        0.0010 * math.sin(dr * (2 * f - mpr)) +
        0.0005 * math.sin(dr * (2 * mpr + m));
    double deltat;
    if (t < -11) {
      deltat =
          0.001 +
          0.000839 * t +
          0.0002261 * t2 -
          0.00000845 * t3 -
          0.000000081 * t * t3;
    } else {
      deltat = -0.000278 + 0.000265 * t + 0.000262 * t2;
    }
    final jdNew = jd1 + c1 - deltat;
    return (jdNew + 0.5 + timeZone / 24).floor();
  }

  static int _getSunLongitude(int jdn, double timeZone) {
    final t = (jdn - 2451545.5 - timeZone / 24) / 36525;
    final t2 = t * t;
    const dr = math.pi / 180;
    final m =
        357.52910 + 35999.05030 * t - 0.0001559 * t2 - 0.00000048 * t * t2;
    final l0 = 280.46645 + 36000.76983 * t + 0.0003032 * t2;
    var dl = (1.914600 - 0.004817 * t - 0.000014 * t2) * math.sin(dr * m);
    dl =
        dl +
        (0.019993 - 0.000101 * t) * math.sin(dr * 2 * m) +
        0.000290 * math.sin(dr * 3 * m);
    var l = l0 + dl;
    l = l * dr;
    l = l - math.pi * 2 * (l / (math.pi * 2)).floor();
    return (l / math.pi * 6).floor();
  }

  static int _getLunarMonth11(int yy, double timeZone) {
    final off = _jdFromDate(31, 12, yy) - 2415021;
    final k = (off / 29.530588853).floor();
    var nm = _getNewMoonDay(k, timeZone);
    final sunLong = _getSunLongitude(nm, timeZone);
    if (sunLong >= 9) {
      nm = _getNewMoonDay(k - 1, timeZone);
    }
    return nm;
  }

  static int _getLeapMonthOffset(int a11, double timeZone) {
    final k = ((a11 - 2415021.076998695) / 29.530588853 + 0.5).floor();
    var last = 0;
    var i = 1;
    var arc = _getSunLongitude(_getNewMoonDay(k + i, timeZone), timeZone);
    do {
      last = arc;
      i++;
      arc = _getSunLongitude(_getNewMoonDay(k + i, timeZone), timeZone);
    } while (arc != last && i < 14);
    return i - 1;
  }

  static List<int> _convertSolar2Lunar(
    int dd,
    int mm,
    int yy,
    double timeZone,
  ) {
    final dayNumber = _jdFromDate(dd, mm, yy);
    final k = ((dayNumber - 2415021.076998695) / 29.530588853).floor();
    var monthStart = _getNewMoonDay(k + 1, timeZone);
    if (monthStart > dayNumber) {
      monthStart = _getNewMoonDay(k, timeZone);
    }
    var a11 = _getLunarMonth11(yy, timeZone);
    var b11 = a11;
    int lunarYear;
    if (a11 >= monthStart) {
      lunarYear = yy;
      a11 = _getLunarMonth11(yy - 1, timeZone);
    } else {
      lunarYear = yy + 1;
      b11 = _getLunarMonth11(yy + 1, timeZone);
    }
    final lunarDay = dayNumber - monthStart + 1;
    final diff = ((monthStart - a11) / 29).floor();
    var lunarLeap = 0;
    var lunarMonth = diff + 11;
    if (b11 - a11 > 365) {
      final leapMonthDiff = _getLeapMonthOffset(a11, timeZone);
      if (diff >= leapMonthDiff) {
        lunarMonth = diff + 10;
        if (diff == leapMonthDiff) {
          lunarLeap = 1;
        }
      }
    }
    if (lunarMonth > 12) {
      lunarMonth = lunarMonth - 12;
    }
    if (lunarMonth >= 11 && diff < 4) {
      lunarYear -= 1;
    }
    return [lunarDay, lunarMonth, lunarYear, lunarLeap];
  }
}
