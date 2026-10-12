import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// Feature pairing-funnel, audit 2026-10-12: native flags that a
// `flutter create .` or an old-branch merge could quietly drop.
void main() {
  final plist = File('ios/Runner/Info.plist').readAsStringSync();
  final manifest =
      File('android/app/src/main/AndroidManifest.xml').readAsStringSync();

  String orientations(String key) => RegExp(
        '<key>$key</key>\\s*<array>(.*?)</array>',
        dotAll: true,
      ).firstMatch(plist)!.group(1)!;

  test('PA1: Flutter deep linking is off — dearembeiu:// only foregrounds',
      () {
    expect(
      plist,
      matches(RegExp(r'<key>FlutterDeepLinkingEnabled</key>\s*<false/>')),
    );
    expect(
      manifest,
      matches(RegExp(
        r'android:name="flutter_deeplinking_enabled"\s*'
        r'android:value="false"',
      )),
    );
  });

  test('PA10/PA-N2: the Health prompt says the wake-ups go to the partner too',
      () {
    final health = RegExp(
      r'<key>NSHealthShareUsageDescription</key>\s*<string>(.*?)</string>',
    ).firstMatch(plist)!.group(1)!;
    expect(health, allOf(contains('thức giấc'), contains('người ấy')));
  });

  test('T6-1: every permission prompt is in both InfoPlist.strings, and the '
      'Vietnamese one matches the Info.plist fallback', () {
    // iOS reads vi.lproj on a Vietnamese phone: a sentence changed in only one
    // of the two places would still pass every other test.
    final prompts = {
      for (final m in RegExp(
        r'<key>(\w+UsageDescription)</key>\s*<string>(.*?)</string>',
        dotAll: true,
      ).allMatches(plist))
        m[1]!: m[2]!
            .replaceAll('&lt;', '<')
            .replaceAll('&gt;', '>')
            .replaceAll('&quot;', '"')
            .replaceAll('&apos;', "'")
            .replaceAll('&amp;', '&'),
    };
    final entry = RegExp(r'"(\w+UsageDescription)"\s*=\s*"((?:[^"\\]|\\.)*)";');
    Map<String, String> strings(String lang) => {
          for (final m in entry.allMatches(
            File('ios/Runner/$lang.lproj/InfoPlist.strings')
                .readAsStringSync()
                .replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), ''),
          ))
            m[1]!: m[2]!.replaceAllMapped(RegExp(r'\\(["\\])'), (e) => e[1]!),
        };

    expect(prompts, isNotEmpty);
    expect(strings('vi'), prompts);
    expect(strings('en').keys.toSet(), prompts.keys.toSet());
  });

  test('PA9: phones portrait only, iPad keeps every orientation', () {
    final phone = orientations('UISupportedInterfaceOrientations');
    expect(RegExp('UIInterfaceOrientation').allMatches(phone), hasLength(1));
    expect(phone, contains('UIInterfaceOrientationPortrait'));
    final pad = orientations('UISupportedInterfaceOrientations~ipad');
    expect(RegExp('UIInterfaceOrientation').allMatches(pad), hasLength(4));
    expect(manifest, contains('android:screenOrientation="portrait"'));
  });
}
