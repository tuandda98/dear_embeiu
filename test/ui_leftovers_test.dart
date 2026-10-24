import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:provider/provider.dart';

import 'package:dear_embeiu/l10n/app_localizations.dart';
import 'package:dear_embeiu/models/app_user.dart';
import 'package:dear_embeiu/providers/auth_provider.dart';
import 'package:dear_embeiu/providers/couple_provider.dart';
import 'package:dear_embeiu/screens/love_tree_screen.dart';
import 'package:dear_embeiu/screens/settings_screen.dart';
import 'package:dear_embeiu/services/auth_service.dart';
import 'package:dear_embeiu/theme/app_theme.dart';
import 'package:dear_embeiu/widgets/eyebrow_chip.dart';
import 'package:dear_embeiu/widgets/header_icon_button.dart';
import 'package:dear_embeiu/widgets/sub_screen_header.dart';

// Audit 2026-10-12, round 2 (R2-c/d/e). No font is loaded on purpose: the
// default test font draws every glyph a full em wide — wider than Quicksand —
// so "no overflow" here also holds with the app's font.

const _widths = [320.0, 360.0, 375.0];
const _scales = [1.0, 1.5, 2.0];

class _UnpairedAuth extends AuthProvider {
  _UnpairedAuth() : super(authService: AuthService());

  @override
  AppUser? get currentUser => AppUser(
    id: 'me',
    email: 'me@test.dev',
    displayName: 'Anh',
    inviteCode: 'ABC123',
    status: 'single',
    createdAt: DateTime(2026, 10, 11),
    updatedAt: DateTime(2026, 10, 11),
  );
}

/// Every label the app puts in an [EyebrowChip]: the sub-screen badges plus
/// the tabs, auth, intro, waiting card and sheets.
List<String> _chipLabels(AppLocalizations l) => [
  l.careMessageBadge,
  l.careTimelineBadge,
  l.chatBadge,
  l.chatBgBadge,
  l.counterBgBadge,
  l.coupleOnboardingBadge,
  l.createAccountBadge,
  l.createPostBadge,
  l.customReminderFormBadge,
  l.customRemindersBadge,
  l.editCoupleBadge,
  l.featureTourBadge,
  l.forceUpdateBadge,
  l.forgotPasswordBadge,
  l.guestModeBadge,
  l.homeWaitingBadge,
  l.introSlide1Badge,
  l.introSlide2Badge,
  l.introSlide3Badge,
  l.journalBadge,
  l.loveProfileBadge,
  l.loveTreeBadge,
  l.lunarCalendarBadge,
  l.milestoneBadge,
  l.notifCenterBadge,
  l.privateGalleryBadge,
  l.remindersHubBadge,
  l.rpsGameBadge,
  l.rpsHistoryBadge,
  l.settingsBadge,
  l.sleepBadge,
  l.verifyEmailBadge,
  l.welcomeBackBadge,
];

void _phone(WidgetTester tester, double width, double scale) {
  tester.view.physicalSize = Size(width * 3, 800 * 3);
  tester.view.devicePixelRatio = 3;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearAllTestValues);
}

Widget _app(Widget home, {String lang = 'vi'}) => MaterialApp(
  theme: AppTheme.lightTheme,
  locale: Locale(lang),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: home,
);

/// The trailing actions real screens put in [SubScreenHeader]: none, a 44px
/// icon (Cây tình yêu, Oẳn tù tì, thông báo), the "Lưu" button (form lời nhắc)
/// and the x/20 counter (lời nhắc riêng).
Map<String, Widget?> _trailings(AppLocalizations l) => {
  'none': null,
  'icon': HeaderIconButton(
    icon: IconsaxPlusLinear.share,
    semanticsLabel: 'share',
    onTap: () {},
  ),
  'save': TextButton(
    onPressed: () {},
    child: Text(
      l.customRemindersSave,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
    ),
  ),
  'counter': Text(
    l.customRemindersCount(20),
    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
  ),
};

const _trailingKey = ValueKey('trailing');

final _back = find.byWidgetPredicate(
  (w) => w is HeaderIconButton && w.icon == IconsaxPlusLinear.arrow_left,
);

