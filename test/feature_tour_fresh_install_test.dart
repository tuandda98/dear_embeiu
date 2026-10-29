import 'dart:io';

import 'package:dear_embeiu/widgets/feature_tour_sheet.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  test('fresh install records the current build before Home ever opens', () async {
    final dir = await Directory.systemTemp.createTemp('tour');
    Hive.init(dir.path);
    PackageInfo.setMockInitialValues(
      appName: 'x',
      packageName: 'x',
      version: '1.12.0',
      buildNumber: '33',
      buildSignature: '',
    );
    await FeatureTour.rememberFreshInstall();
    expect(Hive.box<String>('app_settings').get('feature_tour_seen_build'), '33');
    await Hive.close();
    await dir.delete(recursive: true);
  });
}
