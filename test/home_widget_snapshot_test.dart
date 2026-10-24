import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:dear_embeiu/l10n/app_localizations.dart';
import 'package:dear_embeiu/models/couple.dart';
import 'package:dear_embeiu/services/home_widget_snapshot.dart';

/// Feature home-widget (D4): Flutter owns the words, native owns the numbers.
/// Every string the widget prints is pre-translated here; native only fills
/// `{count}` / `{label}` and formats the day count.
void main() {
  setUpAll(() => initializeDateFormatting());

  final vi = lookupAppLocalizations(const Locale('vi'));
  final en = lookupAppLocalizations(const Locale('en'));
  final epoch = DateTime(2023, 5, 14, 9, 30); // time of day must not leak

  Couple couple({String name2 = 'Thảo'}) => Couple(
    id: 'c1',
    person1Name: 'Tuấn',
    person2Name: name2,
    anniversaryDate: epoch,
    inviteCode: 'ABC123',
    memberIds: const ['me', 'other'],
    memberCount: 2,
    createdByUserId: 'me',
    status: 'active',
    createdAt: epoch,
    updatedAt: epoch,
  );

  test('couple → counter snapshot with Vietnamese templates', () {
    final s = HomeWidgetSnapshot.build(couple: couple(), l10n: vi);
    expect(s['state'], 'counter');
    expect(s['lang'], 'vi');
    expect(s['anniversary'], '2023-05-14');
    expect(s['name1'], 'Tuấn');
    expect(s['name2'], 'Thảo');
    expect(s['daysLabel'], 'ngày bên nhau');
    expect(s['milestoneFmt'], 'Cột mốc {label}');
    expect(s['daysLeftOne'], 'còn 1 ngày');
    expect(s['daysLeftFmt'], 'còn {count} ngày');
    expect(s['todayLabel'], 'hôm nay 🎉');
    expect(s['monthsOne'], '1 tháng');
    expect(s['monthsFmt'], '{count} tháng');
    expect(s['yearsOne'], '1 năm');
    expect(s['yearsFmt'], '{count} năm');
    expect(s['daysFmt'], '{count} ngày');
    expect(s['sinceText'], 'Bắt đầu từ 14 thg 5, 2023');
  });

  test('English keeps its plural forms and date style', () {
    final s = HomeWidgetSnapshot.build(couple: couple(), l10n: en);
    expect(s['lang'], 'en');
    expect(s['daysLabel'], 'days together');
    expect(s['milestoneFmt'], 'Milestone: {label}');
    expect(s['daysLeftOne'], '1 day left');
    expect(s['daysLeftFmt'], '{count} days left');
    expect(s['monthsOne'], '1 month');
    expect(s['monthsFmt'], '{count} months');
    expect(s['yearsFmt'], '{count} years');
    expect(s['sinceText'], 'Since May 14, 2023');
  });

  test('no couple → empty snapshot, no stale counter keys', () {
    final s = HomeWidgetSnapshot.build(couple: null, l10n: vi);
    expect(s['state'], 'empty');
    expect(s['lang'], 'vi');
    expect(s['emptyChip'], 'DEAR EMBEIU');
    expect(s['emptyText'], 'Chạm để bắt đầu đếm ngày yêu');
    expect(s.containsKey('anniversary'), isFalse);
    expect(s.containsKey('name1'), isFalse);
  });

  test('names are trimmed; a blank partner name stays blank', () {
    final s = HomeWidgetSnapshot.build(
      couple: couple(name2: '  '),
      l10n: vi,
    );
    expect(s['name2'], '');
  });

  test('templates keep their placeholders and drop the sentinel digit', () {
    for (final l10n in [vi, en]) {
      final s = HomeWidgetSnapshot.build(couple: couple(), l10n: l10n);
      for (final key in ['daysLeftFmt', 'monthsFmt', 'yearsFmt', 'daysFmt']) {
        expect(s[key], contains('{count}'), reason: key);
        expect(s[key], isNot(contains('0')), reason: key);
      }
      expect(s['milestoneFmt'], contains('{label}'));
    }
  });
}
