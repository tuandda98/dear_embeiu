# Build & run — Chi tiết gotchas

> Chi tiết tách từ `CLAUDE.md §13`. Lệnh thường dùng ở CLAUDE.md §13; file này chứa gotchas và cơ chế nền.

## iOS IPA build gotchas (gặp 2026-06-06)

1. **KHÔNG chạy nhiều `flutter build ipa` song song/nền chồng nhau** → process `xcodebuild/swift-frontend` mồ côi giành chung DerivedData → `accessing build database … disk I/O error`. Gặp thì:
   ```
   pkill -f "Developer/usr/bin/xcodebuild"
   pkill -f "XcodeDefault.xctoolchain.*swift-frontend"
   pkill -f frontend_server_aot
   rm -rf ~/Library/Developer/Xcode/DerivedData/Runner-*
   ```
2. CocoaPods (Ruby 4.0.2) báo `Ignoring ffi … extensions not built` + lỗi gRPC-Core modulemap → fix: `brew reinstall cocoapods` rồi `cd ios && pod install` (warning ffi là benign, vẫn cài xong).
3. `flutter clean` xoá ephemeral → ép `pod install` chạy lại (lộ lỗi cocoapods); `Pods/` KHÔNG bị clean xoá.

## iOS Simulator — native_assets bug (Flutter 3.22+, vẫn còn 3.41.6, 2026-06-07)

`flutter run` cho simulator không truyền `SdkRoot` vào native_assets hooks → `objective_c` package (Firebase dùng) compile **device binary** (platform 2) thay vì simulator (platform 7) → crash `DOBJC_initializeApi / Failed to load dynamic library` kẹt splash trên simulator.

**Workaround:** dùng `scripts/ios-sim.sh` thay `flutter run` — script tự compile đúng trước khi run. Sau `flutter clean` thì `build/native_assets/ios/` bị xoá → cần chạy `scripts/fix-simulator-native-assets.sh` (hoặc `ios-sim.sh --clean`) trước khi run lại.

**3 gotcha gặp khi chạy lại trên máy mới (2026-06-08) — đã vá tận gốc trong script:**
1. **`Build input file cannot be found: Runner/GoogleService-Info.plist`** — file đã `git mv` ra `ios/config/{dev,prod}/` + gitignore; Xcode kiểm tra input tồn tại TRƯỚC khi script phase copy. **Vá:** `ios/Podfile` post_install **seed** file từ `config/prod` (fallback an toàn) nếu thiếu. Gỡ tay: `cp ios/config/prod/GoogleService-Info.plist ios/Runner/GoogleService-Info.plist`.
2. **`Source not found: objective_c-<ver>/src` → "Run: flutter pub get"** (dù đã pub get) — `fix-simulator-native-assets.sh` hardcode `hosted/pub.dev/`, nhưng package tải từ **mirror** (vd `pub.flutter-io.cn`) nên nằm ở `hosted/<mirror>/`. **Vá:** script dò mọi host dưới `$PUB_CACHE/hosted/*/objective_c-<ver>/src`.
3. **`Package(s) objective_c require the native assets feature to be enabled`** (lặp dù đã bật cờ) — `ios-sim.sh` hardcode **bare `flutter`** (subprocess né hook ép-fvm → chạy nhầm 3.5.4, đọc config cũ). **Vá:** script tự chọn toolchain (`fvm flutter` nếu có `.fvmrc`/`.fvm/`, ngược lại `flutter`). Ngoài ra phải bật cờ 1 lần: `fvm flutter config --enable-native-assets`.

## iOS Strip Invalid Architectures

Build-phase "Strip Invalid Architectures" (thêm vào target Runner qua `ios/Podfile` post_install bằng Xcodeproj, 2026-06-01): lipo remove `i386/x86_64` khỏi mọi embedded framework + re-sign. Bắt buộc vì `objective_c.framework` (transitive native FFI) ship fat binary có slice simulator → Transporter báo *Validation failed (409) Invalid executable … x86_64 slice*. Idempotent, sống qua `pod install`.

⚠️ **GUARD simulator (2026-06-04):** script đầu phase `if [ "${PLATFORM_NAME}" = "iphonesimulator" ]; then exit 0; fi` — KHÔNG strip khi build simulator (nếu strip, slice arm64-simulator/x86_64 của `objective_c.framework` bị xoá → app crash `DOBJC_initializeApi … Failed to load dynamic library` kẹt splash trên simulator). Chỉ strip cho device/archive (`iphoneos`). Podfile dùng **find-or-update** phase (không phải add-once) nên `pod install` luôn cập nhật script.

🔴 **RELEASE IPA phải `flutter clean` TRƯỚC nếu session đã chạy iOS simulator (2026-06-21):** chạy `scripts/ios-sim.sh` compile `objective_c` (native FFI) thành dylib **simulator** ở `build/native_assets/ios/`. Sau đó `flutter build ipa --release` **tái dùng** dylib simulator đó (bug cache native_assets) → IPA device embed `objective_c.framework` slice **arm64 platform IOSSIMULATOR** → Transporter *Validation failed (409): references an unsupported platform in the arm64 slice*. Strip-Arch KHÔNG bắt được (slice là arm64, không phải x86_64; lipo không tách được arm64-device vs arm64-sim). **Fix: `flutter clean` (xoá `build/native_assets/`) → `flutter build ipa --release` → device build compile lại `objective_c` đúng platform IOS.** **Verify trước khi nộp:** `vtool -show-build <ipa>/…/objective_c.framework/objective_c | grep platform` phải = `IOS` (không `IOSSIMULATOR`). Lưu ý: `flutter clean` xoá luôn AAB → build lại AAB sau.

## Enforcement tự động (Stop hook)

`.claude/hooks/run-firebase-rules-tests.sh` (wire ở `.claude/settings.json`, committed) băm `firestore.rules`+`storage.rules`+`functions/index.js`; khi đổi so với lần PASS gần nhất thì tự chạy lại TOÀN BỘ rules test cuối lượt, FAIL thì CHẶN. Máy thiếu JDK 21+ → bỏ qua êm. Chi tiết: [`firebase_rules_test/README.md`](../firebase_rules_test/README.md).

## Config files & vị trí

- `android/app/google-services.json` — PROD Firebase config
- `android/app/src/debug/google-services.json`, `src/profile/google-services.json` — DEV config
- `ios/config/prod/GoogleService-Info.plist`, `ios/config/dev/GoogleService-Info.plist` — nguồn thật (committed)
- `ios/Runner/GoogleService-Info.plist` — dynamic (gitignored, copy by build-phase `Select GoogleService-Info (env)`)
- `.firebaserc` — alias `default`=`tonyembeiu-dev`, `prod`, `dev`
- `android/key.properties` + keystore — KHÔNG commit; signing fallback debug nếu thiếu
