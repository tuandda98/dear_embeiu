# 💻 Dev — Widget màn hình chính — Đếm ngày yêu · Kế hoạch triển khai

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
>
> Dev sở hữu. Đọc `overview.md` + `design.md` trước. Role Dev là role DUY NHẤT sửa `lib/`, `ios/`, `android/`. Không đụng `firestore.rules` / `functions/`.

- **Trạng thái dev:** xong — chờ test (implement 2026-10-12, 8 task)
- **Người/role:** Dev
- **Nhánh:** `feature/home-widget` (đã có trên GitHub, tách từ `fix/audit-2026-10-12`)
- **Đọc file này thế nào:** phần dưới là kế hoạch đã chạy, các ô Step không tick từng ô. Trạng thái thật nằm ở "Checklist implement" và "Nhật ký implement" cuối file. Các khối code trong kế hoạch đã được đồng bộ lại với file thật ngày 2026-10-12.

**Goal:** Widget màn hình chính "Đếm ngày yêu" trên iOS (nhỏ 2×2 + vừa 4×2) và Android (2×2 + 4×2) hiện số ngày bên nhau, tên hai người, cột mốc tiếp theo; tự nhảy số mỗi 0:00 không cần mở app; chạm mở app.

**Architecture:** Native vẽ (iOS: target WidgetKit `DearEmbeiuWidget`; Android: `AppWidgetProvider` trong app). Flutter chỉ đẩy một "ảnh chụp" `Map<String,String>` (ngày yêu + tên + chuỗi đã dịch) qua MethodChannel `dear_embeiu/widget` tự viết (cùng pattern `dear_embeiu/sleep`); native lưu vào App Group `UserDefaults` / `SharedPreferences`, tự tính số ngày + cột mốc mỗi lần vẽ bằng công thức copy y hệt Dart (`LoveTreeService.daysTogether`, `_getNextMilestone`).

**Tech Stack:** Flutter 3.41.6 (máy nhà: bare `flutter` đúng version) · Swift 5 / SwiftUI / WidgetKit (iOS 15.0+) · Kotlin 2.2 / RemoteViews (minSdk theo Flutter, compileSdk 36) · gem `xcodeproj` 1.27 đi kèm CocoaPods Homebrew (chạy qua `GEM_HOME=$(brew --prefix cocoapods)/libexec $(brew --prefix ruby)/bin/ruby`, KHÔNG set `GEM_PATH`).

**Spec:** `project/features/home-widget/overview.md` (D1–D9, 11 acceptance) · `project/features/home-widget/design.md` (token, copy, states) · mockup `https://claude.ai/artifact/Rb2dk1uaXdjuUGEBwNiKD9`.

## Global Constraints

- Không đổi `firestore.rules`, `storage.rules`, `functions/`. Không deploy gì.
- Channel: `dear_embeiu/widget`; method `update(Map<String,String>)`, `consumeLaunch() -> String?`.
- Bundle id widget: `com.tony.dearembeiu.widget` (Release) · `com.tony.dearembeiu.dev.widget` (Debug/Profile). App Group: `group.com.tony.dearembeiu` (Release) · `group.com.tony.dearembeiu.dev` (Debug/Profile) — qua build setting `APP_GROUP_ID`, đọc từ Info.plist key `AppGroupId`.
- Bảng cột mốc `[30, 50, 100, 180, 365, 500, 730, 1000, 1500, 2000, 3000]`, hết bảng → `((days / 500) + 1) * 500`; tiến độ = `days / next`; nhãn `N tháng` (<365, chia hết 30) / `N năm` (chia hết 365) / `N ngày`. Đếm ngày = so ngày lịch, không âm.
- Token màu (design.md): nền `#FF5C8F → #FF4D6D (55%) → #E63956` góc 150°, scrim đen .10→.28, aurora trắng .26 + lavender `#A78BFA` .40; chip trắng .84 chữ navy `#1A1A2E`; tim `#E63956`; chữ trắng bóng đen .30. Cỡ chữ chỉ 10 / 11 / 12 / 14 / 28 / 32 / 40. Font Quicksand (Bold/SemiBold/Medium từ `assets/fonts/`).
- Copy: chuỗi hiển thị do Flutter dịch sẵn (D4). Ngoại lệ native: tên/mô tả trong gallery widget + câu trạng thái trống khi chưa có ảnh chụp. Giọng "chúng mình". Không emoji làm icon.
- iOS deployment target widget = 15.0 (bằng app). Số: `minimumScaleFactor 0.6` iOS, `autoSizeTextType` Android.
- Mỗi task kết thúc bằng `flutter analyze` sạch (khi đụng Dart) + commit. Commit message tiếng Việt kiểu `feat(home-widget): …`, cuối message 2 dòng:
  `Co-Authored-By: Claude <model thật đang code> <noreply@anthropic.com>` và `Claude-Session: https://claude.ai/code/session_01Fe9gCYrrfgYjeuLy2WrVgg` (subagent ghi đúng model của mình, vd `Claude Haiku 5.5`; các khối lệnh commit trong task viết sẵn `Fable 5.1` — thay cho đúng).
- Chạy lệnh từ gốc repo `/Users/dodaoanhtuan/AndroidStudioProjects/dear_embeiu`.

---

## Cấu trúc file (chốt phân rã)

| File | Trách nhiệm |
|---|---|
| `lib/services/home_widget_snapshot.dart` (mới) | Hàm thuần `HomeWidgetSnapshot.build(couple, l10n) → Map<String,String>` — danh sách key là hợp đồng với native |
| `lib/services/home_widget_bridge.dart` (mới) | Lắng nghe CoupleProvider + LocaleProvider, gửi ảnh chụp qua channel, `consumeLaunch` → Analytics |
| `lib/services/analytics_service.dart` | + event `widget_tap` / param `family` |
| `lib/main.dart` | CoupleProvider + LocaleProvider thành field của `_MyAppState`, gắn bridge, gọi `consumeLaunch` khi resume |
| `lib/l10n/app_vi.arb`, `app_en.arb` | + key `widgetEmptyTap` |
| `test/home_widget_snapshot_test.dart` (mới) | Test hàm thuần |
| `ios/DearEmbeiuWidget/DayMath.swift` | Đếm ngày / cột mốc / format số (mirror Dart) — thuần Foundation |
| `ios/DearEmbeiuWidget/WidgetSnapshot.swift` | Đọc ảnh chụp từ App Group; `DayModel` tính chuỗi hiển thị |
| `ios/DearEmbeiuWidget/DayCounterWidget.swift` | `TimelineProvider` (7 nửa đêm) + `@main Widget` |
| `ios/DearEmbeiuWidget/DayCounterView.swift` | SwiftUI nhỏ/vừa/trống + nền + tinted |
| `ios/DearEmbeiuWidget/{Info.plist, DearEmbeiuWidget.entitlements, PrivacyInfo.xcprivacy, en.lproj/Localizable.strings, vi.lproj/Localizable.strings}` | Cấu hình target |
| `scripts/ios-add-widget-target.{sh,rb}` | Thêm target vào `Runner.xcodeproj` bằng gem xcodeproj (idempotent) |
| `scripts/check-widget-daymath.sh` + `scripts/widget-daymath-check/main.swift` | Kiểm `DayMath.swift` bằng `swiftc`, không cần Xcode project |
| `ios/Runner/{AppDelegate.swift, SceneDelegate.swift, Runner.entitlements, Info.plist}` | Channel `HomeWidgetChannel`, ghi cờ mở-từ-widget, App Group |
| `android/app/src/main/kotlin/com/tony/dearembeiu/widget/{DayMath.kt, WidgetStore.kt, DayCounterWidget.kt}` | Mirror Dart · kho SharedPreferences · provider |
| `android/app/src/main/kotlin/com/tony/dearembeiu/MainActivity.kt` | Channel + ghi cờ từ intent extra |
| `android/app/src/main/res/{layout/widget_day_small.xml, layout/widget_day_medium.xml, layout/widget_day_empty.xml, drawable/*.xml, drawable-v31/widget_bg.xml, xml/widget_day_info.xml, values/strings.xml, values-vi/strings.xml}` | Giao diện RemoteViews |
| `android/app/src/main/AndroidManifest.xml` | `<receiver>` widget |
| `android/app/build.gradle.kts` + `android/app/src/test/kotlin/com/tony/dearembeiu/widget/DayMathTest.kt` | JUnit cho DayMath |

---

### Task 1: Ảnh chụp dữ liệu (Flutter, hàm thuần) + key l10n mới

**Files:**
- Create: `lib/services/home_widget_snapshot.dart`
- Modify: `lib/l10n/app_vi.arb` (quanh dòng 1043), `lib/l10n/app_en.arb` (quanh dòng 1562), rồi `flutter gen-l10n` (sinh lại `lib/l10n/app_localizations*.dart`, đã commit trong repo)
- Test: `test/home_widget_snapshot_test.dart`

**Interfaces:**
- Consumes: `Couple` (`lib/models/couple.dart`: `person1Name`, `person2Name`, `anniversaryDate`), `AppLocalizations` (`lookupAppLocalizations(Locale)`, `localeName`, các getter/hàm `daysTogether`, `milestoneNextLabel(String)`, `milestoneDaysLeft(int)`, `milestoneTodayLabel`, `milestoneMonthsOne/Many(int)`, `milestoneYearsOne/Many(int)`, `milestoneDaysLabel(int)`, `guestCounterStartFrom(String)`, `fullDateFormat`, `widgetEmptyTap` mới).
- Produces: `abstract final class HomeWidgetSnapshot { static Map<String, String> build({required Couple? couple, required AppLocalizations l10n}); }` với các key cố định: `state` (`counter`|`empty`), `lang`, `anniversary` (`YYYY-MM-DD`), `name1`, `name2`, `daysLabel`, `milestoneFmt` (`…{label}`), `daysLeftOne`, `daysLeftFmt` (`…{count}…`), `todayLabel`, `monthsOne`, `monthsFmt`, `yearsOne`, `yearsFmt`, `daysFmt`, `sinceText`; trạng thái trống: `state`, `lang`, `emptyChip`, `emptyText`. Native (Task 4, Task 7) đọc đúng các key này.

- [ ] **Step 1: Thêm key l10n `widgetEmptyTap`**

Edit `lib/l10n/app_vi.arb` — old:
```json
  "guestCounterStartFrom": "Bắt đầu từ {date}",
```
new:
```json
  "widgetEmptyTap": "Chạm để bắt đầu đếm ngày yêu",
  "@widgetEmptyTap": {
    "description": "Home-screen widget, empty state (guest / no couple / signed out). One line under the app-name chip; widget is 158pt wide, max 3 lines."
  },
  "guestCounterStartFrom": "Bắt đầu từ {date}",
```
Edit `lib/l10n/app_en.arb` — old:
```json
  "guestCounterStartFrom": "Since {date}",
```
new:
```json
  "widgetEmptyTap": "Tap to start counting your days together",
  "@widgetEmptyTap": {
    "description": "Home-screen widget, empty state (guest / no couple / signed out). One line under the app-name chip; widget is 158pt wide, max 3 lines."
  },
  "guestCounterStartFrom": "Since {date}",
```
Run: `flutter gen-l10n`
Expected: không lỗi; `grep -n "widgetEmptyTap" lib/l10n/app_localizations.dart` ra 1 dòng `String get widgetEmptyTap;`.

- [ ] **Step 2: Viết test (fail trước)**

Create `test/home_widget_snapshot_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:dear_embeiu/l10n/app_localizations.dart';
import 'package:dear_embeiu/models/couple.dart';
import 'package:dear_embeiu/services/home_widget_snapshot.dart';

/// Feature home-widget (D4): Flutter owns the words, native owns the numbers.
/// Every string the widget prints is pre-translated here; native only fills
/// `{count}` / `{label}` and formats the day count.
void main() {
  setUpAll(() => initializeDateFormatting());

  final vi = lookupAppLocalizations(const Locale('vi'));
  final en = lookupAppLocalizations(const Locale('en'));
  final epoch = DateTime(2023, 5, 14, 9, 30); // time of day must not leak

  Couple couple({String name2 = 'Thảo'}) => Couple(
    id: 'c1',
    person1Name: 'Tuấn',
    person2Name: name2,
    anniversaryDate: epoch,
    inviteCode: 'ABC123',
    memberIds: const ['me', 'other'],
    memberCount: 2,
    createdByUserId: 'me',
    status: 'active',
    createdAt: epoch,
    updatedAt: epoch,
  );

  test('couple → counter snapshot with Vietnamese templates', () {
    final s = HomeWidgetSnapshot.build(couple: couple(), l10n: vi);
    expect(s['state'], 'counter');
    expect(s['lang'], 'vi');
    expect(s['anniversary'], '2023-05-14');
    expect(s['name1'], 'Tuấn');
    expect(s['name2'], 'Thảo');
    expect(s['daysLabel'], 'ngày bên nhau');
    expect(s['milestoneFmt'], 'Cột mốc {label}');
    expect(s['daysLeftOne'], 'còn 1 ngày');
    expect(s['daysLeftFmt'], 'còn {count} ngày');
    expect(s['todayLabel'], 'hôm nay 🎉');
    expect(s['monthsOne'], '1 tháng');
    expect(s['monthsFmt'], '{count} tháng');
    expect(s['yearsOne'], '1 năm');
    expect(s['yearsFmt'], '{count} năm');
    expect(s['daysFmt'], '{count} ngày');
    expect(s['sinceText'], 'Bắt đầu từ 14 thg 5, 2023');
  });

  test('English keeps its plural forms and date style', () {
    final s = HomeWidgetSnapshot.build(couple: couple(), l10n: en);
    expect(s['lang'], 'en');
    expect(s['daysLabel'], 'days together');
    expect(s['milestoneFmt'], 'Milestone: {label}');
    expect(s['daysLeftOne'], '1 day left');
    expect(s['daysLeftFmt'], '{count} days left');
    expect(s['monthsOne'], '1 month');
    expect(s['monthsFmt'], '{count} months');
    expect(s['yearsFmt'], '{count} years');
    expect(s['sinceText'], 'Since May 14, 2023');
  });

  test('no couple → empty snapshot, no stale counter keys', () {
    final s = HomeWidgetSnapshot.build(couple: null, l10n: vi);
    expect(s['state'], 'empty');
    expect(s['lang'], 'vi');
    expect(s['emptyChip'], 'DEAR EMBEIU');
    expect(s['emptyText'], 'Chạm để bắt đầu đếm ngày yêu');
    expect(s.containsKey('anniversary'), isFalse);
    expect(s.containsKey('name1'), isFalse);
  });

  test('names are trimmed; a blank partner name stays blank', () {
    final s = HomeWidgetSnapshot.build(couple: couple(name2: '  '), l10n: vi);
    expect(s['name2'], '');
  });

  test('templates keep their placeholders and drop the sentinel digit', () {
    for (final l10n in [vi, en]) {
      final s = HomeWidgetSnapshot.build(couple: couple(), l10n: l10n);
      for (final key in ['daysLeftFmt', 'monthsFmt', 'yearsFmt', 'daysFmt']) {
        expect(s[key], contains('{count}'), reason: key);
        expect(s[key], isNot(contains('0')), reason: key);
      }
      expect(s['milestoneFmt'], contains('{label}'));
    }
  });
}
```

- [ ] **Step 3: Chạy test, phải FAIL**

Run: `flutter test test/home_widget_snapshot_test.dart`
Expected: FAIL biên dịch — `Error: Error when reading 'lib/services/home_widget_snapshot.dart'` / `HomeWidgetSnapshot` không tồn tại.

- [ ] **Step 4: Viết hàm thuần**

Create `lib/services/home_widget_snapshot.dart`:
```dart
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../models/couple.dart';

/// What the home-screen widget shows, pre-translated (feature home-widget, D4).
///
/// Flutter owns the words, native owns the numbers: the iOS extension
/// (`ios/DearEmbeiuWidget/WidgetSnapshot.swift`) and the Android provider
/// (`android/.../widget/DayCounterWidget.kt`) recompute the day count and the
/// next milestone every day from `anniversary`, then fill `{count}` /
/// `{label}` in these templates. Renaming a key means renaming it in all
/// three places.
abstract final class HomeWidgetSnapshot {
  /// Chip text of the empty state — the brand name, never translated.
  static const String emptyChip = 'DEAR EMBEIU';

  static Map<String, String> build({
    required Couple? couple,
    required AppLocalizations l10n,
  }) {
    final lang = l10n.localeName.startsWith('vi') ? 'vi' : 'en';
    if (couple == null) {
      return {
        'state': 'empty',
        'lang': lang,
        'emptyChip': emptyChip,
        'emptyText': l10n.widgetEmptyTap,
      };
    }
    final a = couple.anniversaryDate;
    final since = DateFormat(l10n.fullDateFormat, l10n.localeName).format(a);
    return {
      'state': 'counter',
      'lang': lang,
      'anniversary': _isoDate(a),
      'name1': couple.person1Name.trim(),
      'name2': couple.person2Name.trim(),
      'daysLabel': _lowerFirst(l10n.daysTogether),
      'milestoneFmt': l10n.milestoneNextLabel('{label}'),
      'daysLeftOne': l10n.milestoneDaysLeft(1),
      'daysLeftFmt': _countTemplate(l10n.milestoneDaysLeft),
      'todayLabel': l10n.milestoneTodayLabel,
      'monthsOne': l10n.milestoneMonthsOne(1),
      'monthsFmt': _countTemplate(l10n.milestoneMonthsMany),
      'yearsOne': l10n.milestoneYearsOne(1),
      'yearsFmt': _countTemplate(l10n.milestoneYearsMany),
      'daysFmt': _countTemplate(l10n.milestoneDaysLabel),
      'sinceText': l10n.guestCounterStartFrom(since),
    };
  }

  /// Date only — the count is calendar days, like LoveTreeService.daysTogether.
  static String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static String _lowerFirst(String s) =>
      s.isEmpty ? s : s[0].toLowerCase() + s.substring(1);

  /// ICU plurals only take an int, so render with 0 and swap it for `{count}`
  /// — native fills the real number (grouped per `lang`) at render time. The
  /// generated code interpolates `$count` verbatim, so "0" is the only digit.
  static String _countTemplate(String Function(int) render) =>
      render(0).replaceFirst('0', '{count}');
}
```

