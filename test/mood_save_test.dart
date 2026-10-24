import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:dear_embeiu/l10n/app_localizations.dart';
import 'package:dear_embeiu/models/mood.dart';
import 'package:dear_embeiu/providers/mood_provider.dart';
import 'package:dear_embeiu/services/mood_service.dart';
import 'package:dear_embeiu/theme/app_theme.dart';
import 'package:dear_embeiu/widgets/mood_card.dart';

/// Saving today's mood (audit 2026-10-12): SU9 — the picker never waits for
/// the server; SU10 — the note is cut on whole characters within the rule.

/// Firestore stand-in: every write runs [write] (hang = offline, throw =
/// rejected by the rules).
class _Service extends MoodService {
  _Service(this.write);

  Future<void> Function() write;
  int writes = 0;
  final _moods = StreamController<Map<String, Mood>>.broadcast();

  @override
  bool get isUsingFirebase => true;

  @override
  Stream<Map<String, Mood>> watchMoods(String coupleId) => _moods.stream;

  @override
  Future<void> setMood({
    required String coupleId,
    required String uid,
    required String mood,
    required String note,
    required String dateKey,
  }) {
    writes++;
    return write();
  }
}

MoodProvider _provider(_Service service) =>
    MoodProvider(service: service)..watchForCouple('c1', 'me');

