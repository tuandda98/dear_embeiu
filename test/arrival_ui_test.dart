import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:dear_embeiu/l10n/app_localizations.dart';
import 'package:dear_embeiu/models/app_user.dart';
import 'package:dear_embeiu/models/arrival.dart';
import 'package:dear_embeiu/models/couple.dart';
import 'package:dear_embeiu/providers/arrival_provider.dart';
import 'package:dear_embeiu/providers/auth_provider.dart';
import 'package:dear_embeiu/providers/couple_provider.dart';
import 'package:dear_embeiu/providers/sleep_provider.dart';
import 'package:dear_embeiu/screens/arrival_place_screen.dart';
import 'package:dear_embeiu/services/arrival_platform.dart';
import 'package:dear_embeiu/services/auth_service.dart';
import 'package:dear_embeiu/services/home_widget_bridge.dart';
import 'package:dear_embeiu/services/home_widget_status.dart';
import 'package:dear_embeiu/services/push_notification_service.dart';
import 'package:dear_embeiu/services/sleep_service.dart';
import 'package:dear_embeiu/theme/app_theme.dart';
import 'package:dear_embeiu/utils/arrival_edge_filter.dart';
import 'package:dear_embeiu/widgets/arrival/arrival_card.dart';
import 'package:dear_embeiu/widgets/person_label.dart';
import 'package:dear_embeiu/widgets/today_constellation.dart';

import 'arrival_test.dart' show FakeArrivalService, FakeGeofence, FakeBattery;

/// Feature arrival, stage 3 (UI): Home card states, the add-place flow,
/// "current location" timeout, delete + undo, push / widget mapping.

final _epoch = DateTime(2026, 1, 1);

/// Stage-1 fake with the Hive half kept in memory (no file IO in
/// `testWidgets`' fake async zone).
class _Service extends FakeArrivalService {
  final places = <String, List<ArrivalPlace>>{};
  final wants = <String, bool>{};

  @override
  Future<List<ArrivalPlace>> loadPlaces(String uid) async =>
      places[uid] ?? const [ArrivalPlace.home()];

  @override
  Future<void> savePlaces(String uid, List<ArrivalPlace> list) async =>
      places[uid] = list;

  @override
  Future<ArrivalEdgeState> loadEdge(String uid, String slot) async =>
      const ArrivalEdgeState();

  @override
  Future<void> saveEdge(String uid, String slot, ArrivalEdgeState s) async {}

  @override
  Future<void> clearEdge(String uid, String slot) async {}

  @override
  Future<bool> loadWantsAuto(String uid) async => wants[uid] ?? false;

  @override
  Future<void> saveWantsAuto(String uid, bool value) async =>
      wants[uid] = value;

  @override
  Future<void> saveSession(String uid, String? coupleId) async {}

  @override
  Future<void> clearSession() async {}
}

class _Search implements PlaceSearch {
  _Search(this.results);
  final List<PlaceSearchResult> results;
  final queries = <String>[];

  @override
  bool get suggestsWhileTyping => true;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<List<PlaceSearchResult>> search(String query) async {
    queries.add(query);
    return results;
  }
}

class _Perms implements ArrivalPermissions {
  _Perms(this.state);
  ArrivalPermissionState state;
  int asked = 0;

  @override
  Future<ArrivalPermissionState> status() async => state;

  @override
  Future<ArrivalPermissionState> requestWhenInUse() async {
    asked++;
    return state;
  }

  @override
  Future<ArrivalPermissionState> requestAlways() async => state;

  @override
  Future<void> openSettings() async {}
}

class _Location implements CurrentLocationReader {
  _Location(this.fix);
  CurrentFix? fix;

  @override
  Future<CurrentFix?> current({
    Duration timeout = const Duration(seconds: 15),
  }) async => fix;
}

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

final _couple = Couple(
  id: 'c1',
  person1Name: 'Thảo',
  person2Name: 'Tuấn',
  anniversaryDate: DateTime(2025, 1, 1),
  inviteCode: 'ABC123',
  memberIds: const ['her', 'me'],
  memberCount: 2,
  createdByUserId: 'her',
  status: 'active',
  createdAt: _epoch,
  updatedAt: _epoch,
);

class _Couples extends CoupleProvider {
  @override
  Couple? get couple => _couple;
}