- [ ] **Step 5: Chạy test, phải PASS**

Run: `flutter test test/home_widget_snapshot_test.dart`
Expected: `All tests passed!` (5 test).

- [ ] **Step 6: Analyze + commit**

Run: `flutter analyze`
Expected: `No issues found!`
```bash
git add lib/services/home_widget_snapshot.dart lib/l10n test/home_widget_snapshot_test.dart
git commit -m "$(cat <<'EOF'
feat(home-widget): ảnh chụp dữ liệu widget — chuỗi dịch sẵn, số để native tính

HomeWidgetSnapshot.build(couple, l10n) → Map<String,String> (D4): ngày yêu
YYYY-MM-DD, 2 tên, mẫu "Cột mốc {label}" / "còn {count} ngày" / tháng-năm-ngày
+ key l10n mới widgetEmptyTap (vi/en). 5 test.

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01Fe9gCYrrfgYjeuLy2WrVgg
EOF
)"
```

---

### Task 2: Bridge Flutter → native + Analytics + gắn vào app root

**Files:**
- Create: `lib/services/home_widget_bridge.dart`
- Modify: `lib/services/analytics_service.dart:46,58,337`, `lib/main.dart` (import quanh dòng 47; `_MyAppState` dòng 225–275; MultiProvider dòng 281 và 298–300), `lib/app/session_resolver.dart` (nhánh guest ~dòng 148–163 + nhánh verifyEmail ~168–182)
- Test: `test/home_widget_bridge_test.dart` (Step 3b — guard đang-nạp / nạp-lỗi / gửi-một-lần / retry)

**Interfaces:**
- Consumes: `HomeWidgetSnapshot.build` (Task 1), `CoupleProvider.couple` + `addListener`, `LocaleProvider.addListener`, `AppL10n.strings`, `AnalyticsService.instance.logEvent(name, {params})`.
- Produces: `HomeWidgetBridge.bind(CoupleProvider, LocaleProvider)` (gọi 1 lần), `HomeWidgetBridge.push(Couple?)`, `HomeWidgetBridge.consumeLaunch()`; `AnalyticsService.logWidgetTap(String family)`; event `widget_tap` param `family`. Native (Task 4/7) phải trả lời method `update` (args `Map<String,String>`) và `consumeLaunch` (trả `String?`).

- [ ] **Step 1: Thêm event Analytics**

Edit `lib/services/analytics_service.dart` — old:
```dart
  static const String rpsGameFinished = 'rps_game_finished';
```
new:
```dart
  static const String rpsGameFinished = 'rps_game_finished';

  // Home-screen widget (feature home-widget)
  static const String widgetTap = 'widget_tap'; // home-screen widget opened the app
```
old:
```dart
  static const String pRematch = 'rematch'; // rps_invite_sent (bool)
```
new:
```dart
  static const String pRematch = 'rematch'; // rps_invite_sent (bool)
  static const String pFamily = 'family'; // widget_tap: small / medium
```
old:
```dart
  void logCounterBgSwiped() => logEvent(AnalyticsEvents.counterBgSwiped);
```
new:
```dart
  void logCounterBgSwiped() => logEvent(AnalyticsEvents.counterBgSwiped);

  /// The app was opened by tapping the home-screen widget (feature home-widget).
  /// [family] is `small` or `medium`.
  void logWidgetTap(String family) => logEvent(
        AnalyticsEvents.widgetTap,
        params: {AnalyticsEvents.pFamily: family},
      );
```

- [ ] **Step 2: Viết bridge**

Create `lib/services/home_widget_bridge.dart`:
```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../l10n/app_l10n.dart';
import '../models/couple.dart';
import '../providers/couple_provider.dart';
import '../providers/locale_provider.dart';
import 'analytics_service.dart';
import 'home_widget_snapshot.dart';

/// Keeps the native home-screen widget in sync (feature home-widget, D3/D8).
///
/// Channel `dear_embeiu/widget` — iOS `HomeWidgetChannel` (AppDelegate.swift),
/// Android `MainActivity.kt`:
///  * `update(Map<String,String>)` — native stores the snapshot in the shared
///    store and redraws every widget.
///  * `consumeLaunch()` → `'small' | 'medium' | null` — which widget opened the
///    app since the last call; native clears the flag.
abstract final class HomeWidgetBridge {
  static const MethodChannel _channel = MethodChannel('dear_embeiu/widget');
  static Map<String, String>? _lastSent;
  static bool _bound = false;

  /// Wire once from the app root. Re-sends whenever the couple or the language
  /// changes. No push at bind time: `couple` is null until SessionResolver's
  /// loadCoupleForUser answers, and that first notification is what tells us
  /// whether this session really has no couple.
  static void bind(CoupleProvider couples, LocaleProvider locales) {
    if (_bound || kIsWeb) return;
    _bound = true;
    void onChange() {
      // Still fetching: the couple is unknown, not absent.
      if (couples.isLoading) return;
      // Fetch failed (offline, sync error): keep what the widget shows now.
      if (couples.couple == null && couples.errorMessage != null) return;
      _afterFrame(() => push(couples.couple));
    }
    couples.addListener(onChange);
    locales.addListener(onChange);
  }

  /// Tests only: lets a test bind its own fake providers.
  @visibleForTesting
  static void resetForTest() {
    _bound = false;
    _lastSent = null;
  }

  /// MaterialApp re-resolves the locale (AppL10n.setLocale) in the frame that
  /// follows a LocaleProvider change, so read the strings after that frame.
  /// scheduleFrame() guarantees a frame even when nothing else repaints.
  static void _afterFrame(VoidCallback fn) {
    SchedulerBinding.instance.addPostFrameCallback((_) => fn());
    SchedulerBinding.instance.scheduleFrame();
  }

  static Future<void> push(Couple? couple) async {
    Map<String, String>? snapshot;
    try {
      // build() formats dates with intl — main.dart ran initializeDateFormatting()
      // before runApp, and a widget refresh must never take the app down anyway.
      snapshot = HomeWidgetSnapshot.build(couple: couple, l10n: AppL10n.strings);
      if (mapEquals(snapshot, _lastSent)) return;
      await _channel.invokeMethod<void>('update', snapshot);
      _lastSent = snapshot; // only a delivered snapshot counts as sent
    } on MissingPluginException {
      _lastSent = snapshot; // no native side (web, tests): nothing to retry
    } catch (e) {
      // Left unsent on purpose: the next change retries the same snapshot.
      debugPrint('HomeWidgetBridge.update failed: $e');
    }
  }

  /// Logs `widget_tap` when the app was opened from the widget.
  static Future<void> consumeLaunch() async {
    if (kIsWeb) return;
    try {
      final family = await _channel.invokeMethod<String>('consumeLaunch');
      if (family == null || family.isEmpty) return;
      debugPrint('HomeWidgetBridge: opened from the $family widget');
      AnalyticsService.instance.logWidgetTap(family);
    } on MissingPluginException {
      // No native side.
    } catch (e) {
      debugPrint('HomeWidgetBridge.consumeLaunch failed: $e');
    }
  }
}
```

- [ ] **Step 3: Gắn vào `_MyAppState` (main.dart)**

Edit `lib/main.dart` — 7 chỗ, mỗi chỗ old → new:

(a) import — old:
```dart
import 'services/firebase_bootstrap_service.dart';
```
new:
```dart
import 'services/firebase_bootstrap_service.dart';
import 'services/home_widget_bridge.dart';
```
(b) field — old:
```dart
  late final AuthProvider _authProvider =
      AuthProvider(authService: widget.authService);
```
new:
```dart
  late final AuthProvider _authProvider =
      AuthProvider(authService: widget.authService);

  // Home-screen widget (feature home-widget): the bridge listens to these two,
  // so they are owned here instead of being created inside MultiProvider.
  final CoupleProvider _coupleProvider = CoupleProvider();
  late final LocaleProvider _localeProvider =
      LocaleProvider(initialLocale: widget.initialLocale);
```
(c) initState — old:
```dart
    WidgetsBinding.instance.addObserver(this);
    _authProvider.addListener(_handleAuthProviderChanged);
  }
```
new:
```dart
    WidgetsBinding.instance.addObserver(this);
    _authProvider.addListener(_handleAuthProviderChanged);
    HomeWidgetBridge.bind(_coupleProvider, _localeProvider);
    HomeWidgetBridge.consumeLaunch();
  }
```
(d) dispose — old:
```dart
    _authProvider.removeListener(_handleAuthProviderChanged);
    _authProvider.dispose();
    super.dispose();
```
new:
```dart
    _authProvider.removeListener(_handleAuthProviderChanged);
    _authProvider.dispose();
    _coupleProvider.dispose();
    _localeProvider.dispose();
    super.dispose();
```
(e) resume — old:
```dart
    if (state == AppLifecycleState.resumed) {
      _authProvider.refreshPushRegistration();
    }
```
new:
```dart
    if (state == AppLifecycleState.resumed) {
      _authProvider.refreshPushRegistration();
      HomeWidgetBridge.consumeLaunch();
    }
```
(f) provider couple — old:
```dart
        ChangeNotifierProvider(create: (_) => CoupleProvider()),
```
new:
```dart
        ChangeNotifierProvider<CoupleProvider>.value(value: _coupleProvider),
```
(g) provider locale — old:
```dart
        ChangeNotifierProvider(
          create: (_) => LocaleProvider(initialLocale: widget.initialLocale),
        ),
```
new:
```dart
        ChangeNotifierProvider<LocaleProvider>.value(value: _localeProvider),
```

- [ ] **Step 3b: Test bridge — không đẩy `empty` khi đang nạp / nạp lỗi, gửi mỗi snapshot một lần**

Create `test/home_widget_bridge_test.dart`:
```dart
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

  testWidgets('a failed update is retried on the next change', (tester) async {
    final couples = _FakeCouples();
    HomeWidgetBridge.resetForTest();
    HomeWidgetBridge.bind(couples, LocaleProvider());
    var failNext = true;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (failNext) {
        failNext = false;
        throw PlatformException(code: 'boom');
      }
      if (call.method == 'update') {
        sent.add(Map<String, String>.from(call.arguments as Map));
      }
      return null;
    });
    sent.clear();

    couples.emit(couple: couple);
    await tester.pump();
    expect(sent, isEmpty, reason: 'the first attempt failed');

    couples.emit(couple: couple);
    await tester.pump();
    expect(sent.length, 1, reason: 'the same snapshot is re-sent after a failure');
  });
}
```
Run: `flutter test test/home_widget_bridge_test.dart`
Expected: `All tests passed!` (2 test). Nếu một assertion fail chỉ vì microtask của channel chưa chạy, thêm một `await tester.pump();` nữa ngay sau lần pump đó (không đổi assertion).

- [ ] **Step 3c: SessionResolver quên couple khi đăng xuất / chưa xác thực email**

Đăng xuất và xoá tài khoản đi qua nhánh guest của `SessionResolver`; nhánh đó dọn mọi provider TRỪ `CoupleProvider` → `couple` cũ còn nguyên, bridge không có gì để đẩy `empty` (acceptance "đăng xuất → widget trống" hỏng). `loadCoupleForUser(null)` huỷ stream, null couple, xoá lỗi và notify — đúng nghĩa "không user → không couple".

Edit `lib/app/session_resolver.dart` — old:
```dart
      rpsGameProvider.clear();
      sleepProvider.clear();
      // No active couple: drop the daily-question nudge (b2). The on/off
      // preference is kept so it re-arms on the next sync once a couple loads.
      await reminderProvider.cancelDailyQuestionSchedule();
      return AppRoutes.guest;
```
new:
```dart
      rpsGameProvider.clear();
      sleepProvider.clear();
      // Signed out / account deleted: forget the couple too — the home-screen
      // widget bridge listens to CoupleProvider and pushes its empty state.
      await coupleProvider.loadCoupleForUser(null);
      // No active couple: drop the daily-question nudge (b2). The on/off
      // preference is kept so it re-arms on the next sync once a couple loads.
      await reminderProvider.cancelDailyQuestionSchedule();
      return AppRoutes.guest;
```
old:
```dart
      rpsGameProvider.clear();
      sleepProvider.clear();
      await reminderProvider.cancelDailyQuestionSchedule();
      return AppRoutes.verifyEmail;
```
new:
```dart
      rpsGameProvider.clear();
      sleepProvider.clear();
      await coupleProvider.loadCoupleForUser(null); // same reason as the guest branch
      await reminderProvider.cancelDailyQuestionSchedule();
      return AppRoutes.verifyEmail;
```

- [ ] **Step 4: Analyze + toàn bộ test**

Run: `flutter analyze && flutter test`
Expected: `No issues found!` và `All tests passed!` (các test cũ dùng `CoupleProvider`/`LocaleProvider` trực tiếp, không qua main.dart, nên không đổi).

- [ ] **Step 5: Commit**

```bash
git add lib/services/home_widget_bridge.dart lib/services/analytics_service.dart lib/main.dart lib/app/session_resolver.dart test/home_widget_bridge_test.dart
git commit -m "$(cat <<'EOF'
feat(home-widget): bridge gửi ảnh chụp sang native + event widget_tap

HomeWidgetBridge lắng nghe CoupleProvider/LocaleProvider (post-frame để lấy
đúng ngôn ngữ vừa đổi), gửi qua channel dear_embeiu/widget khi khác lần
trước; consumeLaunch khi mở/resume → Analytics widget_tap{family}. Couple +
Locale provider thành field của _MyAppState (.value).

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01Fe9gCYrrfgYjeuLy2WrVgg
EOF
)"
```

---

### Task 3: iOS `DayMath.swift` (mirror Dart) + kiểm bằng `swiftc`

**Files:**
- Create: `ios/DearEmbeiuWidget/DayMath.swift`
- Create: `scripts/widget-daymath-check/main.swift`, `scripts/check-widget-daymath.sh`

**Interfaces:**
- Produces (Task 4 dùng): `enum DayMath` với `static var gregorian: Calendar` (Gregorian + timeZone máy — mặc định, KHÔNG `.current`), `static func parseDate(_ s: String) -> DateComponents?`, `static func daysTogether(anniversary: String, today: Date, calendar: Calendar = DayMath.gregorian) -> Int`, `static func nextMilestone(_ days: Int) -> Int`, `static func progress(days: Int, next: Int) -> Double`, `static func milestoneLabel(_ next: Int, monthsOne: String, monthsFmt: String, yearsOne: String, yearsFmt: String, daysFmt: String, number: (Int) -> String) -> String`, `static func format(_ n: Int, lang: String) -> String`.

- [ ] **Step 1: Viết harness kiểm (fail trước)**