Widget _app(MoodProvider mood, {TargetPlatform? platform}) =>
    ChangeNotifierProvider<MoodProvider>.value(
  value: mood,
  child: MaterialApp(
    theme: AppTheme.lightTheme.copyWith(platform: platform),
    locale: const Locale('vi'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Builder(
        builder: (c) => Center(
          child: TextButton(
            onPressed: () => showMoodPicker(c),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  ),
);

Future<void> _pickAndSave(WidgetTester tester, {bool twice = false}) async {
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Vui'));
  await tester.pump();
  final save = find.text('Lưu tâm trạng');
  await tester.tap(save);
  if (twice) {
    await tester.tap(save, warnIfMissed: false);
  }
  await tester.pumpAndSettle();
}

void main() {
  group('SU10: MoodService.fitNote', () {
    test('short notes stay as they are', () {
      expect(MoodService.fitNote('Hôm nay vui ghê 😄'), 'Hôm nay vui ghê 😄');
      final hundred = 'a' * kMoodNoteMaxLength;
      expect(MoodService.fitNote(hundred), hundred);
    });

    test('keeps whole emoji within the rule\'s 100 UTF-16 units', () {
      // Each 😀 is 2 units: 60 of them = 120 → 50 fit.
      final cut = MoodService.fitNote('😀' * 60);
      expect(cut, '😀' * 50);

      // An odd budget never leaves half an emoji ("�").
      final odd = MoodService.fitNote('a${'😀' * 60}');
      expect(odd, 'a${'😀' * 49}');
      expect(odd.length, lessThanOrEqualTo(kMoodNoteMaxLength));

      // A family emoji (11 units) is kept whole or dropped whole.
      const family = '👨‍👩‍👧‍👦';
      final fam = MoodService.fitNote('${'x' * 95}$family');
      expect(fam, 'x' * 95);
    });

    test('Vietnamese text cuts at 100 letters', () {
      final text = 'Nhớ người ấy ghê ' * 10;
      expect(MoodService.fitNote(text), text.substring(0, kMoodNoteMaxLength));
    });
  });

  group('SU9: saving never waits for the server', () {
    testWidgets('offline: the picker closes at once, my card shows the pick', (
      tester,
    ) async {
      final service = _Service(() => Completer<void>().future); // hangs
      final mood = _provider(service);
      await tester.pumpWidget(_app(mood));

      await _pickAndSave(tester, twice: true);

      expect(find.text('Hôm nay bạn thế nào?'), findsNothing);
      expect(mood.myMood?.mood, 'happy');
      expect(service.writes, 1, reason: 'a second tap queued no write');
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('rejected: the pick rolls back and a SnackBar says so', (
      tester,
    ) async {
      final service = _Service(
        () async => throw Exception('permission-denied'),
      );
      final mood = _provider(service);
      await tester.pumpWidget(_app(mood));

      await _pickAndSave(tester);

      expect(find.text('Hôm nay bạn thế nào?'), findsNothing);
      expect(mood.myMood, isNull);
      expect(find.text('Chưa lưu được tâm trạng, thử lại nhé'), findsOneWidget);
    });

    testWidgets('the note field stops where the save would cut', (
      tester,
    ) async {
      final mood = _provider(_Service(() async {}));
      await tester.pumpWidget(_app(mood));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '😀' * 60);
      final text = tester
          .widget<TextField>(find.byType(TextField))
          .controller!
          .text;
      expect(text, '😀' * 50);
    });
  });

  // Vòng 8 N3: typing or pasting into a note at the limit cut the END of the
  // note already there and threw the cursor to the end.
  group('N3: only the new text is cut, the cursor stays after it', () {
    for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
      /// Opens the picker, focuses the note; the returned function plays the
      /// keyboard: sends a value, returns what the field kept.
      Future<Future<TextEditingValue> Function(TextEditingValue)> open(
        WidgetTester tester,
      ) async {
        final mood = _provider(_Service(() async {}));
        await tester.pumpWidget(_app(mood, platform: platform));
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(TextField));
        await tester.pump();
        return (value) async {
          tester.testTextInput.updateEditingValue(value);
          await tester.pump();
          return tester
              .widget<TextField>(find.byType(TextField))
              .controller!
              .value;
        };
      }

      TextEditingValue at(String text, int cursor, {TextRange? composing}) =>
          TextEditingValue(
            text: text,
            selection: TextSelection.collapsed(offset: cursor),
            composing: composing ?? TextRange.empty,
          );

      /// [note] with [insert] typed / pasted at [cursor].
      TextEditingValue insert(String note, int cursor, String insert) => at(
        note.replaceRange(cursor, cursor, insert),
        cursor + insert.length,
      );

      testWidgets('$platform: a full note refuses text at the start, in the '
          'middle and at the end', (tester) async {
        final send = await open(tester);
        final full = '${'b' * 97}XYZ';
        for (final cursor in [0, 40, 100]) {
          await send(at(full, cursor));
          final v = await send(insert(full, cursor, 'hi'));
          expect(v.text, full, reason: 'cursor $cursor');
          expect(v.selection, TextSelection.collapsed(offset: cursor));
        }
      });

      testWidgets('$platform: a paste keeps what fits, the note stays whole', (
        tester,
      ) async {
        final send = await open(tester);
        final note = '${'a' * 45}${'c' * 50}'; // 95: room for 5
        for (final cursor in [0, 45, 95]) {
          await send(at(note, cursor));
          final v = await send(insert(note, cursor, '12345678'));
          expect(
            v.text,
            note.replaceRange(cursor, cursor, '12345'),
            reason: 'cursor $cursor',
          );
          expect(v.selection, TextSelection.collapsed(offset: cursor + 5));
        }
      });

      testWidgets('$platform: emoji and ZWJ families stay whole', (
        tester,
      ) async {
        final send = await open(tester);
        const family = '👨‍👩‍👧‍👦'; // 11 units, one character
        final note = 'd' * 87; // room for 13: 😀 (2) + the family (11)
        await send(at(note, 40));
        var v = await send(insert(note, 40, '😀$family😀'));
        expect(v.text, note.replaceRange(40, 40, '😀$family'));
        expect(v.selection, const TextSelection.collapsed(offset: 53));

        // One unit left: a 2-unit emoji is refused, never split.
        final ninetyNine = 'e' * 99;
        await send(at(ninetyNine, 10));
        v = await send(insert(ninetyNine, 10, '😀'));
        expect(v.text, ninetyNine);
        expect(v.selection, const TextSelection.collapsed(offset: 10));
      });

      testWidgets('$platform: Telex in the middle is cut once the word is '
          'done', (tester) async {
        final send = await open(tester);
        final note = '${'a' * 48}${'z' * 50}'; // 98: room for 2
        await send(at(note, 48));
        // Composing "tiế" past the limit is left alone…
        final composing = await send(
          at(
            note.replaceRange(48, 48, 'tiế'),
            51,
            composing: const TextRange(start: 48, end: 51),
          ),
        );
        expect(composing.text.length, lessThanOrEqualTo(101));
        // …then "tiế " is committed: "ti" fits, the note's end stays.
        final v = await send(at(note.replaceRange(48, 48, 'tiế '), 52));
        expect(v.text, note.replaceRange(48, 48, 'ti'));
        expect(v.selection, const TextSelection.collapsed(offset: 50));
      });

      // A glide-typed word arrives whole, still composing (Android's default
      // limit cut the note's end right there).
      final note = '${'a' * 45}${'c' * 50}'; // 95: room for 5
      TextEditingValue gliding() => at(
        note.replaceRange(45, 45, 'hellowor'),
        53,
        composing: const TextRange(start: 45, end: 53),
      );

      testWidgets('$platform: a glided word in the middle is cut when done', (
        tester,
      ) async {
        final send = await open(tester);
        await send(at(note, 45));
        expect((await send(gliding())).text, gliding().text);
        final v = await send(at(note.replaceRange(45, 45, 'hellowor '), 54));
        expect(v.text, note.replaceRange(45, 45, 'hello'));
        expect(v.selection, const TextSelection.collapsed(offset: 50));
      });

      testWidgets('$platform: saved mid-word, the word is cut, not the note\'s '
          'end', (tester) async {
        final mood = _provider(_Service(() async {}));
        await tester.pumpWidget(_app(mood, platform: platform));
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(TextField));
        await tester.pump();
        tester.testTextInput.updateEditingValue(at(note, 45));
        await tester.pump();
        tester.testTextInput.updateEditingValue(gliding());
        await tester.pump();
        await tester.tap(find.text('Vui'));
        await tester.pump();
        await tester.tap(find.text('Lưu tâm trạng'));
        await tester.pumpAndSettle();
        expect(mood.myMood?.note, note.replaceRange(45, 45, 'hello'));
      });

      // Vòng 9 N3b: the Tester's 15 cases. Tapping into a word, Gboard marks
      // it as composing; typing in it at the limit cut the word's last letter
      // ("hello" + "x" → "hellx", "a" before "nhớ" → "anh").
      testWidgets('$platform: N3b — a word re-composed at the limit stays '
          'whole (15 cases)', (tester) async {
        final send = await open(tester);
        TextEditingValue composing(String text, int cursor, int from, int to) =>
            at(
              text,
              cursor,
              composing: TextRange(start: from, end: to),
            );
        final full = '${'b' * 97}XYZ';
        const family = '👨‍👩‍👧‍👦';
        final d87 = 'd' * 87;
        final n98 = '${'a' * 48}${'z' * 50}';
        final m98 = 'n' * 98;
        final m97 = 'm' * 97;
        final hello = '${'p' * 40}hello${'q' * 55}'; // 100
        final nho = '${'p' * 40}nhớ ${'q' * 56}'; // 100
        final mid = '${'A' * 48}${'Z' * 50}';
        final room = '${'p' * 40}hello${'q' * 50}'; // 95
        // (name, start, keyboard steps, text kept, cursor)
        final cases =
            <(String, TextEditingValue, List<TextEditingValue>, String, int)>[
              for (final c in [0, 40, 100])
                (
                  'full refuses @$c',
                  at(full, c),
                  [insert(full, c, 'hi')],
                  full,
                  c,
                ),
              for (final c in [0, 45, 95])
                (
                  'paste keeps 5 @$c',
                  at(note, c),
                  [insert(note, c, '12345678')],
                  note.replaceRange(c, c, '12345'),
                  c + 5,
                ),
              (
                'emoji + family',
                at(d87, 40),
                [insert(d87, 40, '😀$family😀')],
                d87.replaceRange(40, 40, '😀$family'),
                53,
              ),
              (
                'telex middle',
                at(n98, 48),
                [
                  composing(n98.replaceRange(48, 48, 'tiế'), 51, 48, 51),
                  at(n98.replaceRange(48, 48, 'tiế '), 52),
                ],
                n98.replaceRange(48, 48, 'ti'),
                50,
              ),
              (
                'glide middle',
                at(note, 45),
                [gliding(), at(note.replaceRange(45, 45, 'hellowor '), 54)],
                note.replaceRange(45, 45, 'hello'),
                50,
              ),
              (
                'telex end',
                at(m98, 98),
                [
                  for (final w in ['t', 'ti', 'tiê', 'tiế', 'tiến', 'tiếng'])
                    composing(m98 + w, 98 + w.length, 98, 98 + w.length),
                  at('${m98}tiếng ', 104),
                ],
                '${m98}ti',
                100,
              ),
              (
                'telex start',
                at(m97, 0),
                [
                  for (final w in ['d', 'dd', 'đư', 'đươ', 'được'])
                    composing(w + m97, w.length, 0, w.length),
                  at('được $m97', 5),
                ],
                'đượ$m97',
                3,
              ),
              (
                're-composed "hello", "x" typed before its "o"',
                at(hello, 44),
                [
                  composing(hello, 44, 40, 45),
                  composing(hello.replaceRange(40, 45, 'hellxo'), 45, 40, 46),
                  at(hello.replaceRange(40, 45, 'hellxo'), 45),
                ],
                hello,
                44,
              ),
              (
                're-composed "nhớ", "a" typed in front',
                at(nho, 40),
                [
                  composing(nho, 40, 40, 43),
                  composing(nho.replaceRange(40, 43, 'anhớ'), 41, 40, 44),
                  at(nho.replaceRange(40, 43, 'anhớ'), 41),
                ],
                nho,
                40,
              ),
              (
                'cursor at the start of the composing word',
                at(mid, 48),
                [
                  composing(mid.replaceRange(48, 48, 'được'), 48, 48, 52),
                  at(mid.replaceRange(48, 48, 'được'), 48),
                ],
                mid.replaceRange(48, 48, 'đư'),
                50,
              ),
              (
                're-composed with room left: nothing cut',
                at(room, 44),
                [
                  composing(room, 44, 40, 45),
                  composing(room.replaceRange(40, 45, 'hellxo'), 45, 40, 46),
                  at(room.replaceRange(40, 45, 'hellxo'), 45),
                ],
                room.replaceRange(40, 45, 'hellxo'),
                45,
              ),
            ];
        expect(cases, hasLength(15));
        for (final (name, start, steps, text, cursor) in cases) {
          var v = await send(start);
          for (final step in steps) {
            v = await send(step);
          }
          expect(v.text, text, reason: name);
          expect(
            v.selection,
            TextSelection.collapsed(offset: cursor),
            reason: name,
          );
        }
      });
    }
  });
}
