import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart' show FirebaseException;
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
import 'package:dear_embeiu/screens/arrival_manage_screen.dart';
import 'package:dear_embeiu/screens/arrival_place_screen.dart';
import 'package:dear_embeiu/screens/arrival_setup_screen.dart';
import 'package:dear_embeiu/services/arrival_service.dart';
import 'package:dear_embeiu/widgets/arrival/arrival_format.dart';
import 'package:dear_embeiu/widgets/arrival/arrival_settings_tiles.dart';
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
  List<PlaceSearchResult> results;
  final queries = <String>[];
  bool typing = true;
  bool available = true;
  Object? error;

  @override
  bool get suggestsWhileTyping => typing;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<List<PlaceSearchResult>> search(String query) async {
    queries.add(query);
    if (error != null) throw error!;
    return results;
  }
}

class _Perms implements ArrivalPermissions {
  _Perms(this.state);
  ArrivalPermissionState state;
  int asked = 0;
  bool throwOnRequest = false;

  @override
  Future<ArrivalPermissionState> status() async => state;

  @override
  Future<ArrivalPermissionState> requestWhenInUse() async {
    asked++;
    if (throwOnRequest) throw StateError('plugin');
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

  double textScale = 1;
  bool reduceMotion = false;

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
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          disableAnimations: reduceMotion,
        ),
        child: child!,
      ),
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
    await tester.pump(const Duration(seconds: 7)); // hold timer ends
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

  // ── Review round (Lead 2026-10-20) ────────────────────────────────────────

  group('card feedback', () {
    testWidgets('queued strip goes once the server acks the event', (
      tester,
    ) async {
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

      final mine = _event(
        at: DateTime.now(),
        source: ArrivalEventSource.manual,
      );
      // Local echo, not acked yet → still queued.
      rig.share('me', ArrivalShare(share: true, last: mine, pending: true));
      await tester.pump();
      await tester.pump();
      expect(find.textContaining('Sẽ báo khi có mạng'), findsOneWidget);
      rig.share('me', ArrivalShare(share: true, last: mine));
      await tester.pump();
      await tester.pumpAndSettle();
      expect(find.textContaining('Sẽ báo khi có mạng'), findsNothing);
      expect(rig.provider.lastResult, isNull);
      rig.service.holdWrite!.complete();
    });

    testWidgets('permission-denied → error strip + "Thử lại"', (tester) async {
      final rig = _Rig();
      await rig.start(tester, _card());
      rig.share('me', const ArrivalShare(share: true));
      await tester.pump();
      await tester.pump();
      rig.service.writeError = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
      );
      await tester.tap(find.text('Về nhà rồi'));
      await tester.pump();
      await tester.pumpAndSettle();
      expect(rig.provider.lastResult, ArrivalSendResult.denied);
      expect(find.text('Chưa gửi được tin “Về nhà rồi”.'), findsOneWidget);
      expect(find.text('Thử lại'), findsOneWidget);
    });

    testWidgets('dropped (place gone) → SnackBar, never silent', (
      tester,
    ) async {
      final rig = _Rig(places: [const ArrivalPlace.home(), _gym]);
      await rig.start(tester, _card());
      rig.share('me', const ArrivalShare(share: true));
      await tester.pump();
      await tester.pump();
      rig.service.places['me'] = const [ArrivalPlace.home()];
      await tester.tap(find.text('Đến nơi rồi'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Phòng gym'));
      await tester.pumpAndSettle();
      expect(rig.service.events, isEmpty);
      expect(
        find.text('Chưa gửi được tin “Đã đến Phòng gym”.'),
        findsOneWidget,
      );
    });

    testWidgets('Reduce Motion: no size animation on the strip', (
      tester,
    ) async {
      final rig = _Rig()..reduceMotion = true;
      await rig.start(tester, _card());
      rig.share('me', const ArrivalShare(share: true));
      await tester.pump();
      await tester.pump();
      final size = tester.widget<AnimatedSize>(find.byType(AnimatedSize));
      expect(size.duration, Duration.zero);
    });

    testWidgets('text ×1.3: lanes and buttons stack', (tester) async {
      final rig = _Rig(places: [const ArrivalPlace.home(), _gym])
        ..textScale = 1.3;
      await rig.start(tester, _card());
      rig.share('me', const ArrivalShare(share: true));
      rig.share('her', const ArrivalShare(share: true));
      await tester.pump();
      await tester.pump();
      final you = tester.getTopLeft(find.text('BẠN'));
      final her = tester.getTopLeft(find.text('THẢO'));
      expect(her.dy, greaterThan(you.dy));
      expect(her.dx, you.dx);
      final home = tester.getTopLeft(find.text('Về nhà rồi'));
      final other = tester.getTopLeft(find.text('Đến nơi rồi'));
      expect(other.dy, greaterThan(home.dy));
      expect(tester.takeException(), isNull);
    });
  });

  group('setup', () {
    testWidgets('no place with a location → "Trước hết, nhà bạn ở đâu?"', (
      tester,
    ) async {
      final rig = _Rig();
      await rig.start(
        tester,
        _launcher((c) => openArrivalSetup(c, from: 'home_card')),
      );
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();
      expect(find.text('Trước hết, nhà bạn ở đâu?'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('arrival-set-home')));
      await tester.pumpAndSettle();
      expect(find.text('Nhà ở đâu?'), findsOneWidget);
    });

    testWidgets(
      'Android: disclosure → OS label step → back from the page → done',
      (tester) async {
        ArrivalSetupScreen.backgroundLabel = () async => 'Luôn cho phép';
        addTearDown(
          () => ArrivalSetupScreen.backgroundLabel = () async => null,
        );
        final rig = _Rig(
          places: [ArrivalPlace.home(location: _homeAt)],
          perm: const ArrivalPermissionState(ArrivalPermissionLevel.whenInUse),
        );
        await rig.start(
          tester,
          _launcher((c) => openArrivalSetup(c, from: 'home_card')),
        );
        await tester.tap(find.text('go'));
        await tester.pumpAndSettle();
        expect(find.text('Về đến nơi, Thảo biết ngay'), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('arrival-agree')));
        await tester.pumpAndSettle();
        expect(rig.service.calls, contains('on auto=false'));
        expect(rig.provider.wantsAuto, isTrue);

        // The machine's own words for "Cho phép mọi lúc" (D12).
        expect(find.text('Chọn “Luôn cho phép”'), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('arrival-ask-always')));
        await tester.pumpAndSettle();
        // Not granted yet: stays on step 2 (no spinner left behind).
        expect(find.text('Chọn “Luôn cho phép”'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);

        rig.perms.state = const ArrivalPermissionState(
          ArrivalPermissionLevel.always,
        );
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pumpAndSettle();
        expect(find.text('Đã bật báo về nhà'), findsOneWidget);
      },
    );

    testWidgets('a plugin error never leaves the button spinning', (
      tester,
    ) async {
      final rig = _Rig(places: [ArrivalPlace.home(location: _homeAt)]);
      rig.perms.throwOnRequest = true;
      await rig.start(
        tester,
        _launcher((c) => openArrivalSetup(c, from: 'home_card')),
      );
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();
      rig.perms.state = const ArrivalPermissionState(
        ArrivalPermissionLevel.notDetermined,
      );
      await tester.tap(find.byKey(const ValueKey('arrival-agree')));
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Tạm thời bạn báo bằng tay'), findsOneWidget);
    });
  });

  group('manage', () {
    testWidgets('turn off → dialog with "xoá luôn địa chỉ" → off + wiped', (
      tester,
    ) async {
      final rig = _Rig(places: [ArrivalPlace.home(location: _homeAt)]);
      await rig.start(tester, const ArrivalManageScreen());
      rig.share('me', const ArrivalShare(share: true));
      await tester.pump();
      await tester.pump();
      expect(find.text('Thảo đang thấy'), findsOneWidget);
      // The whole row toggles, not only the switch.
      await tester.tap(find.text('Báo cho Thảo'));
      await tester.pumpAndSettle();
      expect(find.text('Tắt báo về nhà?'), findsOneWidget);
      await tester.tap(
        find.text('Xoá luôn địa chỉ đã lưu của 1 nơi trên máy này'),
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('arrival-turnoff-confirm')));
      await tester.pumpAndSettle();
      expect(rig.service.calls.last, 'off');
      expect(rig.provider.home.location, isNull);
    });

    testWidgets('4 custom places → no "Thêm nơi"; 3 → "Còn 1 chỗ"', (
      tester,
    ) async {
      List<ArrivalPlace> customs(int n) => [
        const ArrivalPlace.home(),
        for (var i = 1; i <= n; i++)
          ArrivalPlace(slot: 'p$i', name: 'Nơi $i', icon: ArrivalIcon.pin),
      ];
      final full = _Rig(places: customs(4));
      await full.start(tester, const ArrivalManageScreen());
      expect(find.text('Nơi 4'), findsOneWidget);
      expect(find.text('Thêm nơi'), findsNothing);
      expect(full.provider.nextFreeSlot, isNull);

      final three = _Rig(places: customs(3));
      await three.start(tester, const ArrivalManageScreen());
      await tester.pumpAndSettle();
      expect(find.text('Thêm nơi'), findsOneWidget);
      expect(find.text('Còn 1 chỗ'), findsOneWidget);
    });
  });

  group('search', () {
    Future<_Rig> open(WidgetTester tester, _Rig rig) async {
      await rig.start(
        tester,
        _launcher((c) => openArrivalPlaceSearch(c, _gym)),
      );
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();
      return rig;
    }

    testWidgets('Android: waits 800 ms, then results + "bấm Tìm" tip', (
      tester,
    ) async {
      final rig = _Rig(
        results: const [
          PlaceSearchResult(
            title: '54 Liễu Giai',
            subtitle: 'Hà Nội',
            lat: 1,
            lng: 1,
          ),
        ],
      );
      rig.search.typing = false;
      await open(tester, rig);
      await tester.enterText(
        find.byKey(const ValueKey('arrival-search')),
        '54 Liễu Giai',
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(rig.search.queries, isEmpty);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(rig.search.queries, ['54 Liễu Giai']);
      expect(find.text('54 Liễu Giai', findRichText: true), findsWidgets);
      expect(
        find.text('Gõ xong bấm Tìm trên bàn phím nếu chưa thấy kết quả.'),
        findsOneWidget,
      );
    });

    testWidgets('not found / offline → message + "Dùng vị trí hiện tại"', (
      tester,
    ) async {
      final rig = await open(tester, _Rig());
      await tester.enterText(find.byKey(const ValueKey('arrival-search')), 'x');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Không tìm thấy địa chỉ này.'),
        findsOneWidget,
      );
      expect(find.text('Dùng vị trí hiện tại'), findsOneWidget);

      rig.search.error = const PlaceSearchOffline();
      await tester.enterText(
        find.byKey(const ValueKey('arrival-search')),
        'xy',
      );
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      expect(find.textContaining('Cần mạng để tìm địa chỉ.'), findsOneWidget);
    });

    testWidgets('no geocoder → "Lưu tên, chỉ bấm tay" saves without address', (
      tester,
    ) async {
      final rig = _Rig()..search.available = false;
      await open(tester, rig);
      expect(
        find.textContaining('Máy này không tìm được địa chỉ.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Lưu tên, chỉ bấm tay'));
      await tester.pumpAndSettle();
      final p = rig.provider.customPlaces.single;
      expect(p.name, 'Phòng gym');
      expect(p.location, isNull);
    });

    test('match range for the iOS underline', () {
      expect(arrivalMatchRange('54 Liễu Giai', '54 liễu gi'), (0, 10));
      expect(arrivalMatchRange('54 Liễu Giai', 'Nguyễn'), isNull);
      expect(arrivalMatchRange('54 Liễu Giai', '  '), isNull);
    });
  });

  group('edit', () {
    testWidgets('rename a place → saved, Save locked until a change', (
      tester,
    ) async {
      final rig = _Rig(places: [const ArrivalPlace.home(), _gym]);
      await rig.start(tester, _launcher((c) => openArrivalEditPlace(c, _gym)));
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();
      ElevatedButton save() => tester.widget<ElevatedButton>(
        find.descendant(
          of: find.byKey(const ValueKey('arrival-edit-save')),
          matching: find.byType(ElevatedButton),
        ),
      );
      expect(save().onPressed, isNull);
      await tester.enterText(find.byKey(const ValueKey('arrival-name')), 'Gym');
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('arrival-edit-save')));
      await tester.pumpAndSettle();
      expect(rig.provider.customPlaces.single.name, 'Gym');
    });

    testWidgets('Home: no rename, "Xoá địa chỉ" only once it has one', (
      tester,
    ) async {
      final rig = _Rig(places: [ArrivalPlace.home(location: _homeAt)]);
      await rig.start(
        tester,
        _launcher((c) => openArrivalEditPlace(c, rig.provider.home)),
      );
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('arrival-name')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('arrival-delete')));
      await tester.pumpAndSettle();
      expect(find.text('Xoá địa chỉ Nhà?'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('arrival-delete-confirm')));
      await tester.pumpAndSettle();
      expect(rig.provider.home.location, isNull);
      expect(find.text('Đã xoá địa chỉ Nhà'), findsOneWidget);
      await tester.pump(const Duration(seconds: 7));
    });

    testWidgets('undo: slot held 5 s; taken anyway → says it can\'t', (
      tester,
    ) async {
      final rig = _Rig(places: [const ArrivalPlace.home(), _gym]);
      await rig.start(tester, _launcher((c) => openArrivalEditPlace(c, _gym)));
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('arrival-delete')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('arrival-delete-confirm')));
      await tester.pumpAndSettle();
      // A new place never gets the slot being undone.
      expect(rig.provider.nextFreeSlot, 'p2');
      await rig.provider.savePlace(
        const ArrivalPlace(slot: 'p1', name: 'Mới', icon: ArrivalIcon.pin),
      );
      await tester.tap(find.text('Hoàn tác'));
      await tester.pumpAndSettle();
      expect(rig.provider.customPlaces.single.name, 'Mới');
      expect(
        find.text('Chưa hoàn tác được: chỗ này vừa được dùng cho nơi khác.'),
        findsOneWidget,
      );
      await tester.pump(const Duration(seconds: 7));
      expect(rig.provider.nextFreeSlot, 'p2'); // p1 is "Mới" now
    });

    testWidgets('confirm: save fails → stays + says so', (tester) async {
      final rig = _Rig();
      await rig.start(
        tester,
        _launcher(
          (c) => Navigator.of(c).push(
            MaterialPageRoute<void>(
              settings: const RouteSettings(name: 'ArrivalPlace/Confirm'),
              builder: (_) =>
                  ArrivalConfirmScreen(draft: _gym, location: _homeAt),
            ),
          ),
        ),
      );
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();
      rig.provider.clear(); // uid gone → savePlace false
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('arrival-save')));
      await tester.pumpAndSettle();
      expect(find.text('Đúng chỗ này chưa?'), findsOneWidget);
      expect(find.text('Chưa lưu được Phòng gym. Thử lại sau nhé.'), findsOne);
    });
  });

  group('settings rows', () {
    testWidgets('"Khi người ấy đến nơi" reads + saves pushArrival', (
      tester,
    ) async {
      final saved = <bool>[];
      final rig = _Rig();
      await rig.start(
        tester,
        Scaffold(
          body: ArrivalPushTile(
            load: () async => false,
            save: (v) async => saved.add(v),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Khi người ấy đến nơi'), findsOneWidget);
      expect(
        tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
        isFalse,
      );
      await tester.tap(find.byType(SwitchListTile));
      await tester.pump();
      expect(saved, [true]);
    });

    testWidgets('"Về đến nhà" subtitle: off / sharing places', (tester) async {
      final rig = _Rig(places: [const ArrivalPlace.home(), _gym]);
      late BuildContext ctx;
      await rig.start(
        tester,
        Builder(
          builder: (c) {
            ctx = c;
            return const SizedBox();
          },
        ),
      );
      expect(arrivalSettingsSubtitle(ctx), 'Đang tắt');
      rig.share('me', const ArrivalShare(share: true));
      await tester.pump();
      await tester.pump();
      expect(
        arrivalSettingsSubtitle(ctx),
        'Đang báo cho Thảo: Nhà · Phòng gym',
      );
    });
  });

  testWidgets('dates follow the locale (D3 i18n)', (tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (c) {
            ctx = c;
            return const SizedBox();
          },
        ),
      ),
    );
    expect(ArrivalFormat.shortDate(ctx, DateTime(2026, 10, 13)), '10/13');
  });
}