Create `scripts/widget-daymath-check/main.swift`:
```swift
import Foundation

// Feature home-widget: the widget's DayMath.swift must match Dart
// (LoveTreeService.daysTogether + _getNextMilestone in home_screen.dart) and
// the Kotlin DayMathTest — same vectors in all three. Run via
// scripts/check-widget-daymath.sh.

var failures = 0
func check(_ ok: Bool, _ what: String) {
  if !ok { failures += 1; print("FAIL: \(what)") }
}

var hcm = Calendar(identifier: .gregorian)
hcm.timeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh")!
let today = hcm.date(from: DateComponents(year: 2026, month: 10, day: 12, hour: 0, minute: 30))!

check(DayMath.daysTogether(anniversary: "2026-10-12", today: today, calendar: hcm) == 0, "same day = 0")
check(DayMath.daysTogether(anniversary: "2026-10-11", today: today, calendar: hcm) == 1, "yesterday = 1 even at 00:30")
check(DayMath.daysTogether(anniversary: "2025-10-12", today: today, calendar: hcm) == 365, "one year = 365")
check(DayMath.daysTogether(anniversary: "2023-05-14", today: today, calendar: hcm) == 1247, "mock couple = 1247")
check(DayMath.daysTogether(anniversary: "2026-10-13", today: today, calendar: hcm) == 0, "future date = 0, not -1")
check(DayMath.daysTogether(anniversary: "garbage", today: today, calendar: hcm) == 0, "bad input = 0")

var berlin = Calendar(identifier: .gregorian)
berlin.timeZone = TimeZone(identifier: "Europe/Berlin")!
let afterDst = berlin.date(from: DateComponents(year: 2026, month: 3, day: 30, hour: 0, minute: 30))!
check(DayMath.daysTogether(anniversary: "2026-03-29", today: afterDst, calendar: berlin) == 1, "DST change costs no day")
// Havana 2018-03-11: clocks jump at 00:00, so the anniversary's own midnight
// never exists — midnight-to-midnight counting would return 0 here.
var havana = Calendar(identifier: .gregorian)
havana.timeZone = TimeZone(identifier: "America/Havana")!
let havanaNoon = havana.date(from: DateComponents(year: 2018, month: 3, day: 12, hour: 12))!
check(DayMath.daysTogether(anniversary: "2018-03-11", today: havanaNoon, calendar: havana) == 1, "DST skipping the anniversary's own midnight still counts the day")
check(DayMath.gregorian.identifier == .gregorian, "default calendar is Gregorian whatever the device setting (Dart parity)")
// check-widget-daymath.sh runs this binary with `-AppleLocale th_TH` (Buddhist
// calendar), so the default-calendar path must still count in Gregorian.
let noon = DayMath.gregorian.date(from: DateComponents(year: 2026, month: 10, day: 12, hour: 12))!
check(DayMath.daysTogether(anniversary: "2023-05-14", today: noon) == 1247, "default path counts Gregorian even under th_TH (Buddhist) locale")

let table: [(Int, Int)] = [(0, 30), (29, 30), (30, 50), (364, 365), (365, 500), (1247, 1500),
                           (2999, 3000), (3000, 3500), (3499, 3500), (3500, 4000)]
for (days, next) in table { check(DayMath.nextMilestone(days) == next, "next(\(days)) == \(next)") }

check(abs(DayMath.progress(days: 1247, next: 1500) - 0.8313) < 0.001, "progress = days / next")
check(DayMath.progress(days: 10, next: 5) == 1, "progress clamps to 1")
check(DayMath.format(1500, lang: "vi") == "1.500", "vi groups with a dot")
check(DayMath.format(1500, lang: "en") == "1,500", "en groups with a comma")

func label(_ n: Int) -> String {
  DayMath.milestoneLabel(n, monthsOne: "1 tháng", monthsFmt: "{count} tháng",
                         yearsOne: "1 năm", yearsFmt: "{count} năm", daysFmt: "{count} ngày",
                         number: { DayMath.format($0, lang: "vi") })
}
check(label(30) == "1 tháng", "30 → 1 tháng")
check(label(180) == "6 tháng", "180 → 6 tháng")
check(label(365) == "1 năm", "365 → 1 năm")
check(label(730) == "2 năm", "730 → 2 năm")
check(label(1500) == "1.500 ngày", "1500 → 1.500 ngày")
check(label(50) == "50 ngày", "50 → 50 ngày")

if failures > 0 { print("\(failures) check(s) failed"); exit(1) }
print("OK DayMath — \(table.count + 20) checks")
```

Create `scripts/check-widget-daymath.sh`:
```bash
#!/bin/bash
# Feature home-widget: compile the widget's DayMath.swift with the check
# harness (scripts/widget-daymath-check/main.swift) as a plain macOS binary and
# run it. No Xcode project, no simulator — a few seconds.
set -euo pipefail
cd "$(dirname "$0")/.."
OUT="$(mktemp -d)/daymath"
xcrun swiftc -O ios/DearEmbeiuWidget/DayMath.swift scripts/widget-daymath-check/main.swift -o "$OUT"
# -AppleLocale th_TH makes Calendar.current Buddhist for this process: the
# default-calendar check only means something under a non-Gregorian locale.
"$OUT" -AppleLocale th_TH
```
Run: `chmod +x scripts/check-widget-daymath.sh && scripts/check-widget-daymath.sh`
Expected: FAIL — `error: no such file or directory: 'ios/DearEmbeiuWidget/DayMath.swift'`.

- [ ] **Step 2: Viết `DayMath.swift`**

Create `ios/DearEmbeiuWidget/DayMath.swift`:
```swift
import Foundation

/// Day count + next milestone for the home-screen widget. Mirrors Dart
/// (`LoveTreeService.daysTogether`, `_getNextMilestone` / `_milestoneLabel` in
/// home_screen.dart) and `DayMath.kt` on Android — change all three together or
/// the widget drifts from the Home counter. Foundation only: also compiled by
/// scripts/check-widget-daymath.sh outside Xcode.
enum DayMath {
  static let milestones = [30, 50, 100, 180, 365, 500, 730, 1000, 1500, 2000, 3000]

  /// `YYYY-MM-DD` (the snapshot's `anniversary`) → year/month/day.
  static func parseDate(_ s: String) -> DateComponents? {
    let parts = s.split(separator: "-").compactMap { Int($0) }
    guard parts.count == 3 else { return nil }
    return DateComponents(year: parts[0], month: parts[1], day: parts[2])
  }

  /// Dart counts in the Gregorian calendar (DateTime). `Calendar.current` follows
  /// the device setting and can be Buddhist/Japanese, which would read "2023"
  /// as another year — so default to Gregorian in the device's time zone.
  static var gregorian: Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = .current
    return calendar
  }

  /// Calendar days from the anniversary to `today`, exactly like Dart
  /// (`LoveTreeService.daysTogether`): take today's local y/m/d in `calendar`,
  /// then subtract the two dates in a UTC calendar, so no DST hour can move a
  /// day. (Midnight-to-midnight in the local calendar misses one when DST skips
  /// the anniversary's own 00:00 — Havana 2018-03-11; `ordinality(.day, in:
  /// .era)` counts UTC day boundaries.) Never below 0 (future date = day 0).
  static func daysTogether(anniversary: String, today: Date, calendar: Calendar = DayMath.gregorian) -> Int {
    guard let start = parseDate(anniversary) else { return 0 }
    let end = calendar.dateComponents([.year, .month, .day], from: today)
    var utc = Calendar(identifier: .gregorian)
    utc.timeZone = TimeZone(secondsFromGMT: 0)!
    guard let s = utc.date(from: start), let e = utc.date(from: end) else { return 0 }
    return max(0, utc.dateComponents([.day], from: s, to: e).day ?? 0)
  }

  static func nextMilestone(_ days: Int) -> Int {
    milestones.first { days < $0 } ?? ((days / 500) + 1) * 500
  }

  /// The Home progress bar: days / next, clamped to 0…1.
  static func progress(days: Int, next: Int) -> Double {
    guard next > 0 else { return 0 }
    return min(1, max(0, Double(days) / Double(next)))
  }

  /// "6 tháng" / "1 năm" / "1.500 ngày" from the snapshot's templates.
  static func milestoneLabel(_ next: Int, monthsOne: String, monthsFmt: String,
                             yearsOne: String, yearsFmt: String, daysFmt: String,
                             number: (Int) -> String) -> String {
    if next % 365 == 0 {
      let n = next / 365
      return n == 1 ? yearsOne : yearsFmt.replacingOccurrences(of: "{count}", with: number(n))
    }
    if next < 365 && next % 30 == 0 {
      let n = next / 30
      return n == 1 ? monthsOne : monthsFmt.replacingOccurrences(of: "{count}", with: number(n))
    }
    return daysFmt.replacingOccurrences(of: "{count}", with: number(next))
  }

  /// Grouped integer in the app's language (vi → 1.500, en → 1,500) — the
  /// approved widget design; Home still prints the raw number (noted in
  /// overview.md as a follow-up).
  static func format(_ n: Int, lang: String) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.locale = Locale(identifier: lang == "vi" ? "vi_VN" : "en_US")
    return formatter.string(from: NSNumber(value: n)) ?? String(n)
  }
}
```

- [ ] **Step 3: Chạy kiểm, phải PASS**

Run: `scripts/check-widget-daymath.sh`
Expected: `OK DayMath — 30 checks`.

- [ ] **Step 4: Commit**

```bash
git add ios/DearEmbeiuWidget/DayMath.swift scripts/widget-daymath-check/main.swift scripts/check-widget-daymath.sh
git commit -m "$(cat <<'EOF'
feat(home-widget): DayMath.swift mirror công thức Home + kiểm bằng swiftc

Đếm ngày như Dart (y/m/d → hiệu ngày trong lịch UTC; DST/lịch Phật không
lệch), bảng cột mốc [30…3000] bước 500, tiến độ days/next, nhãn
tháng/năm/ngày, format số theo vi/en. scripts/check-widget-daymath.sh: 30
check dưới -AppleLocale th_TH, không cần Xcode project.

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01Fe9gCYrrfgYjeuLy2WrVgg
EOF
)"
```

---

### Task 4: Target WidgetKit `DearEmbeiuWidget` + channel iOS + App Group

**Files:**
- Create: `ios/DearEmbeiuWidget/WidgetSnapshot.swift`, `ios/DearEmbeiuWidget/DayCounterWidget.swift`, `ios/DearEmbeiuWidget/DayCounterView.swift`, `ios/DearEmbeiuWidget/Info.plist`, `ios/DearEmbeiuWidget/DearEmbeiuWidget.entitlements`, `ios/DearEmbeiuWidget/PrivacyInfo.xcprivacy`, `ios/DearEmbeiuWidget/en.lproj/Localizable.strings`, `ios/DearEmbeiuWidget/vi.lproj/Localizable.strings`
- Create: `scripts/ios-add-widget-target.rb`, `scripts/ios-add-widget-target.sh`
- Modify: `ios/Runner/Runner.entitlements`, `ios/Runner/Info.plist:81-82`, `ios/Runner/PrivacyInfo.xcprivacy:64-71` (+`1C8F.1`), `ios/Runner/AppDelegate.swift:1-6,23-28` + cuối file, `ios/Runner/SceneDelegate.swift` (thay toàn bộ)
- Generated: `ios/Runner.xcodeproj/project.pbxproj` (do script sửa — commit)

**Interfaces:**
- Consumes: `DayMath` (Task 3); ảnh chụp key theo Task 1; channel method `update`/`consumeLaunch` theo Task 2.
- Produces: `HomeWidgetChannel.register(messenger:)`, `HomeWidgetChannel.recordLaunch(url:)`; store key `widget_snapshot` trong `UserDefaults(suiteName: AppGroupId)`; cờ `widget_launch_family` trong `UserDefaults.standard`; URL chạm `dearembeiu://widget?family=small|medium`.

- [ ] **Step 1: `WidgetSnapshot.swift` — đọc kho + model hiển thị**

Create `ios/DearEmbeiuWidget/WidgetSnapshot.swift`:
```swift
import Foundation

/// The map Flutter pushes over `dear_embeiu/widget` (key list:
/// lib/services/home_widget_snapshot.dart). The app stores it in the shared
/// App Group; the widget reads it at render time.
struct WidgetSnapshot {
  static let storeKey = "widget_snapshot"
  let raw: [String: String]

  subscript(_ key: String) -> String { raw[key] ?? "" }
  var isCounter: Bool { self["state"] == "counter" }
  var lang: String { self["lang"].isEmpty ? "vi" : self["lang"] }

  /// `AppGroupId` in Info.plist = `$(APP_GROUP_ID)` build setting, so the dev
  /// and prod apps never read each other's store.
  static var groupId: String? {
    Bundle.main.object(forInfoDictionaryKey: "AppGroupId") as? String
  }

  static func load() -> WidgetSnapshot? {
    guard let group = groupId,
          let defaults = UserDefaults(suiteName: group),
          let raw = defaults.dictionary(forKey: storeKey) as? [String: String] else { return nil }
    return WidgetSnapshot(raw: raw)
  }

  /// Widget gallery preview only — fixed 1247 days, strings from the
  /// extension's Localizable.strings (the one place native holds copy, D4).
  static var preview: WidgetSnapshot {
    func s(_ key: String) -> String { NSLocalizedString(key, comment: "") }
    let calendar = DayMath.gregorian // the snapshot date is Gregorian (Dart parity)
    let start = calendar.date(byAdding: .day, value: -1247, to: Date()) ?? Date()
    let c = calendar.dateComponents([.year, .month, .day], from: start)
    let anniversary = String(format: "%04d-%02d-%02d", c.year ?? 2023, c.month ?? 5, c.day ?? 14)
    return WidgetSnapshot(raw: [
      "state": "counter", "lang": s("preview_lang"), "anniversary": anniversary,
      "name1": s("preview_name1"), "name2": s("preview_name2"),
      "daysLabel": s("preview_days_label"), "milestoneFmt": s("preview_milestone_fmt"),
      "daysLeftOne": s("preview_days_left_one"), "daysLeftFmt": s("preview_days_left_fmt"),
      "todayLabel": "", "monthsOne": "", "monthsFmt": "{count}", "yearsOne": "", "yearsFmt": "{count}",
      "daysFmt": s("preview_days_fmt"), "sinceText": s("preview_since"),
    ])
  }
}

/// Everything the view prints, computed once per timeline entry.
struct DayModel {
  let name1: String
  let name2: String
  let daysText: String
  let daysLabel: String
  let milestoneText: String
  let daysLeftText: String
  let sinceText: String
  let progress: Double

  init(snapshot s: WidgetSnapshot, today: Date) {
    let days = DayMath.daysTogether(anniversary: s["anniversary"], today: today)
    let next = DayMath.nextMilestone(days)
    let number = { (n: Int) in DayMath.format(n, lang: s.lang) }
    let label = DayMath.milestoneLabel(next, monthsOne: s["monthsOne"], monthsFmt: s["monthsFmt"],
                                       yearsOne: s["yearsOne"], yearsFmt: s["yearsFmt"],
                                       daysFmt: s["daysFmt"], number: number)
    let left = next - days
    name1 = s["name1"]
    name2 = s["name2"]
    daysText = number(days)
    daysLabel = s["daysLabel"]
    milestoneText = s["milestoneFmt"].replacingOccurrences(of: "{label}", with: label)
    daysLeftText = left <= 0 ? s["todayLabel"]
      : left == 1 ? s["daysLeftOne"]
      : s["daysLeftFmt"].replacingOccurrences(of: "{count}", with: number(left))
    sinceText = s["sinceText"]
    progress = DayMath.progress(days: days, next: next)
  }
}
```

- [ ] **Step 2: `DayCounterWidget.swift` — timeline 7 nửa đêm**

Create `ios/DearEmbeiuWidget/DayCounterWidget.swift`:
```swift
import SwiftUI
import WidgetKit

struct DayEntry: TimelineEntry {
  let date: Date
  let snapshot: WidgetSnapshot?
}

/// One entry now + one per midnight for the next 7 days: the count ticks over
/// at 0:00 without the app running. `.atEnd` asks WidgetKit for 7 more then.
struct DayProvider: TimelineProvider {
  func placeholder(in context: Context) -> DayEntry {
    DayEntry(date: Date(), snapshot: .preview)
  }

  func getSnapshot(in context: Context, completion: @escaping (DayEntry) -> Void) {
    completion(DayEntry(date: Date(), snapshot: context.isPreview ? .preview : WidgetSnapshot.load()))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<DayEntry>) -> Void) {
    let snapshot = WidgetSnapshot.load()
    let calendar = Calendar.current
    var entries = [DayEntry(date: Date(), snapshot: snapshot)]
    var day = calendar.startOfDay(for: Date())
    for _ in 0..<7 {
      guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
      day = next
      entries.append(DayEntry(date: day, snapshot: snapshot))
    }
    completion(Timeline(entries: entries, policy: .atEnd))
  }
}

@main
struct DayCounterWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "DayCounter", provider: DayProvider()) { entry in
      DayCounterView(entry: entry)
    }
    .configurationDisplayName(LocalizedStringKey("widget_display_name"))
    .description(LocalizedStringKey("widget_description"))
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}
```

- [ ] **Step 3: `DayCounterView.swift` — giao diện A**

