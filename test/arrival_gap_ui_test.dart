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
import 'package:dear_embeiu/screens/arrival_manage_screen.dart';
import 'package:dear_embeiu/screens/arrival_place_screen.dart';
import 'package:dear_embeiu/screens/arrival_setup_screen.dart';
import 'package:dear_embeiu/services/arrival_platform.dart';
import 'package:dear_embeiu/services/auth_service.dart';
import 'package:dear_embeiu/services/sleep_service.dart';
import 'package:dear_embeiu/theme/app_theme.dart';
import 'package:dear_embeiu/utils/arrival_edge_filter.dart';
import 'package:dear_embeiu/widgets/arrival/arrival_card.dart';
import 'package:dear_embeiu/widgets/arrival/arrival_scaffold.dart';

import 'arrival_test.dart' show FakeArrivalService, FakeGeofence, FakeBattery;

/// Gap cases (test-cases.md): widget level. Harness copied from arrival_ui_test.dart.
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
  Future<void> saveWantsAuto(
    String uid,
    bool value, {
    String? partnerUid,
  }) async => wants[uid] = value;

  @override
  Future<String?> loadAutoPartner(String uid) async => null;

  final everShared = <String>{};

  @override
  Future<bool> loadEverShared(String uid) async => everShared.contains(uid);

  @override
  Future<void> saveEverShared(String uid) async => everShared.add(uid);

  @override
  Future<void> saveSession(String uid, String? coupleId) async {}

  @override
  Future<void> clearSession() async {}

  @override
  Future<String?> loadSharePartner(String uid) async => null;

  @override
  Future<void> saveSharePartner(String uid, String partnerUid) async {}
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

Widget _card() => Scaffold(
  body: SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: ArrivalCard(couple: _couple),
  ),
);

void main() {
  group('name screen', () {
    testWidgets('DD-03: empty / blank name → hint shown, Continue locked', (
      tester,
    ) async {
      final rig = _Rig();
      await rig.start(tester, const ArrivalNameScreen(slot: 'p1'));
      await tester.pumpAndSettle();
      final button = find.byKey(const ValueKey('arrival-continue'));
      expect(find.text('Gõ tên để tiếp tục. Tối đa 24 ký tự.'), findsOneWidget);
      expect(tester.widget<ArrivalPrimaryButton>(button).onPressed, isNull);
      await tester.enterText(find.byType(TextField), '   ');
      await tester.pump();
      expect(find.text('Gõ tên để tiếp tục. Tối đa 24 ký tự.'), findsOneWidget);
      expect(tester.widget<ArrivalPrimaryButton>(button).onPressed, isNull);
      await tester.tap(button, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.byType(ArrivalNameScreen), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Công ty');
      await tester.pump();
      expect(find.text('Gõ tên để tiếp tục. Tối đa 24 ký tự.'), findsNothing);
      expect(tester.widget<ArrivalPrimaryButton>(button).onPressed, isNotNull);
    });
  });

  group('permissions', () {
    testWidgets(
      'QV-06: Precise Location off → "Cần bật Vị trí chính xác", no fix read',
      (tester) async {
        final rig = _Rig(
          perm: const ArrivalPermissionState(
            ArrivalPermissionLevel.whenInUse,
            precise: false,
          ),
          fix: const CurrentFix(lat: 21, lng: 105, accuracyM: 900),
        );
        await rig.start(
          tester,
          _launcher(
            (c) => Navigator.of(c).push(
              MaterialPageRoute<void>(
                builder: (_) => const ArrivalCurrentScreen(draft: _gym),
              ),
            ),
          ),
        );
        await tester.tap(find.text('go'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('arrival-read')));
        await tester.pumpAndSettle();
        expect(find.text('Cần bật Vị trí chính xác'), findsOneWidget);
        expect(find.text('Đúng chỗ này chưa?'), findsNothing);
        expect(rig.provider.placesWithLocation, isEmpty);
      },
    );

    testWidgets(
      'QV-03: Setup, system dialog refused → "Tạm thời bạn báo bằng tay"',
      (tester) async {
        final rig = _Rig(places: [ArrivalPlace.home(location: _homeAt)]);
        await rig.start(
          tester,
          _launcher((c) => openArrivalSetup(c, from: 'home_card')),
        );
        await tester.tap(find.text('go'));
        await tester.pumpAndSettle();
        rig.perms.state = const ArrivalPermissionState(
          ArrivalPermissionLevel.denied,
        );
        await tester.tap(find.byKey(const ValueKey('arrival-agree')));
        await tester.pumpAndSettle();
        expect(find.text('Tạm thời bạn báo bằng tay'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(rig.provider.home.location, isNotNull);
      },
    );
  });

  group('a11y', () {
    testWidgets(
      'AY-03: share row is one merged control (title + subtitle + switch)',
      (tester) async {
        final handle = tester.ensureSemantics();
        final rig = _Rig(places: [ArrivalPlace.home(location: _homeAt)]);
        await rig.start(tester, const ArrivalManageScreen());
        rig.share('me', const ArrivalShare(share: true));
        await tester.pump();
        await tester.pump();
        final row = find.byKey(const ValueKey('arrival-share-switch'));
        final node = tester.getSemantics(
          find.descendant(of: row, matching: find.byType(MergeSemantics)),
        );
        expect(node.label, contains('Báo cho Thảo'));
        expect(
          node.getSemanticsData().flagsCollection.isToggled.name,
          'isTrue',
        );
        // Subtitle is read in the same node, not as a separate stop.
        expect(
          find.descendant(of: row, matching: find.byType(Switch)),
          findsOneWidget,
        );
        expect(node.label.split('\n').length, greaterThanOrEqualTo(2));
        handle.dispose();
      },
    );

    testWidgets(
      'AY-07: text ×2.0 on 360×640 → no overflow (card, name, manage)',
      (tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final rig = _Rig(places: [const ArrivalPlace.home(), _gym])
          ..textScale = 2.0;
        await rig.start(tester, _card());
        rig.share('me', const ArrivalShare(share: true));
        rig.share('her', const ArrivalShare(share: true));
        await tester.pump();
        await tester.pump();
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(rig.app(const ArrivalNameScreen(slot: 'p2')));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byType(TextField),
          'Nhà ngoại ở Thanh Xuân',
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byKey(const ValueKey('arrival-continue')), findsOneWidget);

        await tester.pumpWidget(rig.app(const ArrivalManageScreen()));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  });
}