final _homeAt = ArrivalLocation(
  lat: 21,
  lng: 105.8,
  source: ArrivalLocationSource.address,
  savedAt: DateTime(2026, 10, 1),
  address: 'Ngõ 72 Nguyễn Trãi, Phường Thanh Xuân, Hà Nội',
);

const _gym = ArrivalPlace(slot: 'p1', name: 'Phòng gym', icon: ArrivalIcon.gym);

class _Rig {
  _Rig({
    List<ArrivalPlace>? places,
    bool wantsAuto = false,
    bool always = false,
    List<PlaceSearchResult> results = const [],
    ArrivalPermissionState perm = const ArrivalPermissionState(
      ArrivalPermissionLevel.whenInUse,
    ),
    CurrentFix? fix,
  }) : search = _Search(results),
       perms = _Perms(perm),
       location = _Location(fix) {
    if (places != null) service.places['me'] = places;
    service.wants['me'] = wantsAuto;
    geofence.always = always;
    provider = ArrivalProvider(
      service: service,
      geofence: geofence,
      battery: FakeBattery(64),
      placeSearch: search,
      permissions: perms,
      location: location,
      autoBuildAllowed: true,
    );
  }

  final service = _Service();
  final geofence = FakeGeofence();
  final _Search search;
  final _Perms perms;
  final _Location location;
  late final ArrivalProvider provider;

  Widget app(Widget home) => MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>(create: (_) => _Auth()),
      ChangeNotifierProvider<CoupleProvider>(create: (_) => _Couples()),
      ChangeNotifierProvider<SleepProvider>(
        create: (_) => SleepProvider(service: SleepService()),
      ),
      ChangeNotifierProvider<ArrivalProvider>.value(value: provider),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      locale: const Locale('vi'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    ),
  );

  Future<void> start(WidgetTester tester, Widget home) async {
    await provider.watchForCouple('c1', 'me', 'her');
    await tester.pumpWidget(app(home));
    await tester.pump();
  }

  void share(String uid, ArrivalShare? s) => service.share(uid).add(s);
}

/// A root page with one button that runs [open].
Widget _launcher(void Function(BuildContext) open) => Scaffold(
  body: Builder(
    builder: (c) => Center(
      child: TextButton(onPressed: () => open(c), child: const Text('go')),
    ),
  ),
);

DateTime _today(int h, int m) {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day, h, m);
}

ArrivalEvent _event({
  String place = 'home',
  String? name,
  ArrivalIcon? icon,
  ArrivalEventType type = ArrivalEventType.enter,
  DateTime? at,
  int? battery,
  ArrivalEventSource source = ArrivalEventSource.auto,
}) => ArrivalEvent(
  place: place,
  name: name,
  icon: icon,
  type: type,
  at: at ?? _today(0, 5),
  source: source,
  battery: battery,
);

Widget _card() => Scaffold(
  body: SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: ArrivalCard(couple: _couple),
  ),
);

