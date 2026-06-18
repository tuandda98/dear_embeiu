import 'package:dear_embeiu/utils/lunar_calendar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LunarCalendar.fromSolar — known reference dates', () {
    test('Tết Giáp Thìn: 2024-02-10 → mồng 1 tháng 1 năm 2024', () {
      final l = LunarCalendar.fromSolar(DateTime(2024, 2, 10));
      expect(l.day, 1);
      expect(l.month, 1);
      expect(l.year, 2024);
    });

    test('Tết Đoan Ngọ: 2024-06-10 → mồng 5 tháng 5', () {
      final l = LunarCalendar.fromSolar(DateTime(2024, 6, 10));
      expect(l.day, 5);
      expect(l.month, 5);
    });

    test('Trung Thu: 2024-09-17 → rằm (15) tháng 8', () {
      final l = LunarCalendar.fromSolar(DateTime(2024, 9, 17));
      expect(l.day, 15);
      expect(l.month, 8);
    });

    test('Tết Ất Tỵ: 2025-01-29 → mồng 1 tháng 1 năm 2025', () {
      final l = LunarCalendar.fromSolar(DateTime(2025, 1, 29));
      expect(l.day, 1);
      expect(l.month, 1);
      expect(l.year, 2025);
    });
  });

  test('canChiYear', () {
    expect(LunarCalendar.canChiYear(2024), 'Giáp Thìn');
    expect(LunarCalendar.canChiYear(2025), 'Ất Tỵ');
  });

  group('nextOneAndFifteen', () {
    test('returns chronological day-1 / day-15 events with correct flags', () {
      // Start just before Tết Giáp Thìn so the first event is mồng 1.
      final events = LunarCalendar.nextOneAndFifteen(DateTime(2024, 2, 9), 4);
      expect(events.length, 4);
      // Strictly increasing dates.
      for (var i = 1; i < events.length; i++) {
        expect(events[i].date.isAfter(events[i - 1].date), isTrue);
      }
      // First should be the 2024-02-10 mồng 1.
      expect(events.first.isFirstDay, isTrue);
      expect(events.first.date, DateTime(2024, 2, 10));
      // Each flagged day really is a lunar 1 or 15.
      for (final e in events) {
        final l = LunarCalendar.fromSolar(e.date);
        expect(l.day, e.isFirstDay ? 1 : 15);
      }
    });
  });
}
