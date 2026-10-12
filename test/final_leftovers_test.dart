import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:provider/provider.dart';

import 'package:dear_embeiu/l10n/app_localizations.dart';
import 'package:dear_embeiu/models/milestone_reminder.dart';
import 'package:dear_embeiu/providers/custom_reminders_provider.dart';
import 'package:dear_embeiu/providers/reminder_provider.dart';
import 'package:dear_embeiu/screens/reminders_screen.dart';
import 'package:dear_embeiu/services/reminder_service.dart';
import 'package:dear_embeiu/theme/app_theme.dart';
import 'package:dear_embeiu/widgets/eyebrow_chip.dart';
import 'package:dear_embeiu/widgets/header_icon_button.dart';
import 'package:dear_embeiu/widgets/sub_screen_header.dart';

// Audit 2026-10-12, last round (design-unify + reminders + sleep). No font is
// loaded on purpose, as in ui_leftovers_test: the test font draws every glyph a
// full em wide — wider than Quicksand — so "no overflow" also holds in the app.

class _NoOs extends Fake implements ReminderService {}

/// Every milestone on (so every tile shows its time chip) at "10:00 AM" — the
/// widest English time.
class _AllOn extends ReminderProvider {
  _AllOn() : super(service: _NoOs());

  @override
  bool isMilestoneEnabled(MilestoneType type) => true;

  @override
  TimeOfDay effectiveTimeOf(MilestoneType type) =>
      const TimeOfDay(hour: 10, minute: 0);
}

Widget _app(Widget home, {String lang = 'vi'}) => MaterialApp(
  theme: AppTheme.lightTheme,
  locale: Locale(lang),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: home,
);

Widget _reminders({String lang = 'vi'}) => MultiProvider(
  providers: [
    ChangeNotifierProvider<ReminderProvider>(create: (_) => _AllOn()),
    ChangeNotifierProvider(create: (_) => CustomRemindersProvider()),
  ],
  child: _app(RemindersScreen(key: ValueKey(lang)), lang: lang),
);

final _back = find.byWidgetPredicate(
  (w) => w is HeaderIconButton && w.icon == IconsaxPlusLinear.arrow_left,
);

void main() {
  group('Lời nhắc: the time chip never overflows and keeps its size', () {
    for (final width in [320.0, 360.0]) {
      for (final scale in [1.0, 1.5, 2.0]) {
        testWidgets('@${width}dp ×$scale', (tester) async {
          // Tall enough that all 7 tiles are laid out.
          tester.view.physicalSize = Size(width * 3, 4000 * 3);
          tester.view.devicePixelRatio = 3;
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          tester.platformDispatcher.accessibilityFeaturesTestValue =
              const FakeAccessibilityFeatures(disableAnimations: true);
          addTearDown(tester.view.reset);
          addTearDown(tester.platformDispatcher.clearAllTestValues);

          for (final lang in ['vi', 'en']) {
            await tester.pumpWidget(_reminders(lang: lang));
            await tester.pump(const Duration(seconds: 1)); // entrance timers
            expect(tester.takeException(), isNull, reason: lang);

            final time = const TimeOfDay(
              hour: 10,
              minute: 0,
            ).format(tester.element(find.byType(RemindersScreen)));
            final chips = find.text(time);
            expect(chips, findsNWidgets(kMilestoneOrder.length), reason: lang);
            for (final chip in chips.evaluate()) {
              final text = chip.renderObject! as RenderParagraph;
              // The whole time, never "10:00 A…" …
              expect(text.didExceedMaxLines, isFalse, reason: '$lang $time');
              // … at the size the user picked, not shrunk to fit.
              expect(
                tester
                    .getRect(find.byElementPredicate((e) => e == chip))
                    .height,
                greaterThanOrEqualTo(12 * scale),
                reason: '$lang $time',
              );
            }
          }
        });
      }
    }
  });

  group('SubScreenHeader: back and chip are separate semantics nodes', () {
    testWidgets('Lời nhắc screen', (tester) async {
      await tester.pumpWidget(_reminders());
      await tester.pump(const Duration(seconds: 1));
      final l10n = lookupAppLocalizations(const Locale('vi'));

      final back = tester.getSemantics(_back);
      expect(
        back,
        isSemantics(label: l10n.back, isButton: true, hasTapAction: true),
      );
      final chip = tester.getSemantics(find.byType(EyebrowChip));
      expect(
        chip,
        isSemantics(
          label: l10n.remindersHubBadge,
          isHeader: true,
          isButton: false,
          hasTapAction: false,
        ),
      );
      expect(chip.id, isNot(back.id));
    });

    testWidgets('any list item, with a text trailing', (tester) async {
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: ListView(
              children: [
                SubScreenHeader(
                  badge: 'NHỮNG NGÀY ĐẶC BIỆT',
                  badgeIcon: IconsaxPlusLinear.flag,
                  trailing: const Text('3/20'),
                ),
              ],
            ),
          ),
        ),
      );
      final back = tester.getSemantics(_back);
      final chip = tester.getSemantics(find.byType(EyebrowChip));
      final trailing = tester.getSemantics(find.text('3/20'));
      expect(back, isSemantics(label: 'Quay lại', hasTapAction: true));
      expect(chip, isSemantics(label: 'NHỮNG NGÀY ĐẶC BIỆT'));
      expect(trailing, isSemantics(label: '3/20'));
      expect({back.id, chip.id, trailing.id}, hasLength(3));
    });
  });

  group('T6-2 the sleep share caption mentions the edit labels', () {
    // The partner also sees the "Đã sửa" / "Ghi tay" pill (SourcePill), so the
    // caption can't promise "nothing else".
    for (final (lang, label, nothingElse) in [
      ('vi', 'nhãn', 'Không có gì khác'),
      ('en', 'label', 'Nothing else'),
    ]) {
      test(lang, () {
        final copy = lookupAppLocalizations(Locale(lang)).sleepShareAskOnly;
        expect(copy, contains(label));
        expect(copy, isNot(contains(nothingElse)));
      });
    }
  });
}