void main() {
  group('Home card', () {
    testWidgets('nobody on yet: pitch + "Bật báo về nhà" + "Về nhà rồi"', (
      tester,
    ) async {
      final rig = _Rig();
      await rig.start(tester, _card());
      expect(
        find.textContaining('Về đến nhà là máy tự báo cho Thảo'),
        findsOne,
      );
      expect(find.text('Bật báo về nhà'), findsOneWidget);
      expect(find.text('Về nhà rồi'), findsOneWidget);
      expect(find.text('Đến nơi rồi'), findsNothing);
      expect(find.byType(PersonLabel), findsNothing);
    });

    testWidgets('both on: lanes Bạn · Thảo, low battery pill, Hỏi thăm', (
      tester,
    ) async {
      final rig = _Rig(
        places: [
          ArrivalPlace.home(location: _homeAt),
          _gym,
        ],
        wantsAuto: true,
        always: true,
      );
      await rig.start(tester, _card());
      rig.share(
        'me',
        ArrivalShare(
          share: true,
          auto: true,
          last: _event(
            place: 'p1',
            name: 'Công ty',
            icon: ArrivalIcon.work,
            battery: 64,
          ),
        ),
      );
      rig.share(
        'her',
        ArrivalShare(
          share: true,
          auto: true,
          last: _event(battery: 12, at: _today(0, 10)),
        ),
      );
      await tester.pump();
      await tester.pump();

      final labels = tester.widgetList<PersonLabel>(find.byType(PersonLabel));
      expect(labels.map((l) => l.name), ['Bạn', 'Thảo']);
      expect(find.text('Đã đến Công ty'), findsOneWidget);
      expect(find.text('64%'), findsOneWidget);
      expect(find.text('Đã về đến nhà'), findsOneWidget);
      expect(find.text('Pin còn 12%'), findsOneWidget);
      expect(find.text('Hỏi thăm'), findsOneWidget);
      expect(find.text('Tự báo: Nhà'), findsOneWidget);
      // Sharing: no enable button, both manual buttons.
      expect(find.text('Bật báo về nhà'), findsNothing);
      expect(find.text('Đến nơi rồi'), findsOneWidget);
    });

    testWidgets('partner off → neutral; partner on but quiet → "Đang bật"', (
      tester,
    ) async {
      final rig = _Rig();
      await rig.start(tester, _card());
      rig.share('me', const ArrivalShare(share: true));
      rig.share('her', const ArrivalShare(share: false));
      await tester.pump();
      await tester.pump();
      expect(find.text('Chưa bật báo về nhà'), findsOneWidget);
      expect(find.text('Hỏi thăm'), findsNothing);

      rig.share(
        'her',
        ArrivalShare(
          share: true,
          last: _event(at: DateTime.now().subtract(const Duration(days: 5))),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(find.text('Đang bật báo về nhà'), findsOneWidget);
      expect(find.text('Khi Thảo đến nơi, tin sẽ hiện ở đây.'), findsOneWidget);
    });

    testWidgets('offline → "Sẽ báo khi có mạng"', (tester) async {
      final rig = _Rig();
      await rig.start(tester, _card());
      rig.share('me', const ArrivalShare(share: true));
      await tester.pump();
      await tester.pump();
      rig.service.holdWrite = Completer<void>();
      await tester.tap(find.text('Về nhà rồi'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump();
      expect(find.textContaining('Sẽ báo khi có mạng'), findsOneWidget);
      rig.service.holdWrite!.complete();
    });

    testWidgets('failed → "Thử lại" sends again → "Đã báo Thảo"', (
      tester,
    ) async {
      final rig = _Rig();
      await rig.start(tester, _card());
      rig.share('me', const ArrivalShare(share: true));
      await tester.pump();
      await tester.pump();
      rig.service.writeError = StateError('boom');
      await tester.tap(find.text('Về nhà rồi'));
      await tester.pump();
      await tester.pump();
      expect(find.text('Chưa gửi được tin “Về nhà rồi”.'), findsOneWidget);

      rig.service.writeError = null;
      await tester.pumpAndSettle();
      await tester.tap(find.text('Thử lại'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Đã báo Thảo'), findsOneWidget);
      expect(find.textContaining('Chưa gửi được'), findsNothing);
      expect(rig.service.events.map((e) => e.place), ['home', 'home']);
      await tester.pump(const Duration(seconds: 5)); // the 4 s flash ends
      expect(find.text('Đã báo Thảo'), findsNothing);
    });

    testWidgets('"Đến nơi rồi" sheet sends the picked place', (tester) async {
      final rig = _Rig(places: [const ArrivalPlace.home(), _gym]);
      await rig.start(tester, _card());
      rig.share('me', const ArrivalShare(share: true));
      await tester.pump();
      await tester.pump();
      await tester.tap(find.text('Đến nơi rồi'));
      await tester.pumpAndSettle();
      expect(find.text('Bạn vừa đến đâu?'), findsOneWidget);
      await tester.tap(find.text('Phòng gym'));
      await tester.pumpAndSettle();
      expect(rig.service.events.single.place, 'p1');
      expect(rig.service.events.single.name, 'Phòng gym');
      await tester.pump(const Duration(seconds: 5));
    });
  });

  group('add a place', () {
    testWidgets('name + chip → search → confirm (no house no.) → save', (
      tester,
    ) async {
      final rig = _Rig(
        results: const [
          PlaceSearchResult(
            title: 'Liễu Giai',
            subtitle: 'Phường Ngọc Hà, Hà Nội',
            lat: 21.03,
            lng: 105.81,
            hasHouseNumber: false,
          ),
        ],
      );
      await rig.start(tester, _launcher(openArrivalNewPlace));
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();

      expect(find.text('Nơi mới'), findsOneWidget);
      final next = find.byKey(const ValueKey('arrival-continue'));
      ElevatedButton button() => tester.widget<ElevatedButton>(
        find.descendant(of: next, matching: find.byType(ElevatedButton)),
      );
      expect(button().onPressed, isNull);
      await tester.tap(find.text('Phòng gym'));
      await tester.pump();
      expect(
        find.textContaining('Tuấn đã đến Phòng gym', findRichText: true),
        findsOneWidget,
      );
      expect(button().onPressed, isNotNull);
      await tester.tap(next);
      await tester.pumpAndSettle();

      expect(find.text('Phòng gym ở đâu?'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('arrival-search')),
        'Liễu Giai Hà Nội',
      );
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      expect(rig.search.queries, ['Liễu Giai Hà Nội']);
      expect(find.text('Không thấy địa chỉ? Dùng vị trí hiện tại'), findsOne);
      await tester.tap(find.text('Liễu Giai'));
      await tester.pumpAndSettle();

      expect(find.text('Đúng chỗ này chưa?'), findsOneWidget);
      expect(
        find.text(
          'Địa chỉ này chưa có số nhà, app có thể báo hơi sớm hoặc hơi muộn.',
        ),
        findsOneWidget,
      );
      expect(
        find.text('App báo khi bạn vào trong khoảng 250 m quanh đây.'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('arrival-save')));
      await tester.pumpAndSettle();

      expect(find.text('go'), findsOneWidget); // whole flow popped
      expect(find.text('Đã lưu Phòng gym'), findsOneWidget);
      final saved = rig.provider.places.firstWhere((p) => p.slot == 'p1');
      expect(saved.name, 'Phòng gym');
      expect(saved.icon, ArrivalIcon.gym);
      expect(saved.location!.radius, kArrivalRadiusAddress);
      expect(saved.location!.address, 'Liễu Giai, Phường Ngọc Hà, Hà Nội');
    });

    Future<void> confirm(
      WidgetTester tester, {
      required bool houseNo,
      required bool alley,
    }) async {
      final rig = _Rig();
      await rig.start(
        tester,
        ArrivalConfirmScreen(
          draft: _gym,
          location: _homeAt,
          hasHouseNumber: houseNo,
          approximate: alley,
        ),
      );
    }

    const noNumber =
        'Địa chỉ này chưa có số nhà, app có thể báo hơi sớm hoặc hơi muộn.';
    const alleyWarn =
        'Số nhà trong hẻm thường chỉ tìm được tới đầu hẻm, app có thể báo hơi sớm hoặc hơi muộn.';

    testWidgets('confirm: with a house number → no warning', (tester) async {
      await confirm(tester, houseNo: true, alley: false);
      expect(find.text(noNumber), findsNothing);
      expect(find.text(alleyWarn), findsNothing);
    });

    testWidgets('confirm: alley number → alley warning', (tester) async {
      await confirm(tester, houseNo: true, alley: true);
      expect(find.text(alleyWarn), findsOneWidget);
      expect(find.text(noNumber), findsNothing);
    });
  });

  group('current location', () {
    Future<_Rig> open(WidgetTester tester, _Rig rig) async {
      await rig.start(
        tester,
        _launcher(
          (c) => Navigator.of(c).push(
            MaterialPageRoute<void>(
              settings: const RouteSettings(name: 'ArrivalPlace/Current'),
              builder: (_) => const ArrivalCurrentScreen(draft: _gym),
            ),
          ),
        ),
      );
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();
      return rig;
    }

    testWidgets('no fix in time → "Chưa đọc được vị trí", can retry', (
      tester,
    ) async {
      final rig = await open(tester, _Rig());
      await tester.tap(find.byKey(const ValueKey('arrival-read')));
      await tester.pumpAndSettle();
      expect(
        find.text('Chưa đọc được vị trí. Ra chỗ thoáng hơn rồi thử lại nhé.'),
        findsOneWidget,
      );
      rig.location.fix = const CurrentFix(lat: 21, lng: 105, accuracyM: 12);
      await tester.tap(find.byKey(const ValueKey('arrival-read')));
      await tester.pumpAndSettle();
      expect(find.text('Đúng chỗ này chưa?'), findsOneWidget);
      expect(find.text('Vị trí hiện tại của bạn, lệch khoảng 12 m'), findsOne);
      expect(
        find.text('App báo khi bạn vào trong khoảng 150 m quanh đây.'),
        findsOneWidget,
      );
    });

    testWidgets('permission refused → back to search, asked once', (
      tester,
    ) async {
      final rig = await open(
        tester,
        _Rig(perm: const ArrivalPermissionState(ArrivalPermissionLevel.denied)),
      );
      await tester.tap(find.byKey(const ValueKey('arrival-read')));
      await tester.pumpAndSettle();
      expect(find.text('go'), findsOneWidget);
      expect(rig.perms.asked, 1);
    });
  });

  testWidgets('delete a place → "Hoàn tác" brings it back', (tester) async {
    final gym = _gym.withLocation(_homeAt);
    final rig = _Rig(places: [const ArrivalPlace.home(), gym]);
    await rig.start(tester, _launcher((c) => openArrivalEditPlace(c, gym)));
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('arrival-delete')));
    await tester.pumpAndSettle();
    expect(find.text('Xoá Phòng gym?'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('arrival-delete-confirm')));
    await tester.pumpAndSettle();

    expect(rig.provider.customPlaces, isEmpty);
    expect(find.text('Đã xoá Phòng gym'), findsOneWidget);
    await tester.tap(find.text('Hoàn tác'));
    await tester.pumpAndSettle();
    final back = rig.provider.customPlaces.single;
    expect(back.name, 'Phòng gym');
    expect(back.location, isNotNull);
  });

  group('push + widget', () {
    final vi = lookupAppLocalizations(const Locale('vi'));
    final now = DateTime(2026, 10, 20, 19, 0);

    test('push tap "arrival" → Home tab, focus the card', () {
      NotificationTapRouter.consumeHomeFocusRequest();
      PushNotificationService.instance.applyRouteForTest('arrival');
      expect(NotificationTapRouter.pendingHomeTab.value, 0);
      expect(NotificationTapRouter.pendingHomeFocus.value, 'arrival');
      NotificationTapRouter.consumeHomeFocusRequest();
      NotificationTapRouter.consumeHomeTabRequest();
    });

    test('background push → arrival_home / arrival_place, today only', () {
      Map<String, String>? push(Map<String, dynamic> extra) =>
          HomeWidgetStatus.fromPush(
            {'type': 'arrival', 'actorName': 'Thảo', ...extra},
            l10n: vi,
            now: now,
          );
      final home = push({'place': 'home', 'date': '2026-10-20'})!;
      expect(home['statusKind'], 'arrival_home');
      expect(home['statusText'], 'Thảo đã về đến nhà');
      expect(home['statusTextShort'], 'Thảo về nhà rồi');
      expect(home['statusTarget'], 'home');
      expect(home['statusFocus'], 'arrival');
      final gym = push({
        'place': 'p1',
        'placeName': 'Phòng gym',
        'date': '2026-10-20',
      })!;
      expect(gym['statusKind'], 'arrival_place');
      expect(gym['statusText'], 'Thảo đã đến Phòng gym');
      expect(gym['statusTextShort'], 'Thảo tới Phòng gym');
      expect(push({'place': 'home', 'date': '2026-10-19'}), isNull);
    });

    test('app path: partner arrival of today wins; departures never', () {
      Map<String, String> build(ArrivalEvent? e) => HomeWidgetStatus.build(
        today: TodayConstellation.from(
          myUid: 'me',
          now: now,
          questionDay: '2026-10-20',
        ),
        l10n: vi,
        now: now,
        active: true,
        partnerName: 'Thảo',
        questionReady: false,
        partnerArrival: e,
      );
      expect(
        build(_event(at: DateTime(2026, 10, 20, 18, 42)))['statusText'],
        'Thảo đã về đến nhà',
      );
      expect(
        build(
          _event(
            at: DateTime(2026, 10, 20, 18, 42),
            type: ArrivalEventType.exit,
          ),
        )['statusKind'],
        '',
      );
      expect(
        build(_event(at: DateTime(2026, 10, 19, 22, 58)))['statusKind'],
        '',
      );
    });

    test('a widget tap with the arrival focus / kind is accepted', () {
      final launch = HomeWidgetBridge.parseLaunch({
        'family': 'medium',
        'target': 'home',
        'focus': 'arrival',
        'kind': 'arrival_place',
      })!;
      expect(launch.focus, 'arrival');
      expect(launch.kind, 'arrival_place');
    });
  });
}
