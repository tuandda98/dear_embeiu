import 'dart:io';

import 'package:dear_embeiu/l10n/app_l10n.dart';
import 'package:dear_embeiu/providers/locale_provider.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('setLocale(null) re-resolves AppL10n to the device language', () async {
    Hive.init(Directory.systemTemp.createTempSync().path);
    AppL10n.setLocale(const Locale('vi'));
    await LocaleProvider().setLocale(null);
    final device =
        WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    expect(AppL10n.strings.localeName, device == 'vi' ? 'vi' : 'en');
  });
}
