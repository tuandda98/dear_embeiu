import 'package:flutter/material.dart' show Locale;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dear_embeiu/l10n/app_localizations.dart';
import 'package:dear_embeiu/models/chat_message.dart';
import 'package:dear_embeiu/models/daily_answer.dart';
import 'package:dear_embeiu/models/mood.dart';
import 'package:dear_embeiu/models/photo.dart';
import 'package:dear_embeiu/services/home_widget_bridge.dart';
import 'package:dear_embeiu/services/home_widget_status.dart';
import 'package:dear_embeiu/services/push_notification_service.dart';
import 'package:dear_embeiu/widgets/today_constellation.dart';

/// Feature widget-today: the "hôm nay" line from live providers (D3/D4/D5a),
/// from a background push (D5b/D9) and back from a widget tap (D7).
void main() {
  final vi = lookupAppLocalizations(const Locale('vi'));
  final en = lookupAppLocalizations(const Locale('en'));
  final now = DateTime(2026, 10, 19, 15, 0);
  DateTime at(int h, [int m = 0]) => DateTime(2026, 10, 19, h, m);

  TodayConstellation today({
    DailyAnswer? mine,
    DailyAnswer? theirs,
    Mood? theirMood,
    List<ChatMessage> messages = const [],
    String questionDay = '2026-10-19',
  }) =>
      TodayConstellation.from(
        myUid: 'me',
        now: now,
        questionDay: questionDay,
        myAnswer: mine,
        partnerAnswer: theirs,
        partnerMood: theirMood,
        messages: messages,
      );

  Map<String, String> build(
    TodayConstellation t, {
    AppLocalizations? l10n,
    bool active = true,
    bool questionReady = true,
    String partnerName = 'Thảo',
    DateTime? photoAt,
    WidgetDecision? decision,
  }) =>
      HomeWidgetStatus.build(
        today: t,
        l10n: l10n ?? vi,
        now: now,
        active: active,
        partnerName: partnerName,
        questionReady: questionReady,
        partnerPhotoAt: photoAt,
        decision: decision,
      );

  final theirAnswer =
      DailyAnswer(authorUserId: 'other', text: 'a', answeredAt: at(9));
  final myAnswer = DailyAnswer(authorUserId: 'me', text: 'b', answeredAt: at(10));

  group('build (app open)', () {
    test('nothing yet, question loaded → "đang chờ mình"', () {
      final s = build(today());
      expect(s['statusKind'], 'question_mine');
      expect(s['statusText'], 'Câu hỏi hôm nay đang chờ mình');
      expect(s['statusTextShort'], 'Câu hỏi đang chờ mình');
      expect(s['todayDate'], '2026-10-19');
      expect(s['statusTarget'], 'home');
      expect(s['statusFocus'], 'daily_question');
    });

    test('question not loaded / yesterday\'s answers → no line', () {
      expect(build(today(), questionReady: false)['statusKind'], '');
      // Yesterday's answers in the provider light nothing today.
      expect(
        build(today(theirs: theirAnswer, questionDay: '2026-10-18'),
                questionReady: false)['statusKind'],
        '',
      );
    });

    test('partner answered, I did not → their turn line', () {
      final s = build(today(theirs: theirAnswer));
      expect(s['statusKind'], 'question_partner');
      expect(s['statusText'], 'Thảo đã trả lời, đến lượt mình');
      expect(s['statusTextShort'], 'Thảo đã trả lời');
      expect(s['statusAt'], '${at(9).millisecondsSinceEpoch}');
    });

    test('I answered, partner not → never "người ấy chưa…" (D4.2)', () {
      expect(build(today(mine: myAnswer))['statusKind'], '');
    });

    test('both answered → question_both at the later answer', () {
      final s = build(today(mine: myAnswer, theirs: theirAnswer));
      expect(s['statusKind'], 'question_both');
      expect(s['statusText'], 'Cả hai đã trả lời hôm nay');
      expect(s['statusAt'], '${at(10).millisecondsSinceEpoch}');
    });

    test('newest wins across kinds (D3)', () {
      final t = today(
        theirs: theirAnswer, // 9:00
        theirMood: Mood(
            authorUserId: 'other',
            mood: 'stressed',
            note: '',
            date: '2026-10-19',
            updatedAt: at(11)),
        messages: [
          ChatMessage(authorUserId: 'other', text: 'hi', createdAt: at(12)),
          ChatMessage(authorUserId: 'me', text: 'yo', createdAt: at(14)),
        ],
      );
      expect(build(t)['statusKind'], 'message'); // 12:00; my 14:00 msg is not about them
      final s = build(t, photoAt: at(13));
      expect(s['statusKind'], 'photo');
      expect(s['statusText'], 'Thảo vừa đăng ảnh mới');
      expect(s['statusTarget'], 'gallery');
      final d = build(t,
          photoAt: at(13),
          decision: WidgetDecision(kind: 'eat', result: 'Bún chả', at: at(14)));
      expect(d['statusKind'], 'decision_eat');
      expect(d['statusText'], 'Hôm nay ăn: Bún chả');
      expect(d['statusTextShort'], 'Ăn: Bún chả');
      expect(d['statusFocus'], 'decision');
    });

    test('mood line: lower-case label, both languages, focus mood', () {
      final t = today(
        theirMood: Mood(
            authorUserId: 'other',
            mood: 'stressed',
            note: '',
            date: '2026-10-19',
            updatedAt: at(11)),
      );
      final s = build(t);
      expect(s['statusText'], 'Thảo hôm nay: căng thẳng');
      expect(s['statusTextShort'], 'Thảo: căng thẳng');
      expect(s['statusFocus'], 'mood');
      expect(build(t, l10n: en)['statusText'], 'Thảo today: stressed');
    });

    test('a real event beats "đang chờ mình" — message → Chat', () {
      final s = build(today(messages: [
        ChatMessage(authorUserId: 'other', text: 'hi', createdAt: at(8)),
      ]));
      expect(s['statusKind'], 'message');
      expect(s['statusText'], 'Thảo vừa nhắn cho mình');
      expect(s['statusTarget'], 'chat');
    });

    test('waiting for the partner → no line; empty name → fallback', () {
      expect(build(today(theirs: theirAnswer), active: false)['statusKind'], '');
      expect(
        build(today(theirs: theirAnswer), partnerName: ' ', l10n: en)['statusText'],
        'Your partner answered — your turn',
      );
    });

    test('a photo of yesterday or my own photo does not count', () {
      final photos = [
        Photo(id: '1', path: '', authorUserId: 'me', uploadDate: at(14)),
        Photo(
            id: '2',
            path: '',
            authorUserId: 'other',
            uploadDate: DateTime(2026, 10, 18, 23)),
      ];
      expect(HomeWidgetStatus.latestPartnerPhotoAt(photos, 'me', now), isNull);
      photos.add(Photo(id: '3', path: '', authorUserId: 'other', uploadDate: at(7)));
      expect(HomeWidgetStatus.latestPartnerPhotoAt(photos, 'me', now), at(7));
    });
  });

  group('fromPush (app in the background)', () {
    Map<String, String>? push(Map<String, dynamic> data,
            {AppLocalizations? l10n, DateTime? sentAt}) =>
        HomeWidgetStatus.fromPush(data,
            l10n: l10n ?? vi, now: now, sentAt: sentAt ?? at(14, 59));

    test('the 9 kinds map to the D2 copy', () {
      final cases = <Map<String, dynamic>, (String, String, String)>{
        {'type': 'daily_question', 'bothAnswered': 'false', 'actorName': 'Thảo', 'date': '2026-10-19'}:
            ('question_partner', 'Thảo đã trả lời, đến lượt mình', 'Thảo đã trả lời'),
        {'type': 'daily_question', 'bothAnswered': 'true', 'actorName': 'Thảo', 'date': '2026-10-19'}:
            ('question_both', 'Cả hai đã trả lời hôm nay', 'Cả hai đã trả lời'),
        {'type': 'partner_mood', 'mood': 'happy', 'actorName': 'Thảo', 'date': '2026-10-19'}:
            ('mood', 'Thảo hôm nay: vui', 'Thảo: vui'),
        {'type': 'chat_message', 'actorName': 'Thảo'}:
            ('message', 'Thảo vừa nhắn cho mình', 'Thảo vừa nhắn'),
        {'type': 'photo_posted', 'actorName': 'Thảo', 'photoId': 'p'}:
            ('photo', 'Thảo vừa đăng ảnh mới', 'Thảo đăng ảnh mới'),
        {'type': 'decision', 'kind': 'eat', 'result': 'Phở', 'date': '2026-10-19'}:
            ('decision_eat', 'Hôm nay ăn: Phở', 'Ăn: Phở'),
        {'type': 'decision', 'kind': 'go', 'result': 'Đi cà phê', 'date': '2026-10-19'}:
            ('decision_go', 'Hôm nay: Đi cà phê', 'Đi cà phê'),
        {'type': 'decision', 'kind': 'custom', 'question': 'Ai rửa bát?', 'result': 'Anh', 'date': '2026-10-19'}:
            ('decision_custom', 'Ai rửa bát?: Anh', 'Quay ra: Anh'),
      };
      for (final e in cases.entries) {
        final s = push(e.key)!;
        expect(s['statusKind'], e.value.$1, reason: '${e.key}');
        expect(s['statusText'], e.value.$2);
        expect(s['statusTextShort'], e.value.$3);
        expect(s['onlyIfNewer'], '1');
        expect(s['statusAt'], '${at(14, 59).millisecondsSinceEpoch}');
      }
      // question_mine is about me — only the app can know it, never a push.
    });

    test('a push about another day is ignored (D9)', () {
      expect(push({'type': 'daily_question', 'bothAnswered': 'true', 'date': '2026-10-18'}), isNull);
      expect(push({'type': 'partner_mood', 'mood': 'sad', 'date': '2026-10-18'}), isNull);
      // No date key (chat/photo): sent yesterday, delivered today.
      expect(push({'type': 'chat_message'}, sentAt: DateTime(2026, 10, 18, 23, 50)), isNull);
    });

    test('other types, unknown mood, empty decision → null', () {
      expect(push({'type': 'care_message'}), isNull);
      expect(push({'type': 'partner_joined'}), isNull);
      expect(push({'type': 'partner_mood', 'mood': 'weird', 'date': '2026-10-19'}), isNull);
      expect(push({'type': 'decision', 'kind': 'eat', 'result': ' ', 'date': '2026-10-19'}), isNull);
      expect(push({'type': 'decision', 'kind': 'fly', 'result': 'x', 'date': '2026-10-19'}), isNull);
    });

    test('name fallback + language from data.lang, else the phone', () {
      final data = {'type': 'chat_message', 'actorName': '', 'lang': 'en'};
      final lang = HomeWidgetStatus.pushLang(data, 'vi_VN');
      expect(lang, 'en');
      expect(push(data, l10n: lookupAppLocalizations(Locale(lang)))!['statusText'],
          'Your partner just messaged you');
      expect(HomeWidgetStatus.pushLang({}, 'vi_VN'), 'vi');
      expect(HomeWidgetStatus.pushLang({'lang': 'fr'}, 'en_US'), 'en');
      expect(push({'type': 'chat_message'})!['statusText'], 'Người ấy vừa nhắn cho mình');
    });
  });

  group('widget tap (D7)', () {
    test('parseLaunch whitelists every value', () {
      expect(HomeWidgetBridge.parseLaunch(null), isNull);
      expect(HomeWidgetBridge.parseLaunch({'family': 'huge'}), isNull);
      expect(HomeWidgetBridge.parseLaunch('small')!.family, 'small'); // 1.9.x native
      final l = HomeWidgetBridge.parseLaunch(
          {'family': 'medium', 'target': 'home', 'focus': 'mood', 'kind': 'mood'})!;
      expect((l.target, l.focus, l.kind), ('home', 'mood', 'mood'));
      final bad = HomeWidgetBridge.parseLaunch(
          {'family': 'small', 'target': 'settings', 'focus': 'x', 'kind': 'y'})!;
      expect((bad.target, bad.focus, bad.kind), ('', '', ''));
      final odd = HomeWidgetBridge.parseLaunch(
          {'family': 'small', 'target': 'chat', 'focus': '../x', 'kind': 'hack'})!;
      expect((odd.target, odd.focus, odd.kind), ('chat', '', ''));
    });

    testWidgets('consumeLaunch routes the tap like a push tap', (tester) async {
      const channel = MethodChannel('dear_embeiu/widget');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'consumeLaunch') {
          return {'family': 'small', 'target': 'chat', 'focus': '', 'kind': 'message'};
        }
        return null;
      });
      NotificationTapRouter.consumeHomeTabRequest();
      await HomeWidgetBridge.consumeLaunch();
      expect(NotificationTapRouter.pendingHomeTab.value, 1);
      NotificationTapRouter.consumeHomeTabRequest();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async =>
              {'family': 'medium', 'target': 'home', 'focus': 'daily_question', 'kind': 'question_partner'});
      await HomeWidgetBridge.consumeLaunch();
      expect(NotificationTapRouter.pendingHomeTab.value, 0);
      expect(NotificationTapRouter.pendingHomeFocus.value, 'daily_question');
      NotificationTapRouter.consumeHomeTabRequest();
      NotificationTapRouter.consumeHomeFocusRequest();
    });
  });

  testWidgets('pushStatus: last of a burst, an unchanged line is not re-sent',
      (tester) async {
    const channel = MethodChannel('dear_embeiu/widget');
    final sent = <Map<String, String>>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'updateStatus') {
        sent.add(Map<String, String>.from(call.arguments as Map));
      }
      return null;
    });
    HomeWidgetBridge.resetForTest();
    final a = HomeWidgetStatus.none(now);
    final b = {...a, 'statusKind': 'message', 'statusText': 'x'};
    HomeWidgetBridge.pushStatus(a);
    HomeWidgetBridge.pushStatus(b);
    await tester.pump(HomeWidgetBridge.statusDebounce);
    expect(sent, [b]);
    HomeWidgetBridge.pushStatus({...b});
    await tester.pump(HomeWidgetBridge.statusDebounce);
    expect(sent.length, 1);
    HomeWidgetBridge.pushStatus(a);
    await tester.pump(HomeWidgetBridge.statusDebounce);
    expect(sent.last, a);
  });
}
