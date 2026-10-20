import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:dear_embeiu/l10n/app_localizations.dart';
import 'package:dear_embeiu/models/app_user.dart';
import 'package:dear_embeiu/models/couple.dart';
import 'package:dear_embeiu/models/mood.dart';
import 'package:dear_embeiu/providers/auth_provider.dart';
import 'package:dear_embeiu/providers/mood_provider.dart';
import 'package:dear_embeiu/providers/sleep_provider.dart';
import 'package:dear_embeiu/services/auth_service.dart';
import 'package:dear_embeiu/services/mood_service.dart';
import 'package:dear_embeiu/services/sleep_service.dart';
import 'package:dear_embeiu/theme/app_theme.dart';
import 'package:dear_embeiu/widgets/mood_card.dart';
import 'package:dear_embeiu/widgets/person_label.dart';

/// Home C (home/design.md §15): before sharing, the big "Chia sẻ tâm trạng"
/// button; after, it folds into a "Đổi" text button on the header row. Lanes
/// use PersonLabel, you on the left.

final _epoch = DateTime(2026, 1, 1);

class _Auth extends AuthProvider {
  _Auth() : super(authService: AuthService());

  @override
  AppUser? get currentUser => AppUser(
    id: 'me',
    email: 'me@test.dev',
    displayName: 'Tuấn',
    inviteCode: 'ABC123',
    status: 'in_couple',
    createdAt: _epoch,
    updatedAt: _epoch,
  );
}

class _Moods extends MoodService {
  final moods = StreamController<Map<String, Mood>>.broadcast();

  @override
  bool get isUsingFirebase => true;

  @override
  Stream<Map<String, Mood>> watchMoods(String coupleId) => moods.stream;
}

final _couple = Couple(
  id: 'c1',
  person1Name: 'Thảo',
  person2Name: 'Tuấn',
  anniversaryDate: DateTime(2025, 1, 1),
  inviteCode: 'ABC123',
  memberIds: const ['other', 'me'],
  memberCount: 2,
  createdByUserId: 'other',
  status: 'active',
  createdAt: _epoch,
  updatedAt: _epoch,
);

Future<_Moods> _pump(WidgetTester tester) async {
  final service = _Moods();
  final mood = MoodProvider(service: service)..watchForCouple('c1', 'me');
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(create: (_) => _Auth()),
        ChangeNotifierProvider<MoodProvider>.value(value: mood),
        ChangeNotifierProvider<SleepProvider>(
          create: (_) => SleepProvider(service: SleepService()),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        locale: const Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: MoodCard(couple: _couple)),
      ),
    ),
  );
  return service;
}

void main() {
  testWidgets('not shared: big share button, no "Đổi"', (tester) async {
    final service = await _pump(tester);
    service.moods.add({});
    await tester.pump();

    expect(find.text('Chia sẻ tâm trạng'), findsOneWidget);
    expect(find.text('Đổi'), findsNothing);
    // Lanes: you left, partner right, both as PersonLabel.
    final labels = tester.widgetList<PersonLabel>(find.byType(PersonLabel));
    expect(labels.map((l) => l.name), ['Bạn', 'Thảo']);
  });

  testWidgets('shared: "Đổi" on the header row, big button gone', (
    tester,
  ) async {
    final service = await _pump(tester);
    service.moods.add({
      'me': Mood(
        authorUserId: 'me',
        mood: 'happy',
        note: '',
        date: MoodProvider.todayKey(),
      ),
    });
    await tester.pump();

    expect(find.text('Đổi'), findsOneWidget);
    expect(find.text('Chia sẻ tâm trạng'), findsNothing);
    expect(find.text('Đổi tâm trạng'), findsNothing);
    final size = tester.getSize(
      find.ancestor(of: find.text('Đổi'), matching: find.byType(InkWell)),
    );
    expect(size.height, greaterThanOrEqualTo(44));
  });
}
