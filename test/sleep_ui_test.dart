import 'dart:io';
import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:dear_embeiu/l10n/app_localizations.dart';
import 'package:dear_embeiu/models/app_user.dart';
import 'package:dear_embeiu/models/couple.dart';
import 'package:dear_embeiu/models/sleep_night.dart';
import 'package:dear_embeiu/providers/auth_provider.dart';
import 'package:dear_embeiu/providers/couple_provider.dart';
import 'package:dear_embeiu/providers/sleep_provider.dart';
import 'package:dear_embeiu/screens/sleep_screen.dart';
import 'package:dear_embeiu/services/auth_service.dart';
import 'package:dear_embeiu/services/sleep_service.dart';
import 'package:dear_embeiu/theme/app_theme.dart';
import 'package:dear_embeiu/widgets/content_card.dart';
import 'package:dear_embeiu/widgets/person_label.dart';
import 'package:dear_embeiu/widgets/sleep/sleep_card.dart';
import 'package:dear_embeiu/widgets/sleep/sleep_sheets.dart';

/// UI of feature sleep (audit 2026-10-12, SU1–SU8, SU11): screen readers,
/// big text on small phones, a partner abroad, DST in the edit sheet.

final _epoch = DateTime(2026, 1, 1);
const _longName = 'Nguyễn Hoàng Phương Anh';

class _Auth extends AuthProvider {
  _Auth() : super(authService: AuthService());

  @override
  AppUser? get currentUser => AppUser(
    id: 'me',
    email: 'me@test.dev',
    displayName: 'Anh',
    inviteCode: 'ABC123',
    status: 'in_couple',
    createdAt: _epoch,
    updatedAt: _epoch,
  );
}

Couple _couple(String partner) => Couple(
  id: 'c1',
  person1Name: partner,
  person2Name: 'Anh',
  anniversaryDate: DateTime(2025, 1, 1),
  inviteCode: 'ABC123',
  memberIds: const ['other', 'me'],
  memberCount: 2,
  createdByUserId: 'other',
  status: 'active',
  createdAt: _epoch,
  updatedAt: _epoch,
);

class _CoupleP extends CoupleProvider {
  _CoupleP(this._c);
  final Couple _c;

  @override
  Couple? get couple => _c;
}

/// Tracking on, both share; nights handed in. Records colour picks + saves.
class _Sleep extends SleepProvider {
  _Sleep({this.mine = const {}, this.theirs = const {}});

  final Map<String, SleepNight> mine;
  final Map<String, SleepNight> theirs;
  final colors = <String>[];
  final saved = <({String date, DateTime bedAt, DateTime wakeAt, int? tz})>[];

  @override
  bool get isLoaded => true;
  @override
  bool get enabled => true;
  @override
  SleepMode get mode => SleepMode.manual;
  @override
  bool get isUsingFirebase => true;
  @override
  bool get hasPartner => true;
  @override
  bool get partnerShares => true;
  @override
  bool get myShare => true;
  @override
  Map<String, SleepNight> get myNights => mine;
  @override
  Map<String, SleepNight> get partnerNights => theirs;
  @override
  String get myColorId => 'rose';
  @override
  String get partnerColorId => 'purple';
  @override
  String? get partnerColorChoice => 'purple';
  @override
  bool get myColorAdjusted => false;
  @override
  bool get needsPermission => false;
  @override
  bool get healthHasNoData => false;
  @override
  bool get cardHidden => false;

  @override
  Future<void> setColor(String id) async => colors.add(id);

  @override
  Future<void> saveNight(
    String date,
    DateTime bedAt,
    DateTime wakeAt, {
    int? tz,
  }) async => saved.add((date: date, bedAt: bedAt, wakeAt: wakeAt, tz: tz));
}

/// The motion-fallback bits of the screen, driven by plain flags.
class _MotionSleep extends _Sleep {
  _MotionSleep({
    this.hint = false,
    this.modeValue = SleepMode.manual,
    this.motionOnly = false,
    this.granted = false,
    this.recentAuto = false,
  });
  final bool hint;
  final SleepMode modeValue;
  final bool motionOnly;
  final bool granted;
  final bool recentAuto;

  @override
  bool get showMotionHint => hint;
  @override
  SleepMode get mode => modeValue;
  @override
  bool get onMotionOnly => motionOnly;
  @override
  bool get motionGranted => granted;
  @override
  bool get hasRecentAutoNight => recentAuto;
  @override
  bool get healthHasNoData => modeValue == SleepMode.health;
}

