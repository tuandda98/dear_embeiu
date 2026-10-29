import 'package:dear_embeiu/l10n/app_localizations.dart';
import 'package:dear_embeiu/providers/decision_provider.dart';
import 'package:dear_embeiu/services/analytics_service.dart';
import 'package:dear_embeiu/widgets/decision_card.dart';
import 'package:dear_embeiu/widgets/play_together_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _IdleDecisions extends DecisionProvider {
  @override
  void refreshDay() {}
}

/// 360×640 phone, 16 gutters, text ×1.3, English (the longest copy).
Future<void> _pumpSmall(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(360, 640);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MediaQuery(
        data: const MediaQueryData(
          size: Size(360, 640),
          textScaler: TextScaler.linear(1.3),
        ),
        child: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    ),
  );
}

/// Home "Lúc rảnh" tiles show an entry line's first sentence bold and the
/// rest grey (splitEntryLine). These pin that cut on the real ARB copy, so a
/// copy edit that drops the "state. detail." shape fails here.
void main() {
  group('splitEntryLine', () {
    test('cuts after the first sentence and drops its full stop', () {
      expect(splitEntryLine('Đến lượt bạn. Thảo vừa đi nước 14.'), (
        'Đến lượt bạn',
        'Thảo vừa đi nước 14.',
      ));
    });
    test('keeps ? and ! on the bold part', () {
      expect(splitEntryLine('Xong! Rủ tiếp?'), ('Xong!', 'Rủ tiếp?'));
    });
    test('one sentence → all bold, no grey line', () {
      expect(splitEntryLine('Rủ Thảo một ván, bạn đi trước.'), (
        'Rủ Thảo một ván, bạn đi trước',
        '',
      ));
      expect(splitEntryLine('Người ấy đã ra rồi!'), (
        'Người ấy đã ra rồi!',
        '',
      ));
      expect(splitEntryLine('Tuần này 3 – 1 – 2'), ('Tuần này 3 – 1 – 2', ''));
    });
    test('a thousands dot is not a sentence end', () {
      expect(splitEntryLine('Tuấn 1.024 – 9 Thảo. Rủ Thảo một ván?'), (
        'Tuấn 1.024 – 9 Thảo',
        'Rủ Thảo một ván?',
      ));
    });
  });

  for (final code in ['vi', 'en']) {
    test('every caro state splits without losing text ($code)', () {
      final l10n = lookupAppLocalizations(Locale(code));
      for (final kind in CaroEntryKind.values) {
        if (kind == CaroEntryKind.loading) continue;
        final view = caroEntryView(
          l10n,
          kind,
          partnerName: 'Thảo',
          score: l10n.caroScore('Tuấn', '12', '9', 'Thảo'),
          moves: '14',
          time: '10:12',
          staleDays: '3',
        );
        final (head, rest) = splitEntryLine(view.subtitle);
        expect(head, isNotEmpty, reason: '$kind');
        expect(head.endsWith('.'), isFalse, reason: '$kind');
        // Nothing dropped but the one full stop between the two parts.
        final joined = rest.isEmpty ? head : '$head $rest';
        expect(
          joined.replaceAll('.', ''),
          view.subtitle.trim().replaceAll('.', ''),
          reason: '$kind',
        );
      }
    });
  }

  test('the my-turn state reads as on the mock (vi)', () {
    final l10n = lookupAppLocalizations(const Locale('vi'));
    final view = caroEntryView(
      l10n,
      CaroEntryKind.myTurn,
      partnerName: 'Thảo',
      score: '',
      moves: '14',
      time: '',
      staleDays: '0',
    );
    expect(splitEntryLine(view.subtitle), (
      'Đến lượt bạn',
      'Thảo vừa đi nước 14.',
    ));
    expect(view.cta, 'Đi tiếp');
    expect(view.urgent, isTrue);
  });

  testWidgets('two play tiles at 360 ×1.3: no overflow, equal heights', (
    tester,
  ) async {
    Widget tile(String title, String sub, String cta, bool urgent) => PlayTile(
      view: CaroEntryView(
        title: title,
        subtitle: sub,
        cta: cta,
        urgent: urgent,
      ),
      badge: const SizedBox(width: 36, height: 36),
      onTap: () {},
    );
    await _pumpSmall(
      tester,
      IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: tile(
                'Caro',
                'Waiting for Thảo. You played move 14 at 10:12.',
                'Open',
                false,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: tile(
                'Rock Paper Scissors',
                'Challenge your person to a round',
                'Play',
                false,
              ),
            ),
          ],
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    final heights = tester
        .widgetList<PlayTile>(find.byType(PlayTile))
        .map((w) => tester.getSize(find.byWidget(w)).height)
        .toSet();
    expect(heights.length, 1, reason: 'tiles end on one line');
  });

  testWidgets('compact decision card at 360 ×1.3: three buttons, no overflow', (
    tester,
  ) async {
    await _pumpSmall(
      tester,
      ChangeNotifierProvider<DecisionProvider>.value(
        value: _IdleDecisions(),
        child: const DecisionCard(),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('What to eat?'), findsOneWidget);
    expect(find.text('Where to go?'), findsOneWidget);
    expect(find.text('Other'), findsOneWidget);
    // Each button is a ≥44 tall target.
    for (final label in ['What to eat?', 'Where to go?', 'Other']) {
      final button = find.ancestor(
        of: find.text(label),
        matching: find.byType(ConstrainedBox),
      );
      expect(tester.getSize(button.first).height, greaterThanOrEqualTo(44));
    }
  });

  testWidgets('tapping a game tile logs home_entry_tap with its urgency', (
    tester,
  ) async {
    final events = <(String, Map<String, Object?>?)>[];
    AnalyticsService.debugOnEvent = (name, params) =>
        events.add((name, params));
    addTearDown(() => AnalyticsService.debugOnEvent = null);
    await _pumpSmall(
      tester,
      // Bounded height, as on Home (the pair sits in IntrinsicHeight).
      IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: PlayTile(
                view: const CaroEntryView(
                  title: 'Caro',
                  subtitle: 'Your turn. Thảo just played move 14.',
                  cta: 'Your move',
                  urgent: true,
                ),
                badge: const SizedBox(width: 36, height: 36),
                // Same call the Home caro tile makes before opening the game.
                onTap: () => AnalyticsService.instance.logHomeEntryTap(
                  'caro',
                  urgent: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    await tester.tap(find.byType(PlayTile));
    expect(events.single.$1, 'home_entry_tap');
    expect(events.single.$2, {'entry': 'caro', 'urgent': true});
  });
}
