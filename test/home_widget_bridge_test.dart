import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:dear_embeiu/models/couple.dart';
import 'package:dear_embeiu/providers/couple_provider.dart';
import 'package:dear_embeiu/providers/locale_provider.dart';
import 'package:dear_embeiu/services/home_widget_bridge.dart';

/// Feature home-widget: on a cold start the couple is null until it loads, so
/// the bridge must not overwrite a good widget with `empty` while loading or
/// after a failed load — and must send each snapshot once.
class _FakeCouples extends CoupleProvider {
  Couple? _c;
  bool _loading = false;
  String? _error;

  @override
  Couple? get couple => _c;
  @override
  bool get isLoading => _loading;
  @override
  String? get errorMessage => _error;

  void emit({Couple? couple, bool loading = false, String? error}) {
    _c = couple;
    _loading = loading;
    _error = error;
    notifyListeners();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('dear_embeiu/widget');
  final sent = <Map<String, String>>[];

  setUpAll(() async {
    await initializeDateFormatting();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'update') {
        sent.add(Map<String, String>.from(call.arguments as Map));
      }
      return null;
    });
  });

  final epoch = DateTime(2023, 5, 14);
  final couple = Couple(
    id: 'c1',
    person1Name: 'Tuấn',
    person2Name: 'Thảo',
    anniversaryDate: epoch,
    inviteCode: 'ABC123',
    memberIds: const ['me', 'other'],
    memberCount: 2,
    createdByUserId: 'me',
    status: 'active',
    createdAt: epoch,
    updatedAt: epoch,
  );

  testWidgets('pushes once per change, never while loading or after a failed load',
      (tester) async {
    final couples = _FakeCouples();
    final locales = LocaleProvider();
    HomeWidgetBridge.resetForTest();
    HomeWidgetBridge.bind(couples, locales);
    await tester.pump();
    expect(sent, isEmpty, reason: 'no push at bind: the couple is unknown, not absent');

    couples.emit(loading: true);
    await tester.pump();
    expect(sent, isEmpty, reason: 'loading: keep the widget as it is');

    couples.emit(couple: couple);
    await tester.pump();
    expect(sent.length, 1);
    expect(sent.single['state'], 'counter');
    expect(sent.single['anniversary'], '2023-05-14');

    couples.emit(couple: couple);
    await tester.pump();
    expect(sent.length, 1, reason: 'an identical snapshot is not re-sent');

    couples.emit(couple: null, error: 'sync failed');
    await tester.pump();
    expect(sent.length, 1, reason: 'a failed load keeps the last good snapshot');

    couples.emit(couple: null);
    await tester.pump();
    expect(sent.length, 2);
    expect(sent.last['state'], 'empty', reason: 'signed out / no couple → empty');
  });
}