/// 25 nights up to last night, 23:xx → 06/07:xx local, mixed sources.
Map<String, SleepNight> _nights({required int offsetMin}) {
  final out = <String, SleepNight>{};
  final last = sleepDateFromKey(SleepProvider.lastNightKey())!;
  for (var i = 0; i < 25; i++) {
    final wakeDay = DateTime(last.year, last.month, last.day - i);
    final bed = DateTime(
      wakeDay.year,
      wakeDay.month,
      wakeDay.day - 1,
      23,
    ).add(Duration(minutes: offsetMin + (i % 3) * 20));
    final key = sleepDateKey(wakeDay);
    out[key] = SleepNight(
      date: key,
      bedAt: bed,
      wakeAt: bed.add(Duration(minutes: 7 * 60 + 45 - (i % 4) * 50)),
      wakeUps: i.isEven ? const [60, 200] : const [],
      source: SleepSource.values[i % 4],
    );
  }
  return out;
}

Future<void> _loadQuicksand() async {
  final loader = FontLoader(AppTheme.fontFamily);
  for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
    final bytes = File('assets/fonts/Quicksand-$weight.ttf').readAsBytesSync();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
}

Widget _app(
  Widget home,
  SleepProvider sleep, {
  String partner = 'Minh Anh',
  String lang = 'vi',
}) => MultiProvider(
  providers: [
    ChangeNotifierProvider<AuthProvider>(create: (_) => _Auth()),
    ChangeNotifierProvider<CoupleProvider>(
      create: (_) => _CoupleP(_couple(partner)),
    ),
    ChangeNotifierProvider<SleepProvider>.value(value: sleep),
  ],
  child: MaterialApp(
    theme: AppTheme.lightTheme,
    locale: Locale(lang),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  ),
);

/// A [width]×[height] phone, text at [scale], Reduce Motion on.
void _phone(
  WidgetTester tester,
  double width, {
  double height = 844,
  double scale = 1,
}) {
  tester.view.physicalSize = Size(width * 3, height * 3);
  tester.view.devicePixelRatio = 3;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearAllTestValues);
}

SemanticsData _node(WidgetTester tester, Finder f) =>
    tester.getSemantics(f).getSemanticsData();

/// Moves [t] (a UTC instant) onto a clock [tz] minutes east of UTC.
DateTime _onClock(DateTime t, int tz) => t.toUtc().add(Duration(minutes: tz));

/// The night detail's lane painter (private: read through dynamic access).
dynamic _lanes(WidgetTester tester) => find
    .byType(CustomPaint)
    .evaluate()
    .map((e) => (e.widget as CustomPaint).painter)
    .singleWhere((p) => p.runtimeType.toString() == '_LanePainter');

/// Where the two drawn bars meet, read off the painter (from, to).
List<int> _barsMeet(dynamic painter) {
  final bars = [for (final l in painter.lanes as List) l.bar];
  return [
    bars.map((b) => b.from as int).reduce((x, y) => x > y ? x : y),
    bars.map((b) => b.to as int).reduce((x, y) => x < y ? x : y),
  ];
}

/// A night on this phone's clock, [tz] = the offset at bedtime (1.9.1+).
SleepNight _local(String key, DateTime bed, DateTime wake, {bool tz = true}) =>
    SleepNight(
      date: key,
      bedAt: bed,
      wakeAt: wake,
      source: SleepSource.auto,
      tz: tz ? bed.timeZoneOffset.inMinutes : null,
    );