Create `ios/DearEmbeiuWidget/DayCounterView.swift`:
```swift
import SwiftUI
import WidgetKit

// Design tokens — project/features/home-widget/design.md (hướng A).
private extension Color {
  init(hex: UInt32, opacity: Double = 1) {
    self.init(.sRGB,
              red: Double((hex >> 16) & 0xFF) / 255,
              green: Double((hex >> 8) & 0xFF) / 255,
              blue: Double(hex & 0xFF) / 255,
              opacity: opacity)
  }
}
private let navy = Color(hex: 0x1A1A2E)
private let loveDeep = Color(hex: 0xE63956)
private let lavender = Color(hex: 0xA78BFA)

private extension Font {
  /// Quicksand is bundled in the extension (Info.plist UIAppFonts).
  static func quicksand(_ weight: String, _ size: CGFloat) -> Font {
    .custom("Quicksand-\(weight)", size: size)
  }
}

private extension View {
  /// White-on-gradient text rule: a soft DARK shadow, never a halo.
  func inkShadow(_ opacity: Double = 0.30) -> some View {
    shadow(color: .black.opacity(opacity), radius: 4, y: 1)
  }

  /// iOS 17+: system draws the background + content margins. Earlier: we do.
  @ViewBuilder func widgetBackground<B: View>(_ background: B) -> some View {
    if #available(iOS 17.0, *) {
      containerBackground(for: .widget) { background }
    } else {
      ZStack { background; padding(14) }
    }
  }

  /// iOS 18 tinted mode renders accentable views in the user's tint.
  @ViewBuilder func accentable() -> some View {
    if #available(iOS 16.0, *) { widgetAccentable() } else { self }
  }
}

/// Tells its content whether the system is painting the widget in a single
/// tint (iOS 18 "Tinted", iOS 26 "Clear"): every fill becomes the tint, so a
/// solid pill under tinted text has no contrast (smoke Task 5 measured 1.05:1).
/// iOS 15 has no such mode → always false.
struct AccentedReader<Content: View>: View {
  @ViewBuilder let content: (Bool) -> Content
  var body: some View {
    if #available(iOS 16.0, *) {
      RenderingModeReader(content: content)
    } else {
      content(false)
    }
  }
}

@available(iOS 16.0, *)
private struct RenderingModeReader<Content: View>: View {
  @Environment(\.widgetRenderingMode) private var mode
  let content: (Bool) -> Content
  var body: some View { content(mode == .accented) }
}

struct DayCounterView: View {
  @Environment(\.widgetFamily) private var family
  let entry: DayEntry

  private var familyName: String { family == .systemMedium ? "medium" : "small" }

  var body: some View {
    content
      .widgetBackground(WidgetBackground(medium: family == .systemMedium))
      .widgetURL(URL(string: "dearembeiu://widget?family=\(familyName)"))
  }

  @ViewBuilder private var content: some View {
    if let snapshot = entry.snapshot, snapshot.isCounter {
      let model = DayModel(snapshot: snapshot, today: entry.date)
      if family == .systemMedium {
        MediumCounter(model: model)
      } else {
        SmallCounter(model: model)
      }
    } else {
      EmptyState(chip: entry.snapshot?["emptyChip"] ?? "DEAR EMBEIU",
                 text: entry.snapshot?["emptyText"] ?? NSLocalizedString("empty_tap", comment: ""))
    }
  }
}

/// Gradient 150° + dark scrim + two aurora glows, like the Home CounterCard.
/// The medium widget gets the larger glows from design.md (Ø110 / Ø160).
struct WidgetBackground: View {
  let medium: Bool
  var body: some View {
    ZStack {
      LinearGradient(stops: [
        .init(color: Color(hex: 0xFF5C8F), location: 0),
        .init(color: Color(hex: 0xFF4D6D), location: 0.55),
        .init(color: Color(hex: 0xE63956), location: 1),
      ], startPoint: .topLeading, endPoint: .bottomTrailing)
      LinearGradient(colors: [.black.opacity(0.10), .black.opacity(0.28)],
                     startPoint: .top, endPoint: .bottom)
      Circle().fill(Color.white.opacity(0.26))
        .frame(width: medium ? 110 : 96, height: medium ? 110 : 96).blur(radius: 18)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .offset(x: -28, y: -30)
      Circle().fill(lavender.opacity(0.40))
        .frame(width: medium ? 160 : 120, height: medium ? 160 : 120).blur(radius: medium ? 20 : 18)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        .offset(x: 40, y: medium ? 56 : 46)
    }
  }
}

/// "TUẤN ♥ THẢO" — white pill, navy ink (small white text on pink fails 4.5:1).
/// Tinted/Clear: the pill drops to .22 and the names stay full-tint on top.
struct NamesChip: View {
  let name1: String
  let name2: String

  var body: some View {
    AccentedReader { accented in
      // .kerning on a container is iOS 16+; on Text it is iOS 13+, so per Text.
      HStack(spacing: 5) {
        if !name1.isEmpty { Text(name1).kerning(1) }
        if !name1.isEmpty && !name2.isEmpty {
          Image(systemName: "heart.fill")
            .font(.system(size: 9, weight: .bold))
            .foregroundColor(loveDeep)
            .accessibilityHidden(true)
        }
        if !name2.isEmpty { Text(name2).kerning(1) }
      }
      .font(.quicksand("Bold", 10))
      .textCase(.uppercase)
      .lineLimit(1)
      .foregroundColor(navy)
      .accentable()
      .padding(.horizontal, 8)
      .frame(height: 20)
      .background(Capsule().fill(Color.white.opacity(accented ? 0.22 : 0.84)))
    }
  }
}

struct DayNumber: View {
  let text: String
  var body: some View {
    Text(text)
      .font(.quicksand("Bold", 40))
      .kerning(-1)
      .foregroundColor(.white)
      .lineLimit(1)
      .minimumScaleFactor(0.6)
      .inkShadow()
      .accentable()
  }
}

struct Caption: View {
  let text: String
  var body: some View {
    Text(text)
      .font(.quicksand("SemiBold", 12))
      .foregroundColor(.white.opacity(0.92))
      .lineLimit(2)
      .inkShadow(0.28)
      .accentable()
  }
}

/// Accentable per element (number, caption, chip text) — never on a container
/// that also holds the chip pill (see NamesChip).
struct SmallCounter: View {
  let model: DayModel
  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      NamesChip(name1: model.name1, name2: model.name2)
      Spacer(minLength: 4)
      DayNumber(text: model.daysText)
      Caption(text: model.daysLabel).padding(.top, 6)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
  }
}

struct ProgressBar: View {
  let value: Double
  var body: some View {
    GeometryReader { g in
      ZStack(alignment: .leading) {
        Capsule().fill(Color.white.opacity(0.26))
        Capsule().fill(Color.white.opacity(0.96)).frame(width: max(6, g.size.width * value))
      }
    }
    .frame(height: 6)
  }
}

struct MediumCounter: View {
  let model: DayModel
  var body: some View {
    HStack(spacing: 0) {
      SmallCounter(model: model).frame(width: 150)
      Rectangle().fill(Color.white.opacity(0.28)).frame(width: 1)
        .padding(.horizontal, 14).padding(.vertical, 2)
      VStack(alignment: .leading, spacing: 8) {
        // "Milestone: 10,000 days" is ~131pt at 12; the column is 110–127pt
        // across iPhones, so the line may shrink to ~10 instead of clipping.
        Text(model.milestoneText)
          .font(.quicksand("Bold", 12)).foregroundColor(.white).lineLimit(1)
          .minimumScaleFactor(0.85).inkShadow(0.28)
        ProgressBar(value: model.progress)
        Caption(text: model.daysLeftText)
        Spacer(minLength: 0)
        // "Bắt đầu từ 28 thg 12, 2023" is 133pt — two lines rather than losing the year.
        Text(model.sinceText)
          .font(.quicksand("Medium", 11)).foregroundColor(.white.opacity(0.84)).lineLimit(2).inkShadow(0.28)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
      .accentable()
    }
  }
}

struct EmptyState: View {
  let chip: String
  let text: String
  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      AccentedReader { accented in
        HStack(spacing: 5) {
          Image(systemName: "heart.fill")
            .font(.system(size: 9, weight: .bold)).foregroundColor(loveDeep).accessibilityHidden(true)
          Text(chip).kerning(1)
        }
        .font(.quicksand("Bold", 10)).lineLimit(1).foregroundColor(navy)
        .accentable() // same as NamesChip: faint pill under full-tint text when tinted
        .padding(.horizontal, 8).frame(height: 20)
        .background(Capsule().fill(Color.white.opacity(accented ? 0.22 : 0.84)))
      }
      Spacer(minLength: 4)
      Text(text)
        .font(.quicksand("Bold", 14)).foregroundColor(.white).lineLimit(3).inkShadow()
        .accentable()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
  }
}
```

- [ ] **Step 4: Info.plist, entitlements, privacy, strings của widget**

Create `ios/DearEmbeiuWidget/Info.plist`:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key>
	<string>$(DEVELOPMENT_LANGUAGE)</string>
	<key>CFBundleDisplayName</key>
	<string>Dear Embeiu</string>
	<key>CFBundleExecutable</key>
	<string>$(EXECUTABLE_NAME)</string>
	<key>CFBundleIdentifier</key>
	<string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleName</key>
	<string>$(PRODUCT_NAME)</string>
	<key>CFBundlePackageType</key>
	<string>$(PRODUCT_BUNDLE_PACKAGE_TYPE)</string>
	<key>CFBundleShortVersionString</key>
	<string>$(MARKETING_VERSION)</string>
	<key>CFBundleVersion</key>
	<string>$(CURRENT_PROJECT_VERSION)</string>
	<key>CFBundleLocalizations</key>
	<array>
		<string>en</string>
		<string>vi</string>
	</array>
	<key>AppGroupId</key>
	<string>$(APP_GROUP_ID)</string>
	<key>UIAppFonts</key>
	<array>
		<string>Quicksand-Bold.ttf</string>
		<string>Quicksand-SemiBold.ttf</string>
		<string>Quicksand-Medium.ttf</string>
	</array>
	<key>NSExtension</key>
	<dict>
		<key>NSExtensionPointIdentifier</key>
		<string>com.apple.widgetkit-extension</string>
	</dict>
</dict>
</plist>
```
Create `ios/DearEmbeiuWidget/DearEmbeiuWidget.entitlements`:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>com.apple.security.application-groups</key>
	<array>
		<string>$(APP_GROUP_ID)</string>
	</array>
</dict>
</plist>
```
Create `ios/DearEmbeiuWidget/PrivacyInfo.xcprivacy`:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>NSPrivacyTracking</key>
	<false/>
	<key>NSPrivacyTrackingDomains</key>
	<array/>
	<key>NSPrivacyCollectedDataTypes</key>
	<array/>
	<key>NSPrivacyAccessedAPITypes</key>
	<array>
		<!-- Reads the App Group UserDefaults the app writes: reason 1C8F.1
		     (shared within the same App Group), not CA92.1 (app-private only). -->
		<dict>
			<key>NSPrivacyAccessedAPIType</key>
			<string>NSPrivacyAccessedAPICategoryUserDefaults</string>
			<key>NSPrivacyAccessedAPITypeReasons</key>
			<array>
				<string>1C8F.1</string>
			</array>
		</dict>
	</array>
</dict>
</plist>
```
Create `ios/DearEmbeiuWidget/vi.lproj/Localizable.strings`:
```
/* Gallery widget (hệ thống hiện trước khi có dữ liệu) + trạng thái trống khi app chưa mở lần nào sau bản này. Mọi chuỗi khác do Flutter gửi (D4). */
"widget_display_name" = "Đếm ngày yêu";
"widget_description" = "Số ngày chúng mình bên nhau, cập nhật mỗi ngày.";
"empty_tap" = "Chạm để bắt đầu đếm ngày yêu";
"preview_lang" = "vi";
"preview_name1" = "Anh";
"preview_name2" = "Em";
"preview_days_label" = "ngày bên nhau";
"preview_milestone_fmt" = "Cột mốc {label}";
"preview_days_left_one" = "còn 1 ngày";
"preview_days_left_fmt" = "còn {count} ngày";
"preview_days_fmt" = "{count} ngày";
"preview_since" = "Bắt đầu từ 14 thg 5, 2023";
```
Create `ios/DearEmbeiuWidget/en.lproj/Localizable.strings`:
```
/* Widget gallery (shown before any data exists) + empty state when the app has not been opened since this build. Everything else comes from Flutter (D4). */
"widget_display_name" = "Day counter";
"widget_description" = "Your days together, updated every day.";
"empty_tap" = "Tap to start counting your days together";
"preview_lang" = "en";
"preview_name1" = "Me";
"preview_name2" = "You";
"preview_days_label" = "days together";
"preview_milestone_fmt" = "Milestone: {label}";
"preview_days_left_one" = "1 day left";
"preview_days_left_fmt" = "{count} days left";
"preview_days_fmt" = "{count} days";
"preview_since" = "Since May 14, 2023";
```

- [ ] **Step 5: Runner — App Group + `AppGroupId` + channel + ghi cờ URL + lý do UserDefaults**

Edit `ios/Runner/PrivacyInfo.xcprivacy` (Runner nay ghi UserDefaults dùng chung App Group → thêm lý do `1C8F.1` cạnh `CA92.1`) — old:
```xml
			<key>NSPrivacyAccessedAPIType</key>
			<string>NSPrivacyAccessedAPICategoryUserDefaults</string>
			<key>NSPrivacyAccessedAPITypeReasons</key>
			<array>
				<string>CA92.1</string>
			</array>
```
new:
```xml
			<key>NSPrivacyAccessedAPIType</key>
			<string>NSPrivacyAccessedAPICategoryUserDefaults</string>
			<key>NSPrivacyAccessedAPITypeReasons</key>
			<array>
				<string>CA92.1</string>
				<string>1C8F.1</string>
			</array>
```
Edit `ios/Runner/Runner.entitlements` — old:
```xml
	<key>com.apple.developer.healthkit.access</key>
	<array/>
</dict>
```
new:
```xml
	<key>com.apple.developer.healthkit.access</key>
	<array/>
	<key>com.apple.security.application-groups</key>
	<array>
		<string>$(APP_GROUP_ID)</string>
	</array>
</dict>
```
Edit `ios/Runner/Info.plist` — old:
```xml
		<key>CFBundleVersion</key>
		<string>$(FLUTTER_BUILD_NUMBER)</string>
```
new:
```xml
		<key>CFBundleVersion</key>
		<string>$(FLUTTER_BUILD_NUMBER)</string>
		<key>AppGroupId</key>
		<string>$(APP_GROUP_ID)</string>
```
(Khoá mới đặt NGAY SAU `CFBundleVersion`, trên comment D8 — chèn giữa comment và `FlutterDeepLinkingEnabled` thì comment đứng nhầm trên khoá mới.)
Edit `ios/Runner/AppDelegate.swift` — old:
```swift
import UIKit
import UserNotifications
```
new:
```swift
import UIKit
import UserNotifications
import WidgetKit
```
old:
```swift
      AppleIdStateChannel.register(messenger: registrar.messenger())
    }
```
new:
```swift
      AppleIdStateChannel.register(messenger: registrar.messenger())
      HomeWidgetChannel.register(messenger: registrar.messenger())
    }
```
Thêm vào CUỐI file `ios/Runner/AppDelegate.swift`:
```swift

/// Feature home-widget (D3/D8): Dart pushes the pre-translated snapshot, we
/// store it in the App Group and ask WidgetKit to redraw. A widget tap opens
/// `dearembeiu://widget?family=…`; the family is parked in UserDefaults until
/// Dart asks (`consumeLaunch`) so Analytics gets one `widget_tap` per tap.
final class HomeWidgetChannel {
  static let snapshotKey = "widget_snapshot"
  static let launchKey = "widget_launch_family"

  private static var groupDefaults: UserDefaults? {
    guard let group = Bundle.main.object(forInfoDictionaryKey: "AppGroupId") as? String else { return nil }
    return UserDefaults(suiteName: group)
  }

  static func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "dear_embeiu/widget", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "update":
        guard let snapshot = call.arguments as? [String: String] else {
          result(FlutterError(code: "bad_args", message: "expected Map<String,String>", details: nil))
          return
        }
        groupDefaults?.set(snapshot, forKey: snapshotKey)
        if #available(iOS 14.0, *) { WidgetCenter.shared.reloadAllTimelines() }
        result(nil)
      case "consumeLaunch":
        let family = UserDefaults.standard.string(forKey: launchKey)
        UserDefaults.standard.removeObject(forKey: launchKey)
        result(family)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  /// Called from SceneDelegate for every URL the app is opened with.
  static func recordLaunch(url: URL) {
    guard url.scheme == "dearembeiu", url.host == "widget" else { return }
    let family = URLComponents(url: url, resolvingAgainstBaseURL: false)?
      .queryItems?.first(where: { $0.name == "family" })?.value ?? "unknown"
    UserDefaults.standard.set(family, forKey: launchKey)
  }
}
```
Thay toàn bộ `ios/Runner/SceneDelegate.swift`:
```swift
import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {
  // Feature home-widget: note which widget opened the app (cold start carries
  // the URL in connectionOptions, warm start in openURLContexts). Flutter's own
  // deep linking stays off (audit D8) — the app only needs to come to the front.
  override func scene(_ scene: UIScene, willConnectTo session: UISceneSession,
                      options connectionOptions: UIScene.ConnectionOptions) {
    connectionOptions.urlContexts.forEach { HomeWidgetChannel.recordLaunch(url: $0.url) }
    super.scene(scene, willConnectTo: session, options: connectionOptions)
  }

  override func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    URLContexts.forEach { HomeWidgetChannel.recordLaunch(url: $0.url) }
    super.scene(scene, openURLContexts: URLContexts)
  }
}
```
Nếu Step 8 báo `method does not override any method from its superclass` cho một trong hai hàm: bỏ từ khoá `override` và lời gọi `super.` của đúng hàm đó (FlutterSceneDelegate của bản Flutter này không khai hàm ấy) — giữ phần ghi cờ.

- [ ] **Step 6: Script thêm target vào `Runner.xcodeproj`**

Create `scripts/ios-add-widget-target.rb`:
```ruby
#!/usr/bin/env ruby
# Feature home-widget: adds the DearEmbeiuWidget (WidgetKit) extension target to
# ios/Runner.xcodeproj — sources, fonts from assets/fonts, en/vi strings, build
# settings per configuration, App Group on Runner, embed phase. Idempotent.
# Run through scripts/ios-add-widget-target.sh (needs the xcodeproj gem).
require 'xcodeproj'