void main() {
  group('R2-c EyebrowChip stays on one line without overflowing', () {
    for (final width in _widths) {
      for (final scale in _scales) {
        testWidgets('SubScreenHeader @${width}dp ×$scale', (tester) async {
          _phone(tester, width, scale);
          for (final lang in ['vi', 'en']) {
            final l10n = lookupAppLocalizations(Locale(lang));
            for (final label in _chipLabels(l10n)) {
              for (final MapEntry(key: kind, value: trailing) in _trailings(
                l10n,
              ).entries) {
                final what = '$lang "$label" + $kind';
                // One key per case: an overflow is reported once per render
                // object, so a reused one would hide the next case's.
                await tester.pumpWidget(
                  _app(
                    Scaffold(
                      body: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: [
                              SubScreenHeader(
                                key: ValueKey(what),
                                badge: label,
                                badgeIcon: IconsaxPlusLinear.setting_2,
                                trailing: trailing == null
                                    ? null
                                    : KeyedSubtree(
                                        key: _trailingKey,
                                        child: trailing,
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    lang: lang,
                  ),
                );
                expect(tester.takeException(), isNull, reason: what);
                // A cut-off label still offers the full text on long-press.
                expect(find.byTooltip(label), findsOneWidget, reason: what);

                // The chip never slides under the back arrow's 44px target
                // or the trailing action.
                final chip = tester.getRect(find.byType(EyebrowChip));
                expect(
                  chip.left,
                  greaterThanOrEqualTo(tester.getRect(_back).right),
                  reason: what,
                );
                if (trailing != null) {
                  expect(
                    chip.right,
                    lessThanOrEqualTo(
                      tester.getRect(find.byKey(_trailingKey)).left,
                    ),
                    reason: what,
                  );
                }
              }
            }
          }
        });
      }
    }

    testWidgets('a short chip stays centred on the screen', (tester) async {
      _phone(tester, 375, 1);
      final l10n = lookupAppLocalizations(const Locale('vi'));
      for (final MapEntry(key: kind, value: trailing) in _trailings(
        l10n,
      ).entries) {
        await tester.pumpWidget(
          _app(
            Scaffold(
              body: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    SubScreenHeader(
                      key: ValueKey(kind),
                      badge: l10n.sleepBadge,
                      badgeIcon: IconsaxPlusLinear.moon,
                      trailing: trailing,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        expect(
          tester.getRect(find.byType(EyebrowChip)).center.dx,
          moreOrLessEquals(375 / 2, epsilon: 0.5),
          reason: kind,
        );
      }
    });

    testWidgets('an unbounded parent Row (Profile, catch-up) still works', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          const Scaffold(
            body: Row(
              children: [
                EyebrowChip(label: 'ANH BY <3'),
                Spacer(),
                Text('1/3'),
              ],
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('ANH BY <3'), findsOneWidget);
    });
  });

  group('R2-d "Không thể hoàn tác" wraps instead of overflowing', () {
    for (final width in _widths) {
      for (final scale in _scales) {
        testWidgets('Settings @${width}dp ×$scale', (tester) async {
          _phone(tester, width, scale);
          for (final lang in ['vi', 'en']) {
            final l10n = lookupAppLocalizations(Locale(lang));
            await tester.pumpWidget(
              MultiProvider(
                providers: [
                  ChangeNotifierProvider<AuthProvider>(
                    create: (_) => _UnpairedAuth(),
                  ),
                  ChangeNotifierProvider(create: (_) => CoupleProvider()),
                ],
                child: _app(SettingsScreen(key: ValueKey(lang)), lang: lang),
              ),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull, reason: lang);

            // Both red rules stay visible beside the warning.
            final row = find
                .ancestor(
                  of: find.text(l10n.profileDangerIrreversible),
                  matching: find.byType(Row),
                )
                .first;
            final rules = find.descendant(
              of: row,
              matching: find.byType(Divider),
            );
            expect(rules, findsNWidgets(2));
            for (final rule in rules.evaluate()) {
              expect(rule.size!.width, greaterThanOrEqualTo(24), reason: lang);
            }
          }
        });
      }
    }
  });

  group('R2-e "Khoe cây" copy follows the flower count', () {
    for (final lang in ['vi', 'en']) {
      final l10n = lookupAppLocalizations(Locale(lang));

      test('$lang: no flower yet → the just-sprouted lines', () {
        final copy = loveTreeShareCopy(l10n, days: 12, flowers: 0);
        expect(copy.message, l10n.loveTreeShareMessageSeed);
        expect(copy.message, isNot(contains(RegExp(r'\d'))));
        expect(copy.stats, l10n.loveTreeMilestoneDays(12));
        expect(copy.tagline, l10n.loveTreeShareTaglineSeed);
      });

      test('$lang: from the first flower → the original lines', () {
        for (final flowers in [1, 3]) {
          final copy = loveTreeShareCopy(l10n, days: 120, flowers: flowers);
          expect(copy.message, l10n.loveTreeShareMessage(flowers, 120));
          expect(copy.stats, l10n.loveTreeShareStats(120, flowers));
          expect(copy.tagline, l10n.loveTreeShareTagline);
        }
      });

      test('$lang: the first day reads as such, never "0"', () {
        // A first photo that day already makes a flower.
        for (final flowers in [0, 1]) {
          final copy = loveTreeShareCopy(l10n, days: 0, flowers: flowers);
          expect(copy.stats, l10n.loveTreeShareFirstDay);
          expect(copy.message, l10n.loveTreeShareMessageSeed);
          expect(copy.tagline, l10n.loveTreeShareTaglineSeed);
          expect('${copy.stats}${copy.message}', isNot(contains('0')));
        }
        // From day 1 on, the count is back.
        expect(
          loveTreeShareCopy(l10n, days: 1, flowers: 0).stats,
          l10n.loveTreeMilestoneDays(1),
        );
      });
    }
  });
}
