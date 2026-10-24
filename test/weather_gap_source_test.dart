import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:dear_embeiu/services/analytics_service.dart';
import 'package:dear_embeiu/widgets/weather/weather_card.dart';

/// Gap cases of project/features/weather/test-cases.md that can only be
/// pinned down at the source level, because the code under test is private
/// or sits behind a platform singleton (analytics SDK, notification plugin,
/// HomeScreen state). They check structure, not behaviour — each test says
/// what it can't see.

String read(String path) => File(path).readAsStringSync();

void main() {
  final card = read('lib/widgets/weather/weather_card.dart');
  final sheets = read('lib/widgets/weather/weather_sheets.dart');

  // ── Analytics (AN-01..04, CH-22, CT-06) ──────────────────────────────────
  // AnalyticsService keeps its Firebase handle private, so no event can be
  // captured; what is checked is the call sites and the single funnel.

  group('analytics', () {
    test(
      'AN-01: every weather event goes through AnalyticsService.logEvent',
      () {
        for (final f in [
          'lib/widgets/weather/weather_card.dart',
          'lib/widgets/weather/weather_sheets.dart',
          'lib/providers/weather_provider.dart',
          'lib/services/weather_service.dart',
        ]) {
          expect(read(f), isNot(contains('FirebaseAnalytics')), reason: f);
        }
        expect(
          card,
          contains('AnalyticsService.instance.logEvent(name, params: params)'),
        );
      },
    );

    test(
      'AN-01: logEvent is a no-op without a bound SDK or after opt-out',
      () async {
        final src = read('lib/services/analytics_service.dart');
        final at = src.indexOf('void logEvent(String name');
        expect(
          src.substring(at, at + 400),
          contains('if (analytics == null || !_enabled)'),
        );
        // Runtime: in a test the SDK is never bound, opt-out flips the flag,
        // and logging neither throws nor needs Hive.
        final dir = Directory.systemTemp.createTempSync('weather_gap_hive');
        Hive.init(dir.path);
        await Hive.openBox<String>('app_settings');
        addTearDown(() async {
          await Hive.close();
          dir.deleteSync(recursive: true);
        });
        final a = AnalyticsService.instance;
        await a.setEnabled(false);
        expect(a.isEnabled, isFalse);
        expect(
          Hive.box<String>('app_settings').get('analytics_enabled'),
          'false',
        );
        logWeatherEvent(WeatherEvents.citySet, {
          'who': 'self',
          'region': 'vn',
          'entry': 'card',
        });
        await a.setEnabled(true);
        expect(a.isEnabled, isTrue);
      },
    );

    test('AN-02: weather_city_set carries who / region / entry only', () {
      expect(WeatherEvents.citySet, 'weather_city_set');
      final m = RegExp(
        r'logWeatherEvent\(WeatherEvents\.citySet, \{(.*?)\}\);',
        dotAll: true,
      ).firstMatch(sheets)!;
      final keys = RegExp(
        r"'(\w+)':",
      ).allMatches(m.group(1)!).map((e) => e.group(1)).toList();
      expect(keys, ['who', 'region', 'entry']);
      expect(m.group(1), contains("forPartner ? 'partner' : 'self'"));
      expect(m.group(1), contains("city.isVietnam ? 'vn' : 'intl'"));
      expect(m.group(1), isNot(contains('city.id')));
    });

    test(
      'AN-02 / CH-22: the event sits inside `if (ok)`, the failure branch logs nothing',
      () {
        final then = RegExp(
          r'write\.then\(\(ok\) \{\s*if \(ok\) \{\s*logWeatherEvent\(WeatherEvents\.citySet.*?return;\s*\}(.*?)\}\);',
          dotAll: true,
        ).firstMatch(sheets);
        expect(then, isNotNull, reason: 'log first in `if (ok)`, then return');
        expect(then!.group(1), isNot(contains('logWeatherEvent')));
        expect(then.group(1), contains('showSnackBar'));
      },
    );

    test('AN-03: weather_card_tap {state} — fixed vocabulary, no city', () {
      expect(WeatherEvents.cardTap, 'weather_card_tap');
      expect(
        card,
        contains(
          "logWeatherEvent(WeatherEvents.cardTap, {'state': _stateName(w, error)});",
        ),
      );
      final states = RegExp(r"return '(\w+)';")
          .allMatches(card.substring(card.indexOf('static String _stateName')))
          .map((e) => e.group(1))
          .take(5)
          .toList();
      expect(states, ['error', 'both', 'mine_only', 'partner_only', 'empty']);
    });

    test(
      'AN-03 / CT-06: weather_cta_tap {condition, entry}; card for card+sheet',
      () {
        expect(WeatherEvents.ctaTap, 'weather_cta_tap');
        final m = RegExp(
          r'logWeatherEvent\(WeatherEvents\.ctaTap, \{(.*?)\}\);',
          dotAll: true,
        ).firstMatch(card)!.group(1)!;
        expect(m, contains("'condition': weatherCtaCondition(cta)"));
        expect(
          m,
          contains(
            "'entry': entry == 'notification' ? 'notification' : 'card'",
          ),
        );
        expect(RegExp(r"'(\w+)':").allMatches(m).length, 2);
      },
    );

    test('CT-06: the care screen is opened with source "weather"', () {
      final at = card.indexOf('void openWeatherCare(');
      final body = card.substring(at, card.indexOf('\n}\n', at));
      expect(body, contains("source: 'weather'"));
      // care_message_sent then carries that tag.
      final care = read('lib/screens/care_message_screen.dart');
      expect(care, contains('source: widget.source'));
      final a = read('lib/services/analytics_service.dart');
      expect(a, contains('AnalyticsEvents.pSource: source'));
    });

    test('AN-03: weatherCtaCondition names rain / hot / cold', () {
      // (the three values the dashboard filters on)
      expect(card, contains("WeatherCta.umbrella => 'rain'"));
      expect(card, contains("WeatherCta.water => 'hot'"));
      expect(card, contains("WeatherCta.warm => 'cold'"));
    });

    test(
      'AN-04: weather_notif_toggle {enabled} is logged after the permission, before the write',
      () {
        expect(WeatherEvents.noticeToggle, 'weather_notif_toggle');
        final at = sheets.indexOf('Future<void> toggle(bool value)');
        final body = sheets.substring(at, sheets.indexOf('final noticeOn', at));
        final denied = body.indexOf('requestPermissions()');
        final log = body.indexOf(
          "logWeatherEvent(WeatherEvents.noticeToggle, {'enabled': value});",
        );
        final set = body.indexOf('w.setNoticeEnabled(value)');
        expect(denied, greaterThan(-1));
        expect(
          log,
          greaterThan(denied),
          reason: 'a denied permission logs nothing',
        );
        expect(set, greaterThan(log));
      },
    );
  });

  // ── LG-03: ARB parity ────────────────────────────────────────────────────

  group('ARB', () {
    final en = jsonDecode(read('lib/l10n/app_en.arb')) as Map<String, dynamic>;
    final vi = jsonDecode(read('lib/l10n/app_vi.arb')) as Map<String, dynamic>;
    Iterable<String> keys(Map<String, dynamic> m) =>
        m.keys.where((k) => k.startsWith('weather'));
    Set<String> holes(String s) =>
        RegExp(r'\{(\w+)\}').allMatches(s).map((e) => e.group(1)!).toSet();

    test('LG-03: every weather* key exists in both files', () {
      expect(keys(en).toSet(), keys(vi).toSet());
      expect(keys(en).length, greaterThanOrEqualTo(86));
    });

    test('LG-03: same {placeholders} in en and vi, none empty', () {
      for (final k in keys(en)) {
        expect((en[k] as String).trim(), isNotEmpty, reason: k);
        expect((vi[k] as String).trim(), isNotEmpty, reason: k);
        expect(holes(en[k] as String), holes(vi[k] as String), reason: k);
      }
    });

    test('LG-03 / LG-01: no Vietnamese letters in the English strings', () {
      final vn = RegExp(
        '[ăâđêôơưàáạảãèéẹẻẽìíịỉĩòóọỏõùúụủũỳýỵỷỹ]',
        caseSensitive: false,
      );
      for (final k in keys(en)) {
        if (k.startsWith('@')) continue;
        expect(vn.hasMatch(en[k] as String), isFalse, reason: '$k: ${en[k]}');
      }
    });

    test('LG-03: no ICU braces other than placeholders', () {
      for (final k in keys(vi)) {
        final v = (vi[k] as String).replaceAll(RegExp(r'\{\w+\}'), '');
        expect(v, isNot(contains('{')), reason: k);
        expect(v, isNot(contains('}')), reason: k);
      }
    });
  });

  // ── Notification plumbing that is private ────────────────────────────────

  group('notice plumbing', () {
    final push = read('lib/services/push_notification_service.dart');

    test(
      'NT-16: partner_left cancels 1160 in the background AND the foreground handler',
      () {
        final at = push.indexOf(
          'Future<void> _cancelWeatherNoticeIfPartnerLeft',
        );
        final body = push.substring(at, push.indexOf('\n}\n', at));
        expect(body, contains("message.data['type'] != 'partner_left'"));
        expect(
          body,
          contains('ReminderService.instance.cancelWeatherMorning()'),
        );
        expect(
          '_cancelWeatherNoticeIfPartnerLeft(message)'.allMatches(push).length,
          2,
          reason: 'top-level background handler + foreground listener',
        );
        // The CF side wakes the app (iOS content-available / Android data msg).
        final cf = read('functions/index.js');
        final left = cf.indexOf('exports.notifyPartnerLeft');
        final wake = cf.indexOf('{wakeClients: true}', left);
        expect(wake, greaterThan(cf.indexOf('type: "partner_left"', left)));
      },
    );

    test(
      'NT-13: a payload with an unknown city / cta only scrolls to the card',
      () {
        final home = read('lib/screens/home_screen.dart');
        final at = home.indexOf('void _onWeatherNoticeTap()');
        final body = home.substring(
          at,
          home.indexOf('One "Có gì mới" attempt', at),
        );
        expect(
          body,
          contains(
            'if (city == null || cta == null) {\n        _scrollToCard(_weatherKey);\n        return;',
          ),
        );
        expect(
          body,
          contains('} catch (_) {\n      _scrollToCard(_weatherKey);'),
        );
        // openWeatherCare (the care screen) appears once, behind both guards.
        expect('openWeatherCare('.allMatches(body).length, 1);
        expect(
          body.indexOf('openWeatherCare('),
          greaterThan(body.indexOf('return;')),
        );
      },
    );

    test(
      'NT-18: 1160 is one fixed id and replaces itself (never two pending)',
      () {
        final r = read('lib/services/reminder_service.dart');
        expect('= 1160;'.allMatches(r).length, 1);
        final at = r.indexOf('Future<void> scheduleWeatherMorning(');
        final body = r.substring(at, r.indexOf('\n  }\n', at));
        expect(
          body.indexOf('await cancelWeatherMorning()'),
          lessThan(body.indexOf('zonedSchedule(')),
        );
        // NOT covered: what iOS does when ~64 other notifications are pending.
      },
    );

    test(
      'ST-07: the weather section of Settings only exists inside `if (hasCouple)`',
      () {
        final s = read('lib/screens/settings_screen.dart');
        final open = s.indexOf('if (hasCouple) ...[');
        expect(open, greaterThan(-1));
        var depth = 0;
        var close = -1;
        for (var i = s.indexOf('[', open); i < s.length; i++) {
          if (s[i] == '[') depth++;
          if (s[i] == ']' && --depth == 0) {
            close = i;
            break;
          }
        }
        final inside = s.substring(open, close);
        expect(inside, contains('WeatherSettingsSection('));
        expect(
          s.indexOf('WeatherSettingsSection('),
          s.lastIndexOf('WeatherSettingsSection('),
        );
        expect(inside, contains('coupleProvider.couple!'));
      },
    );

    test('FE-06: the callable has a 15 s client timeout', () {
      final svc = read('lib/services/weather_service.dart');
      expect(svc, contains('_callTimeout = Duration(seconds: 15)'));
      expect(svc, contains('HttpsCallableOptions(timeout: _callTimeout)'));
      // Behaviour on a timeout is in weather_gap_provider_test.dart (FE-06).
    });
  });

  // ── SEC-03 ───────────────────────────────────────────────────────────────

  test(
    'SEC-03: the forecast cache lives in a folder that is not backed up',
    skip:
        'BUG (known debt): `weather_cache` is opened with Hive.openBox on the '
        'default folder, which iCloud / Google backup include; sleep_service / '
        'arrival_service use a *_nobackup folder. The cache holds the two '
        'cities (coarse location).',
    () {
      final svc = read('lib/services/weather_service.dart');
      expect(svc, contains('nobackup'));
    },
  );
}