PROJECT = File.expand_path('../ios/Runner.xcodeproj', __dir__)
NAME = 'DearEmbeiuWidget'
TEAM = '4UBR69C227'

project = Xcodeproj::Project.open(PROJECT)
if project.targets.any? { |t| t.name == NAME }
  puts "#{NAME} already in the project — nothing to do"
  exit 0
end
runner = project.targets.find { |t| t.name == 'Runner' } or abort 'Runner target not found'
generated = project.files.find { |f| f.display_name == 'Generated.xcconfig' } or
  abort 'Flutter/Generated.xcconfig missing — run `flutter build ios --config-only` first'

widget = project.new_target(:app_extension, NAME, :ios, '15.0')
group = project.main_group.new_group(NAME, NAME)

sources = %w[DayMath.swift WidgetSnapshot.swift DayCounterWidget.swift DayCounterView.swift]
widget.add_file_references(sources.map { |f| group.new_file(f) })

# Absolute paths: xcodeproj stores them relative to the group (ios/DearEmbeiuWidget),
# so a hand-written "../assets" would point at ios/assets, which does not exist.
fonts = %w[Bold SemiBold Medium].map do |w|
  group.new_file(File.expand_path("../assets/fonts/Quicksand-#{w}.ttf", __dir__))
end
strings = group.new_variant_group('Localizable.strings')
%w[en vi].each { |lang| strings.new_file("#{lang}.lproj/Localizable.strings") }
privacy = group.new_file('PrivacyInfo.xcprivacy')
widget.add_resources(fonts + [strings, privacy])
group.new_file('Info.plist')
group.new_file("#{NAME}.entitlements")

def dev?(config) = %w[Debug Profile].include?(config.name)

widget.build_configurations.each do |c|
  c.base_configuration_reference = generated # FLUTTER_BUILD_NAME / NUMBER
  c.build_settings.merge!(
    'INFOPLIST_FILE' => "#{NAME}/Info.plist",
    'GENERATE_INFOPLIST_FILE' => 'NO',
    'CODE_SIGN_ENTITLEMENTS' => "#{NAME}/#{NAME}.entitlements",
    'CODE_SIGN_STYLE' => 'Automatic',
    'DEVELOPMENT_TEAM' => TEAM,
    'PRODUCT_NAME' => '$(TARGET_NAME)', # xcodeproj leaves it empty -> product ".appex" (Multiple commands produce)
    'PRODUCT_BUNDLE_IDENTIFIER' => dev?(c) ? 'com.tony.dearembeiu.dev.widget' : 'com.tony.dearembeiu.widget',
    'APP_GROUP_ID' => dev?(c) ? 'group.com.tony.dearembeiu.dev' : 'group.com.tony.dearembeiu',
    'MARKETING_VERSION' => '$(FLUTTER_BUILD_NAME)',
    'CURRENT_PROJECT_VERSION' => '$(FLUTTER_BUILD_NUMBER)',
    'IPHONEOS_DEPLOYMENT_TARGET' => '15.0',
    'TARGETED_DEVICE_FAMILY' => '1',
    'SWIFT_VERSION' => '5.0',
    'SKIP_INSTALL' => 'YES',
    'LD_RUNPATH_SEARCH_PATHS' => ['$(inherited)', '@executable_path/Frameworks', '@executable_path/../../Frameworks'],
  )
end

runner.build_configurations.each do |c|
  c.build_settings['APP_GROUP_ID'] = dev?(c) ? 'group.com.tony.dearembeiu.dev' : 'group.com.tony.dearembeiu'
end

runner.add_dependency(widget)
embed = runner.new_copy_files_build_phase('Embed Foundation Extensions')
embed.symbol_dst_subfolder_spec = :plug_ins
embed.add_file_reference(widget.product_reference).settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }
# It must run BEFORE the "Thin Binary" / Pods script phases: placed after them
# Xcode refuses to build ("Cycle inside Runner").
thin = runner.build_phases.index { |p| p.display_name == 'Thin Binary' } or abort 'Thin Binary phase not found'
runner.build_phases.move(embed, thin)

project.save
puts "Added #{NAME}: #{sources.size} sources, #{fonts.size} fonts, strings en/vi, embedded in Runner"
```
Create `scripts/ios-add-widget-target.sh`:
```bash
#!/bin/bash
# Feature home-widget: one-off, idempotent. Adds the widget extension target to
# ios/Runner.xcodeproj with the xcodeproj gem that ships inside Homebrew's
# CocoaPods. GEM_HOME must point at cocoapods' libexec and GEM_PATH must stay
# unset — with GEM_PATH set the gem is not found.
set -euo pipefail
cd "$(dirname "$0")/.."
RUBY="$(brew --prefix ruby)/bin/ruby"
export GEM_HOME="$(brew --prefix cocoapods)/libexec"
unset GEM_PATH
exec "$RUBY" scripts/ios-add-widget-target.rb "$@"
```

- [ ] **Step 7: Chạy script**

Run: `chmod +x scripts/ios-add-widget-target.sh && flutter build ios --config-only >/dev/null && scripts/ios-add-widget-target.sh`
Expected: `Added DearEmbeiuWidget: 4 sources, 3 fonts, strings en/vi, embedded in Runner`. `git diff --stat ios/Runner.xcodeproj/project.pbxproj` cho thấy file đổi. Chạy lại script lần 2 → `already in the project — nothing to do`.

- [ ] **Step 8: Build iOS (thiết bị, không ký) — extension phải nằm trong app**

Run: `flutter build ios --debug --no-codesign`
Expected: build xong. Rồi:
```bash
ls build/ios/iphoneos/Runner.app/PlugIns/
plutil -p build/ios/iphoneos/Runner.app/PlugIns/DearEmbeiuWidget.appex/Info.plist | grep -E '"CFBundleIdentifier"|"CFBundleShortVersionString"|"CFBundleVersion"|"AppGroupId"'
ls build/ios/iphoneos/Runner.app/PlugIns/DearEmbeiuWidget.appex/ | grep -E "Quicksand|lproj"
```
Expected: `DearEmbeiuWidget.appex`; `CFBundleIdentifier => "com.tony.dearembeiu.dev.widget"`, `CFBundleShortVersionString` = version trong `pubspec.yaml` (hiện `1.9.0`), `CFBundleVersion` = build number (hiện `26`), `AppGroupId => "group.com.tony.dearembeiu.dev"`; 3 file `Quicksand-*.ttf` + `en.lproj`, `vi.lproj`.
Lỗi hay gặp: build báo thiếu `Quicksand-Bold.ttf` → mở pbxproj kiểm `path = ../../assets/fonts/Quicksand-Bold.ttf` (tương đối từ nhóm `ios/DearEmbeiuWidget`); nếu sai, `git checkout ios/Runner.xcodeproj/project.pbxproj`, sửa `.rb`, chạy script lại. Lỗi `method does not override any method from its superclass` ở `SceneDelegate.swift` → xem ghi chú cuối Step 5.

- [ ] **Step 9: Commit**

```bash
git add ios/DearEmbeiuWidget ios/Runner/Runner.entitlements ios/Runner/Info.plist ios/Runner/AppDelegate.swift ios/Runner/SceneDelegate.swift ios/Runner.xcodeproj/project.pbxproj scripts/ios-add-widget-target.rb scripts/ios-add-widget-target.sh
git commit -m "$(cat <<'EOF'
feat(home-widget): target WidgetKit DearEmbeiuWidget + channel iOS + App Group

Widget nhỏ/vừa SwiftUI (gradient + aurora, chip tên, số Quicksand 40, cột
mốc), timeline 7 nửa đêm, tinted/containerBackground theo iOS. App Group
riêng dev/prod qua APP_GROUP_ID. HomeWidgetChannel lưu ảnh chụp + reload,
SceneDelegate ghi cờ dearembeiu://widget?family. Target thêm bằng
scripts/ios-add-widget-target.sh (gem xcodeproj của CocoaPods).

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01Fe9gCYrrfgYjeuLy2WrVgg
EOF
)"
```

---

### Task 5: Smoke iOS trên simulator (DEV)

**Files:** không sửa code (chỉ ghi kết quả vào mục "Nhật ký implement" cuối file này).

- [ ] **Step 1: Chạy app trên iPhone 16 Pro simulator**

Run: `scripts/ios-sim.sh 2EE33EBF-2E01-4A63-8C77-DDF62D1AF9CA`
Expected: app lên (config DEV). Đăng nhập `test1@gmail.com` / `12345678` (seed DEV; nếu chưa có: `node scripts/dev-seed-test-couple.js`). Home hiện CounterCard với số ngày N và "Cột mốc …".

- [ ] **Step 1b: Entitlement App Group có thật trong binary (không chỉ trong file .entitlements)**

```bash
APP=$(find build/ios -type d -name Runner.app -path '*iphonesimulator*' | head -1)
codesign -d --entitlements :- "$APP" 2>/dev/null | grep -A3 application-groups
codesign -d --entitlements :- "$APP/PlugIns/DearEmbeiuWidget.appex" 2>/dev/null | grep -A3 application-groups
```
Expected: cả hai in `group.com.tony.dearembeiu.dev`. Nếu Runner thiếu → `UserDefaults(suiteName:)` ghi vào kho riêng của app, widget trống mãi mà không báo lỗi.

- [ ] **Step 2: Thêm widget, đối chiếu số (2 cỡ máy)**

Simulator iPhone 16 Pro: `Cmd+Shift+H` về màn hình chính → nhấn giữ nền → `+` → tìm "Dear Embeiu Dev" → thêm widget nhỏ, rồi thêm widget vừa. Lặp trên **iPhone 16e** (390pt — cột phải hẹp hơn): `scripts/ios-sim.sh 48AE583D-6416-4A4F-AC1B-51BCD606240D`.
Expected: cả hai hiện cùng N với Home, chip = 2 tên của couple seed (UPPERCASE, tim giữa), bản vừa có "Cột mốc …" + "còn … ngày" + "Bắt đầu từ 1 thg 1, 2025" đúng như Home; dòng "Bắt đầu từ" đủ năm (được xuống 2 dòng), dòng cột mốc không "…". Nền gradient, chữ trắng đọc rõ. Chụp `xcrun simctl io booted screenshot` 2 cỡ, so bằng mắt với artboard A (lưu ý quan sát: tâm aurora và góc gradient bản vừa có thể lệch mock — chỉ ghi nhận, không sửa).

- [ ] **Step 3: Đổi ngôn ngữ trong app**

Vào app → Cài đặt → Ngôn ngữ → English → về màn hình chính.
Expected: widget đổi sang "days together" / "Milestone: …" / "Since Jan 1, 2025" trong ≤2 giây. Đổi lại Tiếng Việt → về vi.

- [ ] **Step 4: Đăng xuất / đăng nhập**

Cài đặt → Đăng xuất → màn hình chính.
Expected: widget trạng thái trống: chip "DEAR EMBEIU", "Chạm để bắt đầu đếm ngày yêu". Đăng nhập lại → số quay lại.

- [ ] **Step 5: Chạm widget → đúng 1 log mỗi lần chạm**

(a) App đang tắt hẳn: chạm widget vừa → app mở về Home; console `flutter run` (hoặc `xcrun simctl spawn booted log stream --predicate 'eventMessage CONTAINS "HomeWidgetBridge"'`) thấy ĐÚNG 1 dòng `HomeWidgetBridge: opened from the medium widget`. (b) App đang chạy nền: chạm widget nhỏ → đúng 1 dòng `small` ngay lần resume đó (không dồn sang lần sau). (c) Mở app bằng icon (không qua widget) → KHÔNG có dòng nào.

- [ ] **Step 6: Tinted + Dynamic Type + iOS 16**

Màn hình chính → nhấn giữ nền → Chỉnh sửa → chọn "Tô màu" (iOS 18): widget về một màu, **tên trong chip vẫn đọc được** (chữ tint trên pill sáng), số/chú thích đọc được. Settings simulator → Accessibility → Display & Text Size → Larger Text kéo tối đa → widget: số co, chú thích tối đa 2 dòng, chip không tràn. Đường iOS 15/16 (`ZStack + padding 14`): nếu máy có runtime iOS 16 thì chạy thử, không có → ghi "chưa kiểm" cho Tester.

- [ ] **Step 7: Ghi nhật ký**

Thêm dòng vào mục "Nhật ký implement" cuối file: `- [YYYY-MM-DD] [Dev] Smoke iOS simulator iPhone 16 Pro (iOS …): … PASS/FAIL từng bước 2–6`. Commit:
```bash
git add project/features/home-widget/dev.md
git commit -m "$(cat <<'EOF'
docs(home-widget): kết quả smoke iOS simulator

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01Fe9gCYrrfgYjeuLy2WrVgg
EOF
)"
```

---

### Task 6: Android `DayMath.kt` (mirror Dart) + JUnit

**Files:**
- Modify: `android/app/build.gradle.kts` (block `dependencies` quanh dòng 100)
- Create: `android/app/src/test/kotlin/com/tony/dearembeiu/widget/DayMathTest.kt`
- Create: `android/app/src/main/kotlin/com/tony/dearembeiu/widget/DayMath.kt`

**Interfaces:**
- Produces (Task 7 dùng): `object DayMath` với `data class LabelStrings(monthsOne, monthsFmt, yearsOne, yearsFmt, daysFmt)`, `fun daysTogether(anniversary: String, today: LocalDate): Int`, `fun nextMilestone(days: Int): Int`, `fun progress(days: Int, next: Int): Float`, `fun format(n: Int, lang: String): String`, `fun milestoneLabel(next: Int, s: LabelStrings, number: (Int) -> String): String`.

- [ ] **Step 1: Thêm JUnit**

Edit `android/app/build.gradle.kts` — old:
```kotlin
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
```
new:
```kotlin
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
    // Feature home-widget: JVM test for widget/DayMath.kt (same vectors as Dart/Swift).
    testImplementation("junit:junit:4.13.2")
```

- [ ] **Step 2: Viết test (fail trước)**

Create `android/app/src/test/kotlin/com/tony/dearembeiu/widget/DayMathTest.kt`:
```kotlin
package com.tony.dearembeiu.widget

import java.time.LocalDate
import org.junit.Assert.assertEquals
import org.junit.Test

/**
 * Feature home-widget: DayMath.kt must match Dart (LoveTreeService.daysTogether
 * + _getNextMilestone in home_screen.dart) and ios/DearEmbeiuWidget/DayMath.swift
 * — same vectors in all three.
 */
class DayMathTest {
    private val today = LocalDate.of(2026, 10, 12)

    @Test
    fun daysTogether_countsCalendarDays_neverNegative() {
        assertEquals(0, DayMath.daysTogether("2026-10-12", today))
        assertEquals(1, DayMath.daysTogether("2026-10-11", today))
        assertEquals(365, DayMath.daysTogether("2025-10-12", today))
        assertEquals(1247, DayMath.daysTogether("2023-05-14", today))
        assertEquals(0, DayMath.daysTogether("2026-10-13", today))
        assertEquals(0, DayMath.daysTogether("garbage", today))
    }

    @Test
    fun nextMilestone_matchesHome() {
        val table = listOf(0 to 30, 29 to 30, 30 to 50, 364 to 365, 365 to 500, 1247 to 1500,
            2999 to 3000, 3000 to 3500, 3499 to 3500, 3500 to 4000)
        table.forEach { (days, next) -> assertEquals("next($days)", next, DayMath.nextMilestone(days)) }
    }

    @Test
    fun progress_isDaysOverNext_clamped() {
        assertEquals(0.8313f, DayMath.progress(1247, 1500), 0.001f)
        assertEquals(1f, DayMath.progress(10, 5), 0f)
        assertEquals(0f, DayMath.progress(10, 0), 0f)
    }

    @Test
    fun format_groupsPerLanguage() {
        assertEquals("1.500", DayMath.format(1500, "vi"))
        assertEquals("1,500", DayMath.format(1500, "en"))
    }