void main() {
  setUpAll(_loadQuicksand);

  testWidgets('SU1: month arrows, days and colours are tappable by TalkBack', (
    tester,
  ) async {
    _phone(tester, 390, height: 2000);
    final semantics = tester.ensureSemantics();
    final sleep = _Sleep(
      mine: _nights(offsetMin: 0),
      theirs: _nights(offsetMin: 35),
    );
    await tester.pumpWidget(_app(const SleepScreen(), sleep));
    await tester.pump(const Duration(seconds: 1));

    // The calendar opens on the month of last night.
    final shown = sleepDateFromKey(SleepProvider.lastNightKey())!;
    final now = DateTime.now();

    // Previous month: has the action, and it works (below).
    final prev = find.bySemanticsLabel('Tháng trước');
    expect(_node(tester, prev).hasAction(SemanticsAction.tap), isTrue);
    // Next month on the current month: disabled, so no action.
    if (shown.month == now.month) {
      expect(
        _node(
          tester,
          find.bySemanticsLabel('Tháng sau'),
        ).hasAction(SemanticsAction.tap),
        isFalse,
      );
    }

    // Day 1 of this month: tapping it through semantics selects it.
    final day1 = find.bySemanticsLabel(RegExp(r'^Ngày 1:'));
    expect(_node(tester, day1).hasAction(SemanticsAction.tap), isTrue);
    tester.semantics.tap(find.semantics.byLabel(RegExp(r'^Ngày 1:')));
    await tester.pump();
    expect(_node(tester, day1).flagsCollection.isSelected, Tristate.isTrue);

    // A free colour: tap action → setColor. The partner's colour: none.
    final teal = find.bySemanticsLabel('Ngọc');
    expect(_node(tester, teal).hasAction(SemanticsAction.tap), isTrue);
    tester.semantics.tap(find.semantics.byLabel('Ngọc'));
    expect(sleep.colors, ['teal']);
    expect(
      _node(
        tester,
        find.bySemanticsLabel('Màu của Minh Anh'),
      ).hasAction(SemanticsAction.tap),
      isFalse,
    );

    tester.semantics.tap(find.semantics.byLabel('Tháng trước'));
    await tester.pump(const Duration(seconds: 1));
    // Calendar title + the stats section title.
    final before = DateTime(shown.year, shown.month - 1);
    expect(
      find.text('Tháng ${before.month} năm ${before.year}'),
      findsNWidgets(2),
    );
    semantics.dispose();
  });

  group('SU2–SU4: big text on small phones', () {
    for (final lang in ['vi', 'en']) {
      for (final width in [320.0, 360.0, 390.0]) {
        for (final scale in [1.0, 1.3, 1.5, 2.0]) {
          testWidgets('$lang @${width.toInt()}dp ×$scale', (tester) async {
            _phone(tester, width, height: 1400, scale: scale);
            final sleep = _Sleep(
              mine: _nights(offsetMin: 0),
              theirs: _nights(offsetMin: 35),
            );
            // Any overflow fails the test on its own.
            await tester.pumpWidget(
              _app(const SleepScreen(), sleep, partner: _longName, lang: lang),
            );
            await tester.pump(const Duration(seconds: 1));

            // The lane names keep their whole line (no cut "y" in Nguyễn).
            final names = [lang == 'vi' ? 'Bạn' : 'You', _longName];
            for (final e in find.byType(Text).evaluate()) {
              final text = e.widget as Text;
              if (!names.contains(text.data)) {
                continue;
              }
              final p = tester.renderObject<RenderParagraph>(
                find.descendant(
                  of: find.byWidget(text),
                  matching: find.byType(RichText),
                ),
              );
              expect(
                p.getMaxIntrinsicHeight(p.size.width),
                lessThanOrEqualTo(p.size.height + 0.5),
                reason: '"${text.data}" clipped',
              );
            }

            // Hour labels never overlap.
            final hours = [
              for (final e
                  in find
                      .byWidgetPredicate(
                        (w) =>
                            w is Text &&
                            w.data != null &&
                            RegExp(r'^\d{1,2}h$').hasMatch(w.data!),
                      )
                      .evaluate())
                tester.getRect(find.byWidget(e.widget)),
            ];
            expect(hours.length, greaterThanOrEqualTo(3));
            for (var i = 1; i < hours.length; i++) {
              expect(hours[i].left, greaterThan(hours[i - 1].right));
            }
          });
        }
      }
    }
  });

  testWidgets('SU7: a night logged by hand reads "ghi tay", not "đã sửa"', (
    tester,
  ) async {
    _phone(tester, 390, height: 2000);
    final semantics = tester.ensureSemantics();
    final key = SleepProvider.lastNightKey();
    final wake = sleepDateFromKey(key)!.add(const Duration(hours: 7));

    Future<String> cellLabel(SleepSource source) async {
      final night = SleepNight(
        date: key,
        bedAt: wake.subtract(const Duration(hours: 8)),
        wakeAt: wake,
        source: source,
      );
      await tester.pumpWidget(
        _app(const SleepScreen(), _Sleep(mine: {key: night})),
      );
      await tester.pump(const Duration(seconds: 1));
      return _node(
        tester,
        find.bySemanticsLabel(RegExp('^Ngày ${wake.day}:')),
      ).label;
    }

    final manual = await cellLabel(SleepSource.manual);
    expect(manual, contains('(ghi tay)'));
    expect(manual, isNot(contains('đã sửa')));
    expect(await cellLabel(SleepSource.edited), contains('(đã sửa)'));
    expect(await cellLabel(SleepSource.auto), isNot(contains('(')));
    semantics.dispose();
  });

  group('SU8, R2-a: a partner abroad, a night from a trip', () {
    // Their clock is 10+ h away from this phone's, whatever zone runs this.
    final local = DateTime.now().timeZoneOffset.inMinutes;
    final tz = local <= 0 ? local + 600 : local - 600;

    /// Their night ending on [wakeKey] (their date), 23:00 → 07:00 their time.
    SleepNight abroad(String wakeKey) {
      final d = sleepDateFromKey(wakeKey)!;
      return SleepNight(
        date: wakeKey,
        bedAt: DateTime.utc(
          d.year,
          d.month,
          d.day - 1,
          23,
        ).subtract(Duration(minutes: tz)),
        wakeAt: DateTime.utc(
          d.year,
          d.month,
          d.day,
          7,
        ).subtract(Duration(minutes: tz)),
        source: SleepSource.auto,
        tz: tz,
      );
    }

    testWidgets('night detail: their clock + "Giờ bên ấy"', (tester) async {
      _phone(tester, 390, height: 2000);
      final key = SleepProvider.lastNightKey();
      final theirs = abroad(key);
      expect(_onClock(theirs.bedAt, tz).hour, 23); // sanity
      final mine = _nights(offsetMin: 0);
      final sleep = _Sleep(mine: mine, theirs: {key: theirs});
      await tester.pumpWidget(_app(const SleepScreen(), sleep));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('23:00 → 7:00'), findsOneWidget); // vi: H:mm
      // Only beside their times — my night is on this phone's clock.
      expect(find.text('Giờ bên ấy'), findsOneWidget);
    });

    testWidgets('home card: their last night on their date', (tester) async {
      _phone(tester, 390);
      // Their "this morning" may be another date than mine.
      final key = SleepProvider.lastNightKey(
        DateTime.now().toUtc().add(Duration(minutes: tz)),
      );
      final sleep = _Sleep(
        mine: _nights(offsetMin: 0),
        theirs: {key: abroad(key)},
      );
      final couple = _couple('Minh Anh');
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: SingleChildScrollView(child: SleepCard(couple: couple)),
          ),
          sleep,
        ),
      );
      await tester.pump();

      expect(find.text('23:00 – 7:00'), findsOneWidget);
      expect(find.text('Giờ bên ấy'), findsOneWidget);
    });

    testWidgets('R2-a: my night from a trip is edited on its own clock', (
      tester,
    ) async {
      _phone(tester, 390);
      final key = SleepProvider.lastNightKey();
      final trip = abroad(key); // recorded abroad: 23:00 → 07:00 there
      final sleep = _Sleep(mine: {key: trip});
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: Builder(
              builder: (c) => Center(
                child: TextButton(
                  onPressed: () => showSleepEditSheet(c, dateKey: key),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
          sleep,
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('23:00'), findsOneWidget);
      expect(find.text('07:00'), findsOneWidget);

      // Wake-up 07:00 → 07:30, picked (and so read back) on that clock.
      await tester.tap(find.text('Thức dậy'));
      await tester.pumpAndSettle();
      final minutes = tester.widget<ListWheelScrollView>(
        find.byType(ListWheelScrollView).last,
      );
      (minutes.controller! as FixedExtentScrollController).jumpToItem(30);
      await tester.pump();
      await tester.tap(find.text('Xác nhận'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lưu'));
      await tester.pumpAndSettle();

      final s = sleep.saved.single;
      expect(s.tz, tz);
      expect(s.bedAt.isAtSameMomentAs(trip.bedAt), isTrue); // untouched
      expect(s.wakeAt.difference(trip.wakeAt), const Duration(minutes: 30));
    });
  });

  group('N2, N4: labels and times read in full on small phones, big text', () {
    // Their clock is 2 h behind this phone's; the night edited too, so both
    // labels show side by side.
    final local = DateTime.now().timeZoneOffset.inMinutes;
    final tz = local - 120;

    RenderParagraph paragraph(WidgetTester tester, Finder text) =>
        tester.renderObject<RenderParagraph>(
          find.descendant(of: text, matching: find.byType(RichText)),
        );

    for (final lang in ['vi', 'en']) {
      for (final width in [320.0, 360.0, 390.0, 412.0]) {
        for (final scale in [1.0, 1.3, 1.5, 2.0]) {
          final at = '$lang @${width.toInt()}dp ×$scale';

          testWidgets('N2 home card labels: $at', (tester) async {
            _phone(tester, width, height: 1200, scale: scale);
            final key = SleepProvider.lastNightKey(
              DateTime.now().toUtc().add(Duration(minutes: tz)),
            );
            final d = sleepDateFromKey(key)!;
            final theirs = SleepNight(
              date: key,
              bedAt: DateTime.utc(
                d.year,
                d.month,
                d.day - 1,
                23,
              ).subtract(Duration(minutes: tz)),
              wakeAt: DateTime.utc(
                d.year,
                d.month,
                d.day,
                7,
              ).subtract(Duration(minutes: tz)),
              source: SleepSource.edited,
              tz: tz,
            );
            await tester.pumpWidget(
              _app(
                Scaffold(
                  body: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: SleepCard(couple: _couple('Minh Anh')),
                  ),
                ),
                _Sleep(mine: _nights(offsetMin: 0), theirs: {key: theirs}),
                lang: lang,
              ),
            );
            await tester.pump();

            // The partner's column: as wide as its name row.
            final column = tester.getRect(
              find.byWidgetPredicate(
                (w) => w is PersonLabel && w.name == 'Minh Anh',
              ),
            );
            final labels = lang == 'vi'
                ? ['Giờ bên ấy', 'Đã sửa']
                : ['Their time', 'Edited'];
            for (final label in labels) {
              final text = find.text(label);
              final p = paragraph(tester, text);
              expect(p.didExceedMaxLines, isFalse, reason: label);
              // The pill: its own size vs. what the screen shows.
              final pill = find
                  .ancestor(of: text, matching: find.byType(Container))
                  .first;
              final natural = tester.renderObject<RenderBox>(pill).size.width;
              final box = tester.getRect(pill);
              expect(box.left, greaterThanOrEqualTo(column.left - 0.5));
              expect(box.right, lessThanOrEqualTo(column.right + 0.5));
              // Shrinks only when a whole column is too narrow, and a little.
              final shown = box.width / natural;
              if (natural <= column.width) {
                expect(shown, closeTo(1, 0.001), reason: label);
              } else {
                expect(shown, greaterThanOrEqualTo(0.75), reason: label);
              }
            }
          });

          testWidgets('N4 night detail times: $at', (tester) async {
            _phone(tester, width, height: 2400, scale: scale);
            final key = SleepProvider.lastNightKey();
            final d = sleepDateFromKey(key)!;
            DateTime t(int day, int h, int m) =>
                DateTime(d.year, d.month, d.day + day, h, m);
            await tester.pumpWidget(
              _app(
                const SleepScreen(),
                _Sleep(
                  mine: {key: _local(key, t(-1, 23, 45), t(0, 6, 55))},
                  theirs: {key: _local(key, t(-1, 22, 50), t(0, 7, 10))},
                ),
                lang: lang,
              ),
            );
            await tester.pump(const Duration(seconds: 1));

            final times = find.byWidgetPredicate(
              (w) =>
                  w is Text &&
                  w.data != null &&
                  RegExp(r'^\d{1,2}:\d\d → \d{1,2}:\d\d$').hasMatch(w.data!),
            );
            expect(times, findsNWidgets(2));
            final card = tester.getRect(
              find
                  .ancestor(of: times.first, matching: find.byType(ContentCard))
                  .first,
            );
            for (final e in times.evaluate()) {
              final f = find.byWidget(e.widget);
              final p = paragraph(tester, f);
              expect(p.didExceedMaxLines, isFalse);
              // One line: every glyph box sits on the same top.
              final boxes = p.getBoxesForSelection(
                TextSelection(
                  baseOffset: 0,
                  extentOffset: p.text.toPlainText().length,
                ),
              );
              expect(boxes.map((b) => b.top).toSet(), hasLength(1));
              expect(
                tester.getRect(f).right,
                lessThanOrEqualTo(card.right - 16 + 0.5),
              );
            }
          });
        }
      }
    }
  });

  testWidgets('N4b: TalkBack reads all of my night, then the edit button', (
    tester,
  ) async {
    _phone(tester, 390, height: 2000);
    final semantics = tester.ensureSemantics();
    final key = SleepProvider.lastNightKey();
    final d = sleepDateFromKey(key)!;
    DateTime t(int day, int h, int m) =>
        DateTime(d.year, d.month, d.day + day, h, m);
    final mine = _local(
      key,
      t(-1, 23, 45),
      t(0, 6, 55),
    ).copyWith(wakeUps: const [60], source: SleepSource.edited);
    final theirs = _local(key, t(-1, 22, 50), t(0, 7, 10));

    /// Labels in the order a screen reader swipes through them.
    List<String> read() {
      final out = <String>[];
      void walk(SemanticsNode node) {
        final label = node.getSemanticsData().label;
        if (label.isNotEmpty) {
          out.add(label);
        }
        node
            .debugListChildrenInOrder(DebugSemanticsDumpOrder.traversalOrder)
            .forEach(walk);
      }

      walk(tester.getSemantics(find.byType(SleepScreen)));
      return out;
    }

    // Was: "Bạn → 7g 10p → Sửa… → 23:45 → 6:55"; empty: "Bạn → Sửa… →
    // Chưa ghi nhận".
    for (final (night, info) in [
      (mine, ['7g 10p', '23:45 → 6:55', 'Thức giấc 1 lần', 'Đã sửa']),
      (null, ['Chưa ghi nhận', 'Bấm nút sửa để ghi tay']),
    ]) {
      await tester.pumpWidget(
        _app(
          const SleepScreen(),
          _Sleep(mine: {key: ?night}, theirs: {key: theirs}),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      final order = read();
      int at(String text) => order.indexWhere((l) => l.contains(text));
      final edit = at('Sửa giờ ngủ đêm này');
      expect(edit, greaterThan(0));
      for (final text in info) {
        expect(at(text), inInclusiveRange(0, edit - 1), reason: text);
      }
      // The partner's night comes after my button, not in between.
      expect(at('22:50 → 7:10'), greaterThan(edit));
    }
    semantics.dispose();
  });

  group('wake-up times behind the ! icon', () {
    final key = SleepProvider.lastNightKey();
    final d = sleepDateFromKey(key)!;
    final bed = DateTime(d.year, d.month, d.day - 1, 23, 30);
    final night = _local(key, bed, DateTime(d.year, d.month, d.day, 7));

    testWidgets('tap shows every time, on the night\'s clock', (tester) async {
      _phone(tester, 390, height: 2000);
      await tester.pumpWidget(
        _app(
          const SleepScreen(),
          _Sleep(
            mine: {
              key: night.copyWith(wakeUps: const [220, 370]),
            },
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('3:10 · 5:40'), findsNothing);
      await tester.tap(find.bySemanticsLabel('Xem giờ thức giấc'));
      await tester.pumpAndSettle();
      expect(find.text('3:10 · 5:40'), findsOneWidget);
      expect(find.text('Số giờ ngủ gồm cả những lần thức này.'), findsOneWidget);
    });

    testWidgets('no icon on a night slept straight through', (tester) async {
      _phone(tester, 390, height: 2000);
      await tester.pumpWidget(
        _app(const SleepScreen(), _Sleep(mine: {key: night})),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.bySemanticsLabel('Xem giờ thức giấc'), findsNothing);
    });
  });

  group('N1: the "asleep together" band is where the two bars meet', () {
    final key = SleepProvider.lastNightKey();
    final day = sleepDateFromKey(key)!;
    DateTime at(int dayOffset, int h, int m, [int s = 0]) =>
        DateTime(day.year, day.month, day.day + dayOffset, h, m, s);

    Future<dynamic> detail(
      WidgetTester tester,
      SleepNight mine,
      SleepNight theirs,
    ) async {
      _phone(tester, 390, height: 2000);
      await tester.pumpWidget(
        _app(
          const SleepScreen(),
          _Sleep(mine: {key: mine}, theirs: {key: theirs}),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      return _lanes(tester);
    }

    testWidgets('times with seconds (auto nights) keep the band', (
      tester,
    ) async {
      // 23:00:30 vs 23:10:10: dropping the seconds put the two starts a
      // minute apart, and the band vanished.
      for (final legacy in [false, true]) {
        final p = await detail(
          tester,
          _local(key, at(-1, 23, 0, 30), at(0, 7, 0, 5), tz: !legacy),
          _local(key, at(-1, 23, 10, 10), at(0, 6, 30, 40)),
        );
        final band = p.together as ({int from, int to})?;
        expect(band, (from: 310, to: 750), reason: 'legacy: $legacy');
        expect([band!.from, band.to], _barsMeet(p));
      }
    });

    testWidgets('no band when their night is on another clock', (tester) async {
      // An hour behind: the bars still meet on the axis, but not in time.
      final tz = at(-1, 23, 0).timeZoneOffset.inMinutes - 60;
      final theirs = SleepNight(
        date: key,
        bedAt: at(-1, 23, 30),
        wakeAt: at(0, 6, 30),
        source: SleepSource.auto,
        tz: tz,
      );
      final p = await detail(
        tester,
        _local(key, at(-1, 23, 0), at(0, 7, 0)),
        theirs,
      );
      expect(p.together, isNull);
    });

    testWidgets('a night across a DST change: the band follows the bars '
        '(run with TZ=Australia/Sydney or Europe/Berlin)', (tester) async {
      // The latest wake-up date (last 400 days) whose night changes offset.
      DateTime? d;
      for (var i = 0; i <= 400 && d == null; i++) {
        final w = DateTime(day.year, day.month, day.day - i);
        final evening = DateTime(w.year, w.month, w.day - 1, 23);
        if (evening.timeZoneOffset !=
            DateTime(w.year, w.month, w.day, 7).timeZoneOffset) {
          d = w;
        }
      }
      if (d == null) {
        markTestSkipped('No DST in this time zone.');
        return;
      }
      final dst = d;
      final semantics = tester.ensureSemantics();
      final k = sleepDateKey(dst);
      DateTime t(int dayOffset, int h, int m) =>
          DateTime(dst.year, dst.month, dst.day + dayOffset, h, m);
      _phone(tester, 390, height: 2000);
      await tester.pumpWidget(
        _app(
          const SleepScreen(),
          _Sleep(
            mine: {k: _local(k, t(-1, 23, 0), t(0, 7, 0))},
            theirs: {k: _local(k, t(-1, 23, 30), t(0, 6, 30))},
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      final back = (day.year - dst.year) * 12 + day.month - dst.month;
      for (var i = 0; i < back; i++) {
        tester.semantics.tap(find.semantics.byLabel('Tháng trước'));
        await tester.pump(const Duration(seconds: 1));
      }
      tester.semantics.tap(find.semantics.byLabel(RegExp('^Ngày ${dst.day}:')));
      await tester.pump(const Duration(seconds: 1));

      final p = _lanes(tester);
      // Drawn on the clock: 23:00 → 7:00 and 23:30 → 6:30, whatever the
      // real length (7 or 9 h); the band used to end an hour off.
      expect(_barsMeet(p), [330, 750]);
      final band = p.together as ({int from, int to})?;
      expect(band, (from: 330, to: 750));
      semantics.dispose();
    });
  });

  testWidgets('SU11: editing a night across a DST change keeps the picked '
      'times', (tester) async {
    // The first wake-up date (±400 days) whose night crosses a change of the
    // local offset; none in a zone without DST (then nothing to check).
    final today = DateTime.now();
    DateTime? wakeDay;
    for (var i = -400; i <= 400 && wakeDay == null; i++) {
      final d = DateTime(today.year, today.month, today.day + i);
      final evening = DateTime(d.year, d.month, d.day - 1, 23);
      final morning = DateTime(d.year, d.month, d.day, 7);
      if (evening.timeZoneOffset != morning.timeZoneOffset) {
        wakeDay = d;
      }
    }
    if (wakeDay == null) {
      markTestSkipped('No DST in this time zone (run with TZ=Europe/Berlin).');
      return;
    }

    _phone(tester, 390);
    final sleep = _Sleep();
    final key = sleepDateKey(wakeDay);
    await tester.pumpWidget(
      _app(
        Scaffold(
          body: Builder(
            builder: (c) => Center(
              child: TextButton(
                onPressed: () => showSleepEditSheet(c, dateKey: key),
                child: const Text('open'),
              ),
            ),
          ),
        ),
        sleep,
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // A new night opens at 23:00 → 07:00; the total is the real one.
    final bed = DateTime(wakeDay.year, wakeDay.month, wakeDay.day - 1, 23);
    final wake = DateTime(wakeDay.year, wakeDay.month, wakeDay.day, 7);
    final hours = wake.difference(bed).inHours; // 7 or 9
    expect(hours, isNot(8));
    expect(find.text('Tổng: $hours giờ'), findsOneWidget);

    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();
    expect(sleep.saved, hasLength(1));
    final s = sleep.saved.single;
    expect([s.bedAt.day, s.bedAt.hour, s.bedAt.minute], [bed.day, 23, 0]);
    expect([s.wakeAt.day, s.wakeAt.hour, s.wakeAt.minute], [wake.day, 7, 0]);
    expect(s.tz, isNull); // a new night takes this phone's clock
  });

  testWidgets('SU6: sleep sheets stop under the status bar at 200%', (
    tester,
  ) async {
    _phone(tester, 320, height: 568, scale: 2);
    tester.view.padding = const FakeViewPadding(top: 20 * 3);
    final sleep = _Sleep(mine: _nights(offsetMin: 0));
    await tester.pumpWidget(
      _app(
        Scaffold(
          body: Builder(
            builder: (c) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: () => showSleepEditSheet(
                      c,
                      dateKey: SleepProvider.lastNightKey(),
                    ),
                    child: const Text('edit'),
                  ),
                  TextButton(
                    onPressed: () => showSleepHowItWorksSheet(c),
                    child: const Text('how'),
                  ),
                ],
              ),
            ),
          ),
        ),
        sleep,
      ),
    );

    for (final open in ['edit', 'how']) {
      await tester.tap(find.text(open));
      await tester.pumpAndSettle(); // the total line no longer overflows
      final top = tester.getTopLeft(find.byType(BackdropFilter).last).dy;
      expect(top, greaterThanOrEqualTo(20), reason: open);
      Navigator.of(tester.element(find.byType(BackdropFilter).last)).pop();
      await tester.pumpAndSettle();
    }
  });

  group('motion fallback on the sleep screen', () {
    Future<void> open(WidgetTester tester, SleepProvider sleep) async {
      _phone(tester, 390, height: 2400);
      await tester.pumpWidget(_app(const SleepScreen(), sleep));
      await tester.pump(const Duration(seconds: 1));
    }

    testWidgets('hint card shows "Cho phép" when showMotionHint', (
      tester,
    ) async {
      await open(tester, _MotionSleep(hint: true, modeValue: SleepMode.auto));
      expect(find.text('Cho phép'), findsOneWidget);
    });

    testWidgets('no hint card when showMotionHint is false', (tester) async {
      await open(tester, _MotionSleep(modeValue: SleepMode.auto));
      expect(find.text('Cho phép'), findsNothing);
    });

    testWidgets('source says "Chuyển động" on Android with motion only', (
      tester,
    ) async {
      await open(
        tester,
        _MotionSleep(
          modeValue: SleepMode.auto,
          motionOnly: true,
          granted: true,
        ),
      );
      expect(find.textContaining('Chuyển động của điện thoại'), findsOneWidget);
      expect(find.textContaining('Điện thoại (tự động)'), findsNothing);
    });

    testWidgets('source stays "Điện thoại" when Usage access is there', (
      tester,
    ) async {
      await open(
        tester,
        _MotionSleep(modeValue: SleepMode.auto, granted: true),
      );
      expect(find.textContaining('Điện thoại (tự động)'), findsOneWidget);
      expect(find.textContaining('Chuyển động của điện thoại'), findsNothing);
    });

    testWidgets(
      'iOS Health mode with motion-filled nights says "Chuyển động"',
      (tester) async {
        await open(
          tester,
          _MotionSleep(modeValue: SleepMode.health, recentAuto: true),
        );
        expect(
          find.textContaining('Chuyển động của điện thoại'),
          findsOneWidget,
        );
      },
    );

    testWidgets('iOS Health on but empty says so, not "Ghi tay"', (
      tester,
    ) async {
      await open(tester, _MotionSleep(modeValue: SleepMode.health));
      expect(
        find.textContaining('Apple Health (chưa có dữ liệu)'),
        findsOneWidget,
      );
      expect(find.textContaining('Nguồn: Ghi tay'), findsNothing);
    });

    testWidgets('manual mode never says "Chuyển động"', (tester) async {
      await open(tester, _MotionSleep(motionOnly: true, granted: true));
      expect(find.textContaining('Chuyển động của điện thoại'), findsNothing);
    });
  });
}