    @Test
    fun milestoneLabel_monthsYearsDays() {
        val s = DayMath.LabelStrings(monthsOne = "1 tháng", monthsFmt = "{count} tháng",
            yearsOne = "1 năm", yearsFmt = "{count} năm", daysFmt = "{count} ngày")
        val label = { n: Int -> DayMath.milestoneLabel(n, s) { DayMath.format(it, "vi") } }
        assertEquals("1 tháng", label(30))
        assertEquals("6 tháng", label(180))
        assertEquals("1 năm", label(365))
        assertEquals("2 năm", label(730))
        assertEquals("1.500 ngày", label(1500))
        assertEquals("50 ngày", label(50))
    }
}
```
Run: `cd android && ./gradlew :app:testDebugUnitTest --tests "com.tony.dearembeiu.widget.DayMathTest" -q; cd ..`
Expected: FAIL biên dịch `Unresolved reference: DayMath`. (Lần đầu Gradle có thể tải dependency vài phút.)

- [ ] **Step 3: Viết `DayMath.kt`**

Create `android/app/src/main/kotlin/com/tony/dearembeiu/widget/DayMath.kt`:
```kotlin
package com.tony.dearembeiu.widget

import java.text.NumberFormat
import java.time.LocalDate
import java.time.temporal.ChronoUnit
import java.util.Locale

/**
 * Day count + next milestone for the home-screen widget. Mirrors Dart
 * (LoveTreeService.daysTogether, _getNextMilestone / _milestoneLabel in
 * home_screen.dart) and ios/DearEmbeiuWidget/DayMath.swift — change all three
 * together or the widget drifts from the Home counter. java.time via
 * coreLibraryDesugaring on older Android.
 */
object DayMath {
    val milestones = intArrayOf(30, 50, 100, 180, 365, 500, 730, 1000, 1500, 2000, 3000)

    data class LabelStrings(
        val monthsOne: String,
        val monthsFmt: String,
        val yearsOne: String,
        val yearsFmt: String,
        val daysFmt: String,
    )

    /** Calendar days from `anniversary` (yyyy-MM-dd) to `today`, never below 0. */
    fun daysTogether(anniversary: String, today: LocalDate): Int {
        val start = try {
            LocalDate.parse(anniversary)
        } catch (_: Exception) {
            return 0
        }
        return ChronoUnit.DAYS.between(start, today).toInt().coerceAtLeast(0)
    }

    fun nextMilestone(days: Int): Int =
        milestones.firstOrNull { days < it } ?: ((days / 500) + 1) * 500

    /** The Home progress bar: days / next, clamped to 0…1. */
    fun progress(days: Int, next: Int): Float =
        if (next <= 0) 0f else (days.toFloat() / next).coerceIn(0f, 1f)

    /** Grouped integer in the app's language (vi → 1.500, en → 1,500). */
    fun format(n: Int, lang: String): String {
        val locale = if (lang == "vi") Locale.forLanguageTag("vi-VN") else Locale.US
        return NumberFormat.getIntegerInstance(locale).format(n)
    }

    /** "6 tháng" / "1 năm" / "1.500 ngày" from the snapshot's templates. */
    fun milestoneLabel(next: Int, s: LabelStrings, number: (Int) -> String): String = when {
        next % 365 == 0 -> (next / 365).let { if (it == 1) s.yearsOne else s.yearsFmt.replace("{count}", number(it)) }
        next < 365 && next % 30 == 0 -> (next / 30).let { if (it == 1) s.monthsOne else s.monthsFmt.replace("{count}", number(it)) }
        else -> s.daysFmt.replace("{count}", number(next))
    }
}
```

- [ ] **Step 4: Chạy test, phải PASS**

Run: `cd android && ./gradlew :app:testDebugUnitTest --tests "com.tony.dearembeiu.widget.DayMathTest" -q; cd ..`
Expected: không lỗi (im lặng = pass). Xem báo cáo: `build/app/test-results/testDebugUnitTest/TEST-com.tony.dearembeiu.widget.DayMathTest.xml` (Flutter đặt build của module app ở `build/app/`, không phải `android/app/build/`) có `tests="5" failures="0"`.

- [ ] **Step 5: Commit**

```bash
git add android/app/build.gradle.kts android/app/src/test/kotlin/com/tony/dearembeiu/widget/DayMathTest.kt android/app/src/main/kotlin/com/tony/dearembeiu/widget/DayMath.kt
git commit -m "$(cat <<'EOF'
feat(home-widget): DayMath.kt mirror công thức Home + 5 test JUnit 4

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01Fe9gCYrrfgYjeuLy2WrVgg
EOF
)"
```

---

### Task 7: Android widget provider + layout + channel + smoke emulator

**Files:**
- Create: `android/app/src/main/kotlin/com/tony/dearembeiu/widget/WidgetStore.kt`, `android/app/src/main/kotlin/com/tony/dearembeiu/widget/DayCounterWidget.kt`
- Create: `android/app/src/main/res/layout/widget_day_small.xml`, `widget_day_medium.xml`, `widget_day_empty.xml`; `res/drawable/widget_bg.xml` (gradient + scrim + 2 glow radial), `res/drawable-v31/widget_bg.xml`, `widget_chip_bg.xml`, `widget_progress.xml`, `widget_heart.xml`; `res/xml/widget_day_info.xml`; `res/values/strings.xml`, `res/values-vi/strings.xml`
- Modify: `android/app/src/main/AndroidManifest.xml` (trước `<receiver … ScheduledNotificationReceiver />`, dòng 72), `android/app/src/main/kotlin/com/tony/dearembeiu/MainActivity.kt` (import, sau `super.configureFlutterEngine`, trước `private fun hasUsageAccess()`)

**Interfaces:**
- Consumes: `DayMath` (Task 6); ảnh chụp key Task 1; channel Task 2.
- Produces: `WidgetStore.save/load/recordLaunch/consumeLaunch`, `DayCounterWidget.updateAll(context)`, `DayCounterWidget.EXTRA_FAMILY = "widget_family"`.

- [ ] **Step 1: Font + strings**

```bash
mkdir -p android/app/src/main/res/values-vi android/app/src/main/res/drawable-v31
```
Create `android/app/src/main/res/values/strings.xml`:
```xml
<?xml version="1.0" encoding="utf-8"?>
<!-- Feature home-widget: only what the system shows before Flutter has pushed
     a snapshot (widget picker + first empty state). Everything else is
     pre-translated by Flutter (D4). -->
<resources>
    <string name="widget_display_name">Day counter</string>
    <string name="widget_description">Your days together, updated every day.</string>
    <string name="widget_empty_tap">Tap to start counting your days together</string>
</resources>
```
Create `android/app/src/main/res/values-vi/strings.xml`:
```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="widget_display_name">Đếm ngày yêu</string>
    <string name="widget_description">Số ngày chúng mình bên nhau, cập nhật mỗi ngày.</string>
    <string name="widget_empty_tap">Chạm để bắt đầu đếm ngày yêu</string>
</resources>
```

- [ ] **Step 2: Drawables**

Create `android/app/src/main/res/drawable/widget_bg.xml`:
```xml
<?xml version="1.0" encoding="utf-8"?>
<!-- Widget background (design.md hướng A): 150° gradient + dark scrim. Angle 315
     = top-left → bottom-right in Android's counter-clockwise convention. -->
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item>
        <shape android:shape="rectangle">
            <corners android:radius="28dp" />
            <gradient
                android:angle="315"
                android:centerColor="#FF4D6D"
                android:endColor="#E63956"
                android:startColor="#FF5C8F"
                android:type="linear" />
        </shape>
    </item>
    <item>
        <shape android:shape="rectangle">
            <corners android:radius="28dp" />
            <gradient
                android:angle="270"
                android:endColor="#47000000"
                android:startColor="#1A000000"
                android:type="linear" />
        </shape>
    </item>
    <!-- Aurora glows live INSIDE the background so every API level clips them
         to the rounded corners (clipToOutline is API 31+). -->
    <item>
        <shape android:shape="rectangle">
            <corners android:radius="28dp" />
            <gradient
                android:centerX="0.0"
                android:centerY="0.0"
                android:endColor="#00FFFFFF"
                android:gradientRadius="56dp"
                android:startColor="#42FFFFFF"
                android:type="radial" />
        </shape>
    </item>
    <item>
        <shape android:shape="rectangle">
            <corners android:radius="28dp" />
            <gradient
                android:centerX="1.0"
                android:centerY="1.0"
                android:endColor="#00A78BFA"
                android:gradientRadius="72dp"
                android:startColor="#66A78BFA"
                android:type="radial" />
        </shape>
    </item>
</layer-list>
```
Create `android/app/src/main/res/drawable-v31/widget_bg.xml` (giống trên, bo theo hệ thống):
```xml
<?xml version="1.0" encoding="utf-8"?>
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item>
        <shape android:shape="rectangle">
            <corners android:radius="@android:dimen/system_app_widget_background_radius" />
            <gradient
                android:angle="315"
                android:centerColor="#FF4D6D"
                android:endColor="#E63956"
                android:startColor="#FF5C8F"
                android:type="linear" />
        </shape>
    </item>
    <item>
        <shape android:shape="rectangle">
            <corners android:radius="@android:dimen/system_app_widget_background_radius" />
            <gradient
                android:angle="270"
                android:endColor="#47000000"
                android:startColor="#1A000000"
                android:type="linear" />
        </shape>
    </item>
    <!-- Aurora glows live INSIDE the background so every API level clips them
         to the rounded corners (clipToOutline is API 31+). -->
    <item>
        <shape android:shape="rectangle">
            <corners android:radius="@android:dimen/system_app_widget_background_radius" />
            <gradient
                android:centerX="0.0"
                android:centerY="0.0"
                android:endColor="#00FFFFFF"
                android:gradientRadius="56dp"
                android:startColor="#42FFFFFF"
                android:type="radial" />
        </shape>
    </item>
    <item>
        <shape android:shape="rectangle">
            <corners android:radius="@android:dimen/system_app_widget_background_radius" />
            <gradient
                android:centerX="1.0"
                android:centerY="1.0"
                android:endColor="#00A78BFA"
                android:gradientRadius="72dp"
                android:startColor="#66A78BFA"
                android:type="radial" />
        </shape>
    </item>
</layer-list>
```
Create `android/app/src/main/res/drawable/widget_chip_bg.xml`:
```xml
<?xml version="1.0" encoding="utf-8"?>
<shape xmlns:android="http://schemas.android.com/apk/res/android" android:shape="rectangle">
    <corners android:radius="999dp" />
    <solid android:color="#D6FFFFFF" />
</shape>
```
Create `android/app/src/main/res/drawable/widget_progress.xml`:
```xml
<?xml version="1.0" encoding="utf-8"?>
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:id="@android:id/background">
        <shape android:shape="rectangle">
            <corners android:radius="3dp" />
            <solid android:color="#42FFFFFF" />
        </shape>
    </item>
    <item android:id="@android:id/progress">
        <clip>
            <shape android:shape="rectangle">
                <corners android:radius="3dp" />
                <solid android:color="#F5FFFFFF" />
            </shape>
        </clip>
    </item>
</layer-list>
```
Create `android/app/src/main/res/drawable/widget_heart.xml`:
```xml
<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:viewportWidth="24"
    android:viewportHeight="24">
    <path
        android:fillColor="#E63956"
        android:pathData="M12,21.35l-1.45,-1.32C5.4,15.36 2,12.28 2,8.5 2,5.42 4.42,3 7.5,3c1.74,0 3.41,0.81 4.5,2.09C13.09,3.81 14.76,3 16.5,3 19.58,3 22,5.42 22,8.5c0,3.78 -3.4,6.86 -8.55,11.54L12,21.35z" />
</vector>
```

- [ ] **Step 3: Layouts (RemoteViews chỉ nhận FrameLayout/LinearLayout/TextView/ImageView/ProgressBar — KHÔNG `Space`, KHÔNG `View`: khoảng trống và vạch chia dùng `FrameLayout`. Chữ dùng FONT HỆ THỐNG: RemoteViews inflate trong context restricted nên `TextView` không nạp `@font/…` (kể cả `res/font`) — độ đậm giữ bằng `android:fontFamily="sans-serif"` + `android:textStyle="bold"` cho Bold, `sans-serif-medium` cho SemiBold/Medium. Quicksand chỉ có trên iOS. 2 dòng dài cột phải (`widget_milestone`, `widget_since`) autosize 10–12sp để widget 3 ô trên máy ô lớn không cắt chữ.)**

Create `android/app/src/main/res/layout/widget_day_small.xml`:
```xml
<?xml version="1.0" encoding="utf-8"?>
<!-- Home-screen widget 2×2 (feature home-widget, design.md hướng A). -->
<FrameLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:id="@+id/widget_root"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:background="@drawable/widget_bg"
    android:clipToOutline="true">

    <LinearLayout
        android:layout_width="match_parent"
        android:layout_height="match_parent"
        android:orientation="vertical"
        android:padding="16dp">

        <LinearLayout
            android:layout_width="wrap_content"
            android:layout_height="20dp"
            android:background="@drawable/widget_chip_bg"
            android:gravity="center_vertical"
            android:orientation="horizontal"
            android:paddingStart="8dp"
            android:paddingEnd="8dp">

            <TextView
                android:id="@+id/widget_name1"
                android:layout_width="wrap_content"
                android:layout_height="wrap_content"
                android:ellipsize="end"
                android:fontFamily="sans-serif"
                android:textStyle="bold"
                android:letterSpacing="0.1"
                android:maxWidth="48dp"
                android:maxLines="1"
                android:textAllCaps="true"
                android:textColor="#1A1A2E"
                android:textSize="10sp" />

            <ImageView
                android:id="@+id/widget_heart"
                android:layout_width="10dp"
                android:layout_height="10dp"
                android:layout_marginStart="4dp"
                android:layout_marginEnd="4dp"
                android:importantForAccessibility="no"
                android:src="@drawable/widget_heart" />

            <TextView
                android:id="@+id/widget_name2"
                android:layout_width="wrap_content"
                android:layout_height="wrap_content"
                android:ellipsize="end"
                android:fontFamily="sans-serif"
                android:textStyle="bold"
                android:letterSpacing="0.1"
                android:maxWidth="48dp"
                android:maxLines="1"
                android:textAllCaps="true"
                android:textColor="#1A1A2E"
                android:textSize="10sp" />
        </LinearLayout>

        <FrameLayout
            android:layout_width="match_parent"
            android:layout_height="0dp"
            android:layout_weight="1" />

        <TextView
            android:id="@+id/widget_days"
            android:layout_width="match_parent"
            android:layout_height="46dp"
            android:autoSizeMaxTextSize="40sp"
            android:autoSizeMinTextSize="24sp"
            android:autoSizeTextType="uniform"
            android:fontFamily="sans-serif"
            android:textStyle="bold"
            android:gravity="bottom|start"
            android:includeFontPadding="false"
            android:letterSpacing="-0.025"
            android:maxLines="1"
            android:shadowColor="#4D000000"
            android:shadowDy="1"
            android:shadowRadius="8"
            android:textColor="#FFFFFF"
            android:textSize="40sp" />

        <TextView
            android:id="@+id/widget_caption"
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:layout_marginTop="6dp"
            android:fontFamily="sans-serif-medium"
            android:maxLines="2"
            android:shadowColor="#47000000"
            android:shadowDy="1"
            android:shadowRadius="6"
            android:textColor="#EBFFFFFF"
            android:textSize="12sp" />
    </LinearLayout>
</FrameLayout>
```
Create `android/app/src/main/res/layout/widget_day_medium.xml`:
```xml
<?xml version="1.0" encoding="utf-8"?>
<!-- Home-screen widget 4×2: counter column + milestone column. -->
<FrameLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:id="@+id/widget_root"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:background="@drawable/widget_bg"
    android:clipToOutline="true">

    <LinearLayout
        android:layout_width="match_parent"
        android:layout_height="match_parent"
        android:orientation="horizontal"
        android:padding="16dp">

        <LinearLayout
            android:layout_width="0dp"
            android:layout_height="match_parent"
            android:layout_weight="1"
            android:orientation="vertical">

            <LinearLayout
                android:layout_width="wrap_content"
                android:layout_height="20dp"
                android:background="@drawable/widget_chip_bg"
                android:gravity="center_vertical"
                android:orientation="horizontal"
                android:paddingStart="8dp"
                android:paddingEnd="8dp">

                <TextView
                    android:id="@+id/widget_name1"
                    android:layout_width="wrap_content"
                    android:layout_height="wrap_content"
                    android:ellipsize="end"
                    android:fontFamily="sans-serif"
                    android:textStyle="bold"
                    android:letterSpacing="0.1"
                    android:maxWidth="64dp"
                    android:maxLines="1"
                    android:textAllCaps="true"
                    android:textColor="#1A1A2E"
                    android:textSize="10sp" />

                <ImageView
                    android:id="@+id/widget_heart"
                    android:layout_width="10dp"
                    android:layout_height="10dp"
                    android:layout_marginStart="4dp"
                    android:layout_marginEnd="4dp"
                    android:importantForAccessibility="no"
                    android:src="@drawable/widget_heart" />

                <TextView
                    android:id="@+id/widget_name2"
                    android:layout_width="wrap_content"
                    android:layout_height="wrap_content"
                    android:ellipsize="end"
                    android:fontFamily="sans-serif"
                    android:textStyle="bold"
                    android:letterSpacing="0.1"
                    android:maxWidth="64dp"
                    android:maxLines="1"
                    android:textAllCaps="true"
                    android:textColor="#1A1A2E"
                    android:textSize="10sp" />
            </LinearLayout>

            <FrameLayout
                android:layout_width="match_parent"
                android:layout_height="0dp"
                android:layout_weight="1" />

            <TextView
                android:id="@+id/widget_days"
                android:layout_width="match_parent"
                android:layout_height="46dp"
                android:autoSizeMaxTextSize="40sp"
                android:autoSizeMinTextSize="24sp"
                android:autoSizeTextType="uniform"
                android:fontFamily="sans-serif"
                android:textStyle="bold"
                android:gravity="bottom|start"
                android:includeFontPadding="false"
                android:letterSpacing="-0.025"
                android:maxLines="1"
                android:shadowColor="#4D000000"
                android:shadowDy="1"
                android:shadowRadius="8"
                android:textColor="#FFFFFF"
                android:textSize="40sp" />

            <TextView
                android:id="@+id/widget_caption"
                android:layout_width="match_parent"
                android:layout_height="wrap_content"
                android:layout_marginTop="6dp"
                android:fontFamily="sans-serif-medium"
                android:maxLines="2"
                android:shadowColor="#47000000"
                android:shadowDy="1"
                android:shadowRadius="6"
                android:textColor="#EBFFFFFF"
                android:textSize="12sp" />
        </LinearLayout>

        <FrameLayout
            android:layout_width="1dp"
            android:layout_height="match_parent"
            android:layout_marginStart="14dp"
            android:layout_marginTop="2dp"
            android:layout_marginEnd="14dp"
            android:layout_marginBottom="2dp"
            android:background="#47FFFFFF" />

        <LinearLayout
            android:layout_width="0dp"
            android:layout_height="match_parent"
            android:layout_weight="1"
            android:orientation="vertical">

            <TextView
                android:id="@+id/widget_milestone"
                android:layout_width="match_parent"
                android:layout_height="16dp"
                android:autoSizeMaxTextSize="12sp"
                android:autoSizeMinTextSize="10sp"
                android:autoSizeTextType="uniform"
                android:ellipsize="end"
                android:fontFamily="sans-serif"
                android:textStyle="bold"
                android:gravity="center_vertical"
                android:maxLines="1"
                android:shadowColor="#47000000"
                android:shadowDy="1"
                android:shadowRadius="6"
                android:textColor="#FFFFFF"
                android:textSize="12sp" />

            <ProgressBar
                android:id="@+id/widget_progress"
                style="?android:attr/progressBarStyleHorizontal"
                android:layout_width="match_parent"
                android:layout_height="6dp"
                android:layout_marginTop="8dp"
                android:max="100"
                android:progressDrawable="@drawable/widget_progress" />

            <TextView
                android:id="@+id/widget_days_left"
                android:layout_width="match_parent"
                android:layout_height="wrap_content"
                android:layout_marginTop="8dp"
                android:fontFamily="sans-serif-medium"
                android:maxLines="1"
                android:shadowColor="#47000000"
                android:shadowDy="1"
                android:shadowRadius="6"
                android:textColor="#EBFFFFFF"
                android:textSize="12sp" />

            <FrameLayout
                android:layout_width="match_parent"
                android:layout_height="0dp"
                android:layout_weight="1" />

            <TextView
                android:id="@+id/widget_since"
                android:layout_width="match_parent"
                android:layout_height="wrap_content"
                android:ellipsize="end"
                android:fontFamily="sans-serif-medium"
                android:maxLines="2"
                android:shadowColor="#47000000"
                android:shadowDy="1"
                android:shadowRadius="6"
                android:textColor="#D6FFFFFF"
                android:textSize="11sp" />
        </LinearLayout>
    </LinearLayout>
</FrameLayout>
```
Create `android/app/src/main/res/layout/widget_day_empty.xml`:
```xml
<?xml version="1.0" encoding="utf-8"?>
<!-- Empty state: guest / no couple / signed out / app not opened since this build. -->
<FrameLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:id="@+id/widget_root"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:background="@drawable/widget_bg"
    android:clipToOutline="true">

    <LinearLayout
        android:layout_width="match_parent"
        android:layout_height="match_parent"
        android:orientation="vertical"
        android:padding="16dp">

        <LinearLayout
            android:layout_width="wrap_content"
            android:layout_height="20dp"
            android:background="@drawable/widget_chip_bg"
            android:gravity="center_vertical"
            android:orientation="horizontal"
            android:paddingStart="8dp"
            android:paddingEnd="8dp">

            <ImageView
                android:layout_width="10dp"
                android:layout_height="10dp"
                android:layout_marginEnd="4dp"
                android:importantForAccessibility="no"
                android:src="@drawable/widget_heart" />

            <TextView
                android:id="@+id/widget_name1"
                android:layout_width="wrap_content"
                android:layout_height="wrap_content"
                android:fontFamily="sans-serif"
                android:textStyle="bold"
                android:letterSpacing="0.1"
                android:maxLines="1"
                android:textColor="#1A1A2E"
                android:textSize="10sp" />
        </LinearLayout>

        <FrameLayout
            android:layout_width="match_parent"
            android:layout_height="0dp"
            android:layout_weight="1" />

        <TextView
            android:id="@+id/widget_empty_text"
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:fontFamily="sans-serif"
            android:textStyle="bold"
            android:maxLines="3"
            android:shadowColor="#4D000000"
            android:shadowDy="1"
            android:shadowRadius="8"
            android:textColor="#FFFFFF"
            android:textSize="14sp" />
    </LinearLayout>
</FrameLayout>
```

- [ ] **Step 4: Provider info + manifest**

Create `android/app/src/main/res/xml/widget_day_info.xml`:
```xml
<?xml version="1.0" encoding="utf-8"?>
<!-- Feature home-widget. 2×2 by default, stretches to 4×2 (medium layout at
     ≥250dp). updatePeriodMillis 30' = the day count may lag up to 30 minutes
     after midnight (D7). ponytail: upgrade to an exact midnight alarm if that
     ever bothers anyone. targetCell*/previewLayout/description are API 31. -->
<appwidget-provider xmlns:android="http://schemas.android.com/apk/res/android"
    android:description="@string/widget_description"
    android:initialLayout="@layout/widget_day_small"
    android:minWidth="110dp"
    android:minHeight="110dp"
    android:minResizeWidth="110dp"
    android:minResizeHeight="110dp"
    android:previewLayout="@layout/widget_day_small"
    android:resizeMode="horizontal"
    android:targetCellWidth="2"
    android:targetCellHeight="2"
    android:updatePeriodMillis="1800000"
    android:widgetCategory="home_screen" />
```
Edit `android/app/src/main/AndroidManifest.xml` — old:
```xml
        <receiver
            android:exported="false"
            android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
```
new:
```xml
        <!-- Feature home-widget: day counter on the home screen. -->
        <receiver
            android:name=".widget.DayCounterWidget"
            android:exported="true"
            android:label="@string/widget_display_name">
            <intent-filter>
                <action android:name="android.appwidget.action.APPWIDGET_UPDATE" />
            </intent-filter>
            <meta-data
                android:name="android.appwidget.provider"
                android:resource="@xml/widget_day_info" />
        </receiver>
        <receiver
            android:exported="false"
            android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
```

- [ ] **Step 5: `WidgetStore.kt` + `DayCounterWidget.kt`**

Create `android/app/src/main/kotlin/com/tony/dearembeiu/widget/WidgetStore.kt`:
```kotlin
package com.tony.dearembeiu.widget

import android.content.Context

/**
 * Shared store between the Flutter channel and the widget provider
 * (feature home-widget). Snapshot keys: lib/services/home_widget_snapshot.dart.
 * The launch flag lives in its own file so clearing a snapshot never eats a tap.
 */
object WidgetStore {
    private const val SNAPSHOT_PREFS = "dear_embeiu_widget"
    private const val LAUNCH_PREFS = "dear_embeiu_widget_launch"
    private const val KEY_FAMILY = "family"

    fun save(context: Context, snapshot: Map<String, String>) {
        val editor = context.getSharedPreferences(SNAPSHOT_PREFS, Context.MODE_PRIVATE).edit().clear()
        snapshot.forEach { (key, value) -> editor.putString(key, value) }
        editor.apply()
    }

    fun load(context: Context): Map<String, String> =
        context.getSharedPreferences(SNAPSHOT_PREFS, Context.MODE_PRIVATE).all
            .mapNotNull { (key, value) -> (value as? String)?.let { key to it } }
            .toMap()

    fun recordLaunch(context: Context, family: String) {
        context.getSharedPreferences(LAUNCH_PREFS, Context.MODE_PRIVATE).edit()
            .putString(KEY_FAMILY, family).apply()
    }

    /** Returns the family of the widget that opened the app, once. */
    fun consumeLaunch(context: Context): String? {
        val prefs = context.getSharedPreferences(LAUNCH_PREFS, Context.MODE_PRIVATE)
        val family = prefs.getString(KEY_FAMILY, null) ?: return null
        prefs.edit().remove(KEY_FAMILY).apply()
        return family
    }
}
```
Create `android/app/src/main/kotlin/com/tony/dearembeiu/widget/DayCounterWidget.kt`:
```kotlin
package com.tony.dearembeiu.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.view.View
import android.widget.RemoteViews
import com.tony.dearembeiu.MainActivity
import com.tony.dearembeiu.R
import java.time.LocalDate

/**
 * Home-screen day counter (feature home-widget). Reads the snapshot Flutter
 * stored through [WidgetStore], recomputes days + milestone ([DayMath]) and
 * picks the small or medium layout from the current cell width.
 */
class DayCounterWidget : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        ids.forEach { render(context, manager, it) }
    }

    override fun onAppWidgetOptionsChanged(context: Context, manager: AppWidgetManager, id: Int, newOptions: Bundle) {
        render(context, manager, id)
    }

    companion object {
        const val EXTRA_FAMILY = "widget_family"
        private const val MEDIUM_MIN_WIDTH_DP = 250

        /** Called by the Flutter channel after every snapshot update. */
        fun updateAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            manager.getAppWidgetIds(ComponentName(context, DayCounterWidget::class.java))
                .forEach { render(context, manager, it) }
        }

        fun render(context: Context, manager: AppWidgetManager, id: Int) {
            val snapshot = WidgetStore.load(context)
            val minWidth = manager.getAppWidgetOptions(id).getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 0)
            val medium = minWidth >= MEDIUM_MIN_WIDTH_DP
            val views = if (snapshot["state"] == "counter") {
                counterViews(context, snapshot, medium)
            } else {
                emptyViews(context, snapshot)
            }
            views.setOnClickPendingIntent(R.id.widget_root, openApp(context, if (medium) "medium" else "small"))
            manager.updateAppWidget(id, views)
        }

        private fun counterViews(context: Context, s: Map<String, String>, medium: Boolean): RemoteViews {
            val lang = s["lang"] ?: "vi"
            val days = DayMath.daysTogether(s["anniversary"] ?: "", LocalDate.now())
            val next = DayMath.nextMilestone(days)
            val number = { n: Int -> DayMath.format(n, lang) }
            val views = RemoteViews(context.packageName, if (medium) R.layout.widget_day_medium else R.layout.widget_day_small)
            bindChip(views, s["name1"] ?: "", s["name2"] ?: "")
            views.setTextViewText(R.id.widget_days, number(days))
            views.setTextViewText(R.id.widget_caption, s["daysLabel"] ?: "")
            if (medium) {
                val strings = DayMath.LabelStrings(
                    monthsOne = s["monthsOne"] ?: "", monthsFmt = s["monthsFmt"] ?: "{count}",
                    yearsOne = s["yearsOne"] ?: "", yearsFmt = s["yearsFmt"] ?: "{count}",
                    daysFmt = s["daysFmt"] ?: "{count}",
                )
                val label = DayMath.milestoneLabel(next, strings, number)
                views.setTextViewText(R.id.widget_milestone, (s["milestoneFmt"] ?: "{label}").replace("{label}", label))
                val left = next - days
                views.setTextViewText(R.id.widget_days_left, when {
                    left <= 0 -> s["todayLabel"] ?: ""
                    left == 1 -> s["daysLeftOne"] ?: ""
                    else -> (s["daysLeftFmt"] ?: "{count}").replace("{count}", number(left))
                })
                views.setProgressBar(R.id.widget_progress, 100, (DayMath.progress(days, next) * 100).toInt(), false)
                views.setTextViewText(R.id.widget_since, s["sinceText"] ?: "")
            }
            return views
        }

        private fun emptyViews(context: Context, s: Map<String, String>): RemoteViews {
            val views = RemoteViews(context.packageName, R.layout.widget_day_empty)
            views.setTextViewText(R.id.widget_name1, s["emptyChip"] ?: "DEAR EMBEIU")
            views.setTextViewText(R.id.widget_empty_text, s["emptyText"] ?: context.getString(R.string.widget_empty_tap))
            return views
        }

        private fun bindChip(views: RemoteViews, name1: String, name2: String) {
            views.setTextViewText(R.id.widget_name1, name1)
            views.setTextViewText(R.id.widget_name2, name2)
            views.setViewVisibility(R.id.widget_name1, if (name1.isEmpty()) View.GONE else View.VISIBLE)
            views.setViewVisibility(R.id.widget_name2, if (name2.isEmpty()) View.GONE else View.VISIBLE)
            views.setViewVisibility(R.id.widget_heart, if (name1.isEmpty() || name2.isEmpty()) View.GONE else View.VISIBLE)
        }

        /** Explicit intent (not ACTION_MAIN) so a running singleTop MainActivity gets onNewIntent + the extra. */
        private fun openApp(context: Context, family: String): PendingIntent {
            val intent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
                putExtra(EXTRA_FAMILY, family)
            }
            val requestCode = if (family == "medium") 2 else 1
            return PendingIntent.getActivity(context, requestCode, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        }
    }
}
```

- [ ] **Step 6: `MainActivity.kt` — channel + cờ mở-từ-widget**

Edit `android/app/src/main/kotlin/com/tony/dearembeiu/MainActivity.kt` — old:
```kotlin
import io.flutter.plugin.common.MethodChannel
```
new:
```kotlin
import io.flutter.plugin.common.MethodChannel
import android.os.Bundle
import com.tony.dearembeiu.widget.DayCounterWidget
import com.tony.dearembeiu.widget.WidgetStore
```
old:
```kotlin
        super.configureFlutterEngine(flutterEngine)
```
new:
```kotlin
        super.configureFlutterEngine(flutterEngine)
        // Feature home-widget (D3/D8): Dart pushes the pre-translated snapshot,
        // we store it and redraw every widget; consumeLaunch hands back which
        // widget opened the app (recorded from the intent extra below).
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "dear_embeiu/widget")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "update" -> {
                        val args = call.arguments as? Map<*, *>
                        val snapshot = args?.entries?.associate { it.key.toString() to it.value.toString() } ?: emptyMap()
                        WidgetStore.save(this, snapshot)
                        DayCounterWidget.updateAll(this)
                        result.success(null)
                    }
                    "consumeLaunch" -> result.success(WidgetStore.consumeLaunch(this))
                    else -> result.notImplemented()
                }
            }
```
old:
```kotlin
    private fun hasUsageAccess(): Boolean {
```
new:
```kotlin
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Only a fresh launch counts as a tap: a recreated activity (process
        // death, config change) or a relaunch from Recents still carries the
        // original widget intent — system_server keeps it with the extra.
        if (savedInstanceState == null &&
            (intent.flags and Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY) == 0) {
            recordWidgetLaunch(intent)
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        recordWidgetLaunch(intent)
    }

    /** A tap on the home-screen widget carries its family; park it for Dart (feature home-widget). */
    private fun recordWidgetLaunch(intent: Intent?) {
        val family = intent?.getStringExtra(DayCounterWidget.EXTRA_FAMILY) ?: return
        WidgetStore.recordLaunch(this, family)
        intent.removeExtra(DayCounterWidget.EXTRA_FAMILY)
    }

    private fun hasUsageAccess(): Boolean {
```

- [ ] **Step 7: Biên dịch**

Run: `flutter build apk --debug`
Expected: `✓ Built build/app/outputs/flutter-apk/app-debug.apk`. Lỗi `Unresolved reference R`/`MainActivity` → kiểm package `com.tony.dearembeiu` ở đầu file; lỗi resource (`@font/...`) → kiểm tên file font chữ thường.

- [ ] **Step 8: Smoke trên emulator Pixel_10**

Run: `flutter emulators --launch Pixel_10` rồi `flutter run -d emulator-5554` (id xem `flutter devices`).
Checklist (ghi PASS/FAIL vào Nhật ký):
1. Đăng nhập `test1@gmail.com` → Home hiện N ngày. Về màn hình chính, nhấn giữ → Widgets → "Dear Embeiu Dev" → kéo "Đếm ngày yêu" ra: 2×2 hiện N, chip "TEST1 ♥ TEST2", "ngày bên nhau", chữ Roboto (font hệ thống — RemoteViews không nạp res/font), nền gradient.
2. Nhấn giữ widget → kéo rộng sang 4 ô → bố cục vừa: "Cột mốc …", thanh tiến độ, "còn … ngày", "Bắt đầu từ 1 thg 1, 2025" — cùng số với Home.
3. Trong app đổi English → về màn hình chính: chữ EN. Đổi lại.
4. Đăng xuất → widget trống "DEAR EMBEIU / Chạm để bắt đầu đếm ngày yêu". Đăng nhập lại → số quay lại.
5. Tắt app (vuốt khỏi Recent) → chạm widget 4×2 → app mở; console `HomeWidgetBridge: opened from the medium widget`. App đang mở nền → chạm widget 2×2 → `small`.
6. `adb shell cmd appwidget` không cần; xoay máy không áp (khoá dọc).

- [ ] **Step 9: Analyze + commit**

Run: `flutter analyze`
Expected: `No issues found!`
```bash
git add android/app/src/main android/app/src/test
git commit -m "$(cat <<'EOF'
feat(home-widget): Android AppWidgetProvider 2×2/4×2 + channel + cờ mở app

DayCounterWidget đọc snapshot từ SharedPreferences, tính ngày/cột mốc bằng
DayMath, 3 layout RemoteViews (nhỏ/vừa/trống) font hệ thống (RemoteViews không nạp res/font), nền
gradient + scrim + aurora, bo góc hệ thống API 31. updatePeriodMillis 30'
(D7). MainActivity: channel dear_embeiu/widget + extra widget_family →
WidgetStore cho widget_tap.

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01Fe9gCYrrfgYjeuLy2WrVgg
EOF
)"
```

---

### Task 8: Tài liệu + kiểm tổng + push

**Files:**
- Modify: `project/features/home-widget/dev.md` (file này — trạng thái + nhật ký), `project/features/home-widget/design.md` (2 chỗ lệch), `project/features/home-widget/overview.md` (trạng thái), `project/ROADMAP.md` (dòng home-widget), `CLAUDE.md` (§2 services, §4 native, §13 build), `project/build-guide.md` (mục mới)

- [ ] **Step 1: Kiểm tổng 4 bộ**

```bash
flutter analyze
flutter test
scripts/check-widget-daymath.sh
(cd android && ./gradlew :app:testDebugUnitTest --tests "com.tony.dearembeiu.widget.DayMathTest" -q)
git status --short
```
Expected: `No issues found!` · `All tests passed!` · `OK DayMath — 30 checks` · gradle im lặng · chỉ còn file docs chưa commit.

- [ ] **Step 2: design.md — chỗ lệch còn lại so với code thật** (dòng "Bắt đầu từ…" + tinted + font Android đã được controller sửa trong lúc chạy)

Edit `project/features/home-widget/design.md` — old:
```
- **Có couple (active hoặc chờ người ấy):** như wireframe. Chờ người ấy → chip 1 tên; không thêm lời mời.
```
new:
```
- **Có couple (active hoặc chờ người ấy):** như wireframe. Setup nhập cả 2 tên lúc tạo nên chip thường có đủ 2 tên ngay khi còn chờ; tên nào trống thì ẩn tên đó và ẩn tim. Không thêm lời mời.
```

- [ ] **Step 2b: Đồng bộ plan với code thật**

Khối Ruby ở Task 4 Step 6 của file này khác `scripts/ios-add-widget-target.rb` đã commit ở 2 chỗ (thêm `'PRODUCT_NAME' => '$(TARGET_NAME)'`; dời phase "Embed Foundation Extensions" lên trước "Thin Binary" để tránh `Cycle inside Runner`). Chép nội dung file đã commit vào khối đó (giữ phần giải thích). Tương tự kiểm khối `WidgetSnapshot.swift`/`DayCounterView.swift`/layout Android nếu Task 5/7 đã lệch gì, ghi chú ngắn thay vì chép lại cả khối.

- [ ] **Step 3: Trạng thái feature**

- `overview.md`: dòng `- **Trạng thái:**` → `💻 Dev xong, 🧪 chờ Tester (YYYY-MM-DD)` + thêm changelog `- [YYYY-MM-DD] [Dev] Implement xong 7 task (bridge · iOS target · Android provider), smoke 2 nền tảng.`
- `dev.md` (file này): `- **Trạng thái dev:** xong — chờ test`; mục "Nhật ký implement" đủ dòng cho Task 1–7 (commit hash + kết quả smoke).
- `project/ROADMAP.md` dòng `📱 **Widget màn hình chính…**`: đổi `📋 **Spec xong, user duyệt thiết kế 2026-10-12**` → `💻 **Dev xong YYYY-MM-DD, chờ Tester**` (giữ phần mô tả còn lại).

- [ ] **Step 4: CLAUDE.md + build-guide**

`CLAUDE.md`:
- §2 đoạn "Services:" thêm ` · **home_widget_bridge + home_widget_snapshot (feature home-widget, 2026-10: Flutter đẩy ảnh chụp dữ liệu dịch sẵn sang widget native qua channel `dear_embeiu/widget`; lắng nghe CoupleProvider + LocaleProvider ở `_MyAppState`)**`.
- §4 Android thêm gạch đầu dòng: `- **Widget màn hình chính (feature home-widget):** receiver `.widget.DayCounterWidget` + `res/xml/widget_day_info.xml` (2×2 kéo tới 4×2, `updatePeriodMillis` 30'), layout RemoteViews `res/layout/widget_day_*.xml`; chữ dùng font hệ thống Roboto (RemoteViews chạy context restricted, KHÔNG nạp `@font/` — Quicksand chỉ có trên iOS). JUnit `DayMathTest` (`./gradlew :app:testDebugUnitTest`).`
- §4 iOS thêm gạch đầu dòng: `- **Widget màn hình chính (feature home-widget):** target `DearEmbeiuWidget` (WidgetKit, iOS 15) thêm bằng `scripts/ios-add-widget-target.sh` (gem xcodeproj của CocoaPods Homebrew: `GEM_HOME=$(brew --prefix cocoapods)/libexec`, KHÔNG set `GEM_PATH`). Bundle `com.tony.dearembeiu[.dev].widget`; App Group `group.com.tony.dearembeiu[.dev]` qua build setting `APP_GROUP_ID` → Info.plist `AppGroupId` (cả Runner lẫn widget). Version/build lấy từ `Generated.xcconfig`. ⚠️ Lần archive đầu Xcode phải đăng nhập Apple ID để tạo App Group cho App ID `com.tony.dearembeiu` + `.widget` (như Sign in with Apple/HealthKit). `DayMath.swift` kiểm bằng `scripts/check-widget-daymath.sh` (swiftc, không cần simulator).`
- §13 thêm: `- **`scripts/check-widget-daymath.sh`** — kiểm công thức widget iOS (27 check). · **`scripts/ios-add-widget-target.sh`** — thêm target widget (idempotent).`

`project/build-guide.md` thêm mục `## Widget extension (home-widget)` 5–8 dòng: script thêm target, App Group cần Apple ID khi archive, `.appex` nằm trong `PlugIns/` không bị script Strip đụng, `flutter build ios --debug --no-codesign` để kiểm extension.

- [ ] **Step 5: Commit + push**

```bash
git add project CLAUDE.md
git commit -m "$(cat <<'EOF'
docs(home-widget): Dev xong — cập nhật dev/design/overview, ROADMAP, CLAUDE.md, build-guide

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01Fe9gCYrrfgYjeuLy2WrVgg
EOF
)"
git push -u origin feature/home-widget
git status --short
```
Expected: push OK, `git status` sạch.

---

## Edge case kỹ thuật (đã có task xử lý)
- Đổi ngôn ngữ: AppL10n đổi sau frame kế → bridge dùng post-frame + `scheduleFrame` (Task 2).
- App nền khi couple đổi (người ấy sửa tên): không có frame → gửi khi quay lại foreground (chấp nhận).
- Chưa mở app sau khi cập nhật: kho trống → `empty_tap` native (Task 4/7).
- 6 chữ số: `minimumScaleFactor 0.6` / `autoSize 24–40sp`.
- Dev + prod chung máy: App Group riêng; Android khác applicationId nên prefs tự tách.
- Chạm widget khi app chạy nền: iOS `openURLContexts`, Android `onNewIntent` (CLEAR_TOP|SINGLE_TOP, intent explicit).

## Checklist implement
- [x] Task 1 · [x] Task 2 · [x] Task 3 · [x] Task 4 · [x] Task 5 (iOS 15/16, 0:00, entitlement ký thật chưa kiểm; tinted theo ruling) · [x] Task 6 · [x] Task 7 · [x] Task 8
- [x] `flutter analyze` sạch · `flutter test` pass · `scripts/check-widget-daymath.sh` OK · gradle `DayMathTest` pass (chạy lại 2026-10-12 ở Task 8)
- [x] Không hardcode chuỗi hiển thị ngoài 2 ngoại lệ D4 (gallery + empty_tap native). Đã grep native: chỉ còn tên thương hiệu "DEAR EMBEIU" làm chuỗi dự phòng của chip trống (cùng giá trị `HomeWidgetSnapshot.emptyChip`).

## Nhật ký implement
- [2026-10-12] [Dev] Viết kế hoạch 8 task (writing-plans) sau khi user duyệt thiết kế. Chưa code.
- [2026-10-12] [Dev] **Task 1** `6b86767` — `HomeWidgetSnapshot.build` (chuỗi dịch sẵn, số để native tính) + key `widgetEmptyTap` vi/en. Test 5/5, analyze 0.
- [2026-10-12] [Dev] **Task 2** `2b39384` → `aa66100` → `bb73ac1` — bridge `dear_embeiu/widget`, event `widget_tap`, `_MyAppState` giữ CoupleProvider + LocaleProvider. Hai vòng vá: không đẩy `empty` khi đang nạp / nạp lỗi (cold start), `_lastSent` chỉ ghi sau khi gửi xong (hỏng thì retry), `SessionResolver` gọi `loadCoupleForUser(null)` ở nhánh guest + chưa xác thực email để đăng xuất thì widget về trống. Test bridge 2/2, `flutter test` 548, analyze 0.
- [2026-10-12] [Dev] **Task 3** `8df2ea8` → `c75cda3` → `9cfa5b4` → `276df3d` — `DayMath.swift` + `scripts/check-widget-daymath.sh` (swiftc, chạy dưới `-AppleLocale th_TH`). Ba vòng vá công thức: mặc định lịch Gregorian (máy lịch Phật đọc "2023" thành năm khác), bỏ `ordinality` (lệch theo UTC), đếm theo y/m/d rồi lấy hiệu ngày trong lịch UTC như Dart (DST bỏ đúng nửa đêm ngày yêu — Havana). 30 check; quét 350.640 điểm, 0 sai.
- [2026-10-12] [Dev] **Task 4** `a5901c0` → `dcf227b` — target `DearEmbeiuWidget` (WidgetKit, iOS 15) + `HomeWidgetChannel` + App Group qua `APP_GROUP_ID` + `scripts/ios-add-widget-target.{sh,rb}`. Script lệch plan 2 chỗ, đã đồng bộ: thêm `PRODUCT_NAME`, xếp phase Embed trước Thin Binary (nếu không Xcode báo `Cycle inside Runner`). `flutter build ios --debug --no-codesign` OK, `.appex` nằm trong `PlugIns/`. Vòng vá: tinted bọc cả chip, cột phải bản vừa cắt chữ, PrivacyInfo `1C8F.1` (cả Runner).
- [2026-10-12] [Dev] **Task 5** smoke iOS — iPhone 17 (iOS 26.3) + iPhone 16e (iOS 18.6): số 649 = Home, đổi ngôn ngữ, đăng xuất / đăng nhập lại, chạm widget (đúng 1 log mỗi lần chạm), Dynamic Type AX5 đều PASS. Tinted / Clear FAIL P1 (hệ thống tô cả pill, tên còn 1,05:1) → vá `4cef979` (`AccentedReader`, pill .22 khi accented): tint mặc định 5,47:1, tint đậm / iOS 26 Tinted / Clear 1,6–4,0:1 = giới hạn nền tảng, chấp nhận ở bản đầu. Chưa kiểm iOS 15/16, 0:00, dòng dài nhất, entitlement khi ký thật.
- [2026-10-12] [Dev] **Task 6** `b26c621` — `DayMath.kt` + 5 test JUnit 4 (cùng vector với Swift). `DayMathTest` 5/5.
- [2026-10-12] [Dev] **Task 7** `3e75661` → `daf8216` → `fb7f1bd` — `DayCounterWidget` (2×2 kéo tới 4×2) + `WidgetStore` + channel trong `MainActivity` + cờ `widget_tap`. Smoke emulator Pixel_10 (API 37): 2×2, 4×2, nhóm hàng nghìn trên ART ("1.199" / "1,199"), đổi ngôn ngữ 2 chiều, đăng xuất / đăng nhập, chạm (app tắt → `medium`, app nền → `small`). Hai vòng vá: font hệ thống Roboto (D11) + 2 dòng dài cột phải co chữ; `widget_tap` không đếm lại khi mở từ Recents, số đủ 40sp (`includeFontPadding=false`), "Bắt đầu từ" 2 dòng, glow chuyển vào `widget_bg` để API dưới 31 không tràn góc bo.
- [2026-10-12] [Dev] **Merge** `f75e00d` (nhánh iOS) + `bd1aa8f` (nhánh Android) vào `feature/home-widget`, `--no-ff`, không conflict.
- [2026-10-12] [Dev] **Task 8** — kiểm tổng: `flutter analyze` 0 · `flutter test` 548 pass (3 skip) · `scripts/check-widget-daymath.sh` OK 30 check · `DayMathTest` 5/5 · diff backend rỗng. Đồng bộ kế hoạch với code: script Ruby, event Analytics, vị trí `AppGroupId` trong Info.plist (mọi khối `Create` còn lại đã khớp từng byte). Cập nhật overview / design / test, ROADMAP, CLAUDE.md, build-guide.
- [2026-10-12] [Dev] **Nợ / minor chuyển Tester:** việc chưa kiểm và minor chưa vá nằm ở [test.md](test.md) (mục "Checklist cho Tester" và "Nợ đã biết"). Không có lỗi chặn. Ưu tiên vá nếu có đợt gom: chọn "Theo hệ thống" mà `AppL10n` giữ ngôn ngữ cũ nên widget đổi chữ trễ tới lần mở app kế (gốc ở `LocaleProvider.setLocale(null)`).
- [2026-10-12] [Dev] **Ảnh thẻ đếm lên widget + nền sáng lại** (user: nền widget đậm hơn cả app; muốn widget hiện ảnh couple đang chọn ở chỗ vuốt, không có thì ảnh mặc định). Bridge thêm `pushPhoto(key, local, remote)` → kênh `setPhoto(Uint8List? png)`: Dart giải mã ảnh (file local trước, không thì cache mạng — đúng thứ tự CounterCard) qua `ResizeImage` fit 720px, gửi PNG; native ghi `widget_photo.png` (iOS: App Group container · Android: `filesDir`), null = xoá. Home gọi `pushPhoto` ngay trong `build` với ứng viên đang hiện (`counterBg`) — bridge dedupe theo key nên chỉ tốn công sau khi vuốt / người ấy vuốt / đổi whitelist / ảnh nạp xong; `push(null)` (đăng xuất, rời couple) xoá ảnh luôn. Widget: iOS `WidgetBackground(photo:)` center-crop + scrim .18→.60; Android `ImageView` + `widget_scrim` (GONE khi không ảnh), bitmap center-crop theo ô (min width × max height) và bo góc nướng vào bitmap (`WidgetStore.photoBitmap`), `fitXY` nên launcher xoay ngang hơi kéo giãn (ghi `ponytail:`). Trạng thái trống không bao giờ hiện ảnh dù file còn. **Ảnh mặc định = gradient sunsetRomance của CounterCard** (#FF6B9D→#FF8FA3→#FFB6C1, scrim .08→.36) vẽ native — không thêm asset; muốn ảnh minh hoạ thật thì thay file sau. Kiểm: analyze 0 · `flutter test` 549 · Kotlin compile OK · `flutter build ios --debug --no-codesign` OK.
- [2026-10-12] [Dev] **Splash native** đổi `#FF6B9D` → `#E8B4D8` (dawn2, tâm gradient dawnBlush của landing/Home/loader) cho cả iOS + Android (kể cả `android_12`), logo tim trắng giữ nguyên; sinh lại bằng `dart run flutter_native_splash:create`. ⚠️ Tool này format lại `AndroidManifest.xml` và **xoá `android:screenOrientation="portrait"`** (khoá dọc của audit D3) → đã `git checkout` manifest, chỉ giữ `styles.xml` + ảnh nền. Lần sau chạy tool phải soát lại manifest.
