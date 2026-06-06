# 💻 Dev — App robustness (Pass 1: diệt freeze cold-start + logout/delete bền)

> Dev sở hữu. Bám kiến trúc Provider + service (`../../../CLAUDE.md` mục 2). Pass này KHÔNG đổi hành vi đúng — chỉ bỏ block mạng khỏi đường khởi động/auth + thêm timeout có fallback rõ ràng.

- **Trạng thái dev:** xong — chờ test (Tester smoke-test runtime cold-start/offline/logout/delete)
- **Người/role:** Dev

## Kế hoạch kỹ thuật
- *Gốc rễ freeze (audit):* cold-start resolve route đi qua chuỗi `await` mạng TUẦN TỰ, KHÔNG có timeout nào trong toàn `lib/` (`grep '.timeout(' lib/` = 0). Bất kỳ Firestore get / authStateChanges / getIdToken(true) / FCM permission nào treo → splash treo vô hạn.
- *Cách tiếp cận:* (1) bỏ network không-thiết-yếu khỏi critical path (fire-and-forget); (2) thêm timeout + nhánh fallback RÕ RÀNG cho mọi await mạng còn lại trong đường resolve; (3) backstop tổng 8s cho resolveStartRoute; (4) loading + chống double-submit cho logout/delete; (5) push init dời sau first frame nhưng GIỮ background handler đăng ký sớm.
- *Cần deploy?* KHÔNG (client-only; không đụng rules/functions/native).

## Thay đổi theo nhóm A–D (file:line gốc)

### A — Cold-start không block bằng mạng chậm
- **A1** `lib/services/auth_service.dart` `_ensureFirebaseSessionReady`: `getIdToken(true)` → `getIdToken()` (bỏ force-refresh; token cache ~1h đủ để resolve route, bỏ 1 round-trip mạng bắt buộc mỗi mở app). Write cần token tươi vẫn tự force-refresh ở permission-recovery của riêng chúng (couple_service `_attemptPermissionRecovery`, join retry) — không đụng.
- **A2** cùng hàm: `authStateChanges().firstWhere(...)` thêm `.timeout(5s, onTimeout: throw AuthException(authSessionNotReady))` → timeout coi như session chưa sẵn sàng, bubble lên `AuthProvider.initialize` catch → unauthenticated → guest. Không treo vô hạn.
- **A3** `lib/providers/auth_provider.dart` `initialize()`: `await PushNotificationService.syncForUser(...)` → `unawaited(...)`. Đăng ký FCM token/device là plumbing push, không quyết định route; chạy off critical path, dù sao cũng re-sync mỗi lần app resume (`didChangeAppLifecycleState`).
- **A4** `auth_service.dart` `getCurrentUser` (nhánh Firebase): `await _userService.updateUserProfile(refreshedProfile)` (chỉ cập nhật lastSeenAt/updatedAt) → `unawaited(...)`. Giữ logic, bỏ chặn route bằng 2 write Firestore.
- **A5** timeout 5s + fallback local cache cho 2 fetch mạng trong đường resolve:
  - `auth_service.dart` `fetchUserProfile` → `.timeout(5s)`; on `TimeoutException` dựng `_buildOfflineFallbackProfile(firebaseUser)` (helper mới): identity từ Firebase user (đã authed) + couple cache đĩa (StorageService.loadCouple) → nếu memberIds chứa uid thì set coupleId+status (`in_couple` nếu ≥2 member, else `waiting_partner`) ⇒ route home thay vì setup; nếu không có cache hợp lệ → setup.
  - `couple_service.dart` `fetchCouple` (nhánh Firebase): `.get().timeout(5s)`; on `TimeoutException` trả `StorageService.loadCouple()` nếu id khớp, else null. Watcher realtime của CoupleProvider vẫn reconcile về server copy khi mạng tới.
- **A6** `lib/app/session_resolver.dart`: tách thân resolve thành `_resolve({...providers})`; `resolveStartRoute` race `_resolve().timeout(8s)`; on bất kỳ lỗi/timeout → `_safeFallbackRoute(authProvider)` (auth đã init & chưa auth → guest; có couple cache đĩa với memberIds → home; authed nhưng không cache → setup; else guest). Idempotent, splash chỉ `pushReplacementNamed` 1 lần ⇒ không double-navigate; resolution dở dang vẫn chạy nền & wire watcher.
- **A7** `lib/main.dart`: chỉ giữ TRƯỚC `runApp` những gì frame đầu / correctness cần — `FirebaseBootstrapService.initialize()` (Firebase + Crashlytics hook), đăng ký `FirebaseMessaging.onBackgroundMessage` (sync, không mạng — phải sớm kẻo mất push terminated-state), và `InstallStateService.handleFreshInstall` (PHẢI xong trước splash resolve, nếu không reinstall có thể restore session cũ — correctness-critical, giữ await). Phần còn lại (AnalyticsService.init, PushNotificationService.initialize, ReminderService.initialize, customReminders load+reschedule) dời vào `_initDeferredServices()` chạy `addPostFrameCallback` → `unawaited`, mỗi bước bọc try/catch riêng để 1 bước chậm/lỗi không kẹt bước khác. `customRemindersProvider` tạo trước runApp (rỗng), load sau frame (ChangeNotifier sẽ notify khi xong).

### B — Logout không kẹt
- `auth_provider.dart` `signOut()` đổi trả `Future<bool>`: `unregisterForUser` (Firestore delete) bọc `.timeout(5s)` + try/catch nuốt (best-effort; server-side `pruneDeadDevices` là backstop). `_authService.signOut()` là phần chính → false chỉ khi nó thật sự lỗi. `setUserId(null)` analytics → `unawaited`. `deleteAccount` provider cũng bọc `unregisterForUser` timeout 5s tương tự.
- `lib/screens/settings_screen.dart` logout dialog: đọc `bool` từ `signOut()`; false → snackbar `signOutFailedMsg` (l10n mới), KHÔNG điều hướng giả; true → `pushNamedAndRemoveUntil(authGate)` như cũ.

### C — Delete account: loading + chống double-submit + timeout
- `settings_screen.dart`: bọc TOÀN body Settings trong `BlockingLoadingOverlay(isVisible: authProvider.isLoading)` (Consumer<AuthProvider> ngoài cùng, GIỐNG Profile) → trong lúc delete/sign-out, UI bị chặn pointer, không mở lại dialog / bấm lần 2.
- `auth_service.dart` `deleteAccount` callable: `.call().timeout(60s)`; `TimeoutException` → `AuthException(authNetworkError)`. 60s vì CF recursiveDelete (couple subcollections + Storage purge) có thể lâu — ngắn quá sẽ false-fail.

### D — Analytics không chặn success path
- `auth_provider.dart` signIn (cũ :79) + signUp (cũ :115): `await AnalyticsService.setUserId(...)` → `unawaited(...)`.

## i18n
- Thêm key `signOutFailedMsg` vào CẢ `app_en.arb` + `app_vi.arb` rồi `fvm flutter gen-l10n` (getter đã sinh trong generated). VI: "Không thể đăng xuất. Vui lòng kiểm tra kết nối và thử lại." / EN: "Couldn't sign out. Please check your connection and try again."
- Timeout delete tái dùng key có sẵn `authNetworkError` (không thêm key mới).

## Đảm bảo KHÔNG phá correctness
- Route authed + có couple: nếu mạng OK, fetch trả về như cũ → home đúng. Nếu fetch timeout, fallback dùng couple cache đĩa → vẫn home; watcher realtime reconcile sau.
- Nhánh local-fallback (`!isUsingFirebase`) GIỮ NGUYÊN (không thêm timeout vào nhánh local — nó không gọi mạng).
- Push: background handler vẫn đăng ký trước runApp; `syncForUser` chỉ đổi từ await→fire-and-forget (vẫn chạy, vẫn re-sync mỗi resume) ⇒ token vẫn được đăng ký, partner vẫn nhận push.
- Reinstall purge giữ trước runApp ⇒ không restore nhầm session lần cài trước.

## Edge case kỹ thuật đã xử lý
- Mọi `.timeout` đều có nhánh xử lý rõ (catch→fallback), không nuốt-lỗi-thành-treo-khác.
- `_safeFallbackRoute` đọc cache đĩa có thể lỗi → bọc try/catch, fallback guest/setup theo auth status.
- `_initDeferredServices` mỗi bước try/catch độc lập.

## Verify
- `fvm flutter analyze` → **No issues found!** (0 issue, không có unawaited_futures / discarded-future warning).
- `fvm flutter test` → 29 pass / 1 fail. Fail là **pre-existing**: `test/widget_test.dart` "renders login screen scaffold" tìm chuỗi hardcode VN "Đăng nhập để tiếp tục" trong khi LoginScreen đã chuyển sang l10n (test dựng MaterialApp KHÔNG có l10n delegates → ra English). KHÔNG đụng tới bởi pass này (không sửa login_screen / widget_test / các key đó).

## Rủi ro / giả định cần Tester soi runtime
- Cold-start authed+couple khi mạng TỐT: vẫn vào home nhanh, dữ liệu couple/ảnh đúng (không regress).
- Cold-start authed+couple khi OFFLINE / mạng cực chậm: trong ≤8s phải vào home (từ cache) — không treo splash; khi mạng về, couple/ảnh tự cập nhật qua watcher.
- Cold-start chưa auth offline: vào guest, không treo.
- Logout khi mạng chập chờn: thoát về authGate ≤ ~5s; nếu signOut Firebase thật lỗi → snackbar, ở lại Settings (không màn trắng).
- Delete account: overlay chặn double-tap; thành công → authGate; timeout 60s → thông báo network, không treo.
- Push sau khi dời sync: đăng ảnh/ghép đôi vẫn đẩy notification cho partner (token vẫn đăng ký qua fire-and-forget + resume sync). Tester nên xác nhận E2E 2 máy.
- Analytics screen_view của màn splash có thể mất (observer bind sau first frame). Minor, không ảnh hưởng chức năng; các event funnel khác vẫn log sau khi init xong.

## Nhật ký implement
- [2026-06-04] [Dev] Pass 1 chống freeze cold-start + logout/delete bền: A1–A7 (auth_service, couple_service, auth_provider, session_resolver, main.dart), B (signOut→bool + timeout, settings dialog), C (BlockingLoadingOverlay theo authProvider.isLoading + deleteAccount timeout 60s), D (analytics fire-and-forget). Thêm i18n `signOutFailedMsg` (en+vi) + gen-l10n. analyze sạch; test 29/30 (1 fail pre-existing widget_test login). Không deploy (client-only).

---

# 💻 Dev — Pass 2: Photo performance (hết freeze chọn/hiện ảnh) + Gallery UX

> Mục tiêu: bỏ jank/OOM khi chọn & render ảnh; rõ trạng thái lỗi/đăng nhiều. PO chốt nén **1920px / quality 85**. Client-only, KHÔNG deploy.

## Pack 3 — Photo perf

### 1. Resize/nén native ở MỌI picker ảnh feed (đòn bẩy lớn nhất)
Thêm `imageQuality: 85, maxWidth: 1920, maxHeight: 1920` (image_picker resize off main-isolate, ảnh upload nhỏ hơn nhiều):
- `lib/screens/gallery_screen.dart` `_pickAndAddPhoto` `pickImage(...)` (~:148).
- `lib/screens/gallery_screen.dart` `_pickMultiplePhotos` `pickMultiImage(...)` (~:205, trong refactor batch).
- `lib/screens/home_screen.dart` `_pickAndAddPhoto` `pickImage(...)` (~:1035).
- setup avatar `_pickPhoto` (:100) GIỮ quality 92 (không đụng, theo brief).

### 2. `Image.file` decode đúng cỡ (cacheWidth) + cap remote (memCacheWidth)
Thêm 2 param optional `int? decodeWidth, decodeHeight` vào `SharedPhotoView` + `SharedCouplePhotoView`. Map vào `Image.file(cacheWidth/cacheHeight)` cho local và `CachedNetworkImage(memCacheWidth/memCacheHeight)` cho remote. Callers thumbnail truyền `logicalSize * MediaQuery.devicePixelRatio`; fullscreen truyền `null` (full-res):
- `lib/widgets/shared_photo_view.dart` — rewrite: param decodeWidth/Height; remote→memCacheWidth, local→cacheWidth.
- `lib/widgets/shared_couple_photo_view.dart` — rewrite tương tự.
- Callers thumbnail truyền decodeWidth:
  - `gallery_screen.dart` today strip (96px) → `96 * dpr`; feed card full-width → `screenWidth * dpr`; couple avatar `_buildCoupleAvatar(size)` → `size * dpr` (588).
  - `home_screen.dart` recent thumbnail 64px → `64 * dpr` (:1489); recent memories card 140px → `140 * dpr` (:1641).
  - `profile_screen.dart` avatar badge 72px → `72 * dpr` (:868, đã thêm `BuildContext context` vào `_buildAvatarBadge` + call-site :360); cover banner blurred → `screenWidth * dpr` (:225).
  - `couple_info_card.dart` avatar 64px → `64 * dpr` (:62).
  - `setup_screen.dart` `_buildCircularPhotoPreview` Image.file 100px → `cacheWidth: 100 * dpr` (:990); SharedCouplePhotoView nhánh else → `decodeWidth: 100 * dpr`.
- **Fullscreen giữ full-res:** `gallery_screen.dart:2145` `_FullscreenPhotoPreview` `SharedPhotoView(fit: BoxFit.contain)` KHÔNG set decodeWidth (default null) → InteractiveViewer zoom 4x vẫn nét. Hero thumbnail→fullscreen: thumbnail dùng cỡ nhỏ, fullscreen full-res, Hero chỉ animate layout nên không nháy chất lượng.

### 3. Bỏ `existsSync()` đồng bộ trong build() khi có remoteUrl
- `shared_photo_view.dart` + `shared_couple_photo_view.dart`: ĐẢO thứ tự — ưu tiên `CachedNetworkImage(remoteUrl)` TRƯỚC (luồng Firebase đa số), chỉ `File(path).existsSync()` trong `errorWidget`/khi KHÔNG có remoteUrl (`_buildLocalOrFallback`). Hết stat đĩa mỗi build cho ảnh đã có remote.
- `setup_screen.dart:701` `hasPhoto` existsSync GIỮ: chỉ đụng `_couplePhotoPath` (ảnh local vừa chọn, chưa có remoteUrl) — đúng trường hợp "chỉ có local path".

## Pack 4 — Gallery UX

### 4. Error state (phân biệt empty thật vs lỗi)
- `gallery_screen.dart` build(): `hasLoadError = photoProvider.errorMessage != null && photos.isEmpty`. Khi true → `_buildErrorState()` (icon `cloudOff` + `galleryLoadErrorTitle` + subtitle trấn an "kỷ niệm vẫn an toàn" + nút `galleryRetryBtn` gọi `_retrySync`), KHÔNG hiện empty "đăng ảnh đầu tiên". Empty thật (errorMessage==null, photos rỗng) vẫn `_buildEmptyFeedState`.
- `_retrySync()` = `PhotoProvider.syncForUser(currentUser)` (re-arm Firestore stream; stream onError set errorMessage, success xoá vì syncForUser `_clearError`).

### 5. Pull-to-refresh
- Gallery: bọc `CustomScrollView` trong `RefreshIndicator(onRefresh: _retrySync)`, physics → `AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics())` để kéo được cả khi feed ngắn/empty/error.
- Home tab: bọc `SingleChildScrollView` trong `RefreshIndicator(onRefresh: _refreshHome)` (re-arm `PhotoProvider.syncForUser`), physics AlwaysScrollable.

### 6. Đăng NHIỀU ảnh: 1 overlay xuyên suốt + tiến độ + không bỏ ảnh khi lỗi
- `photo_provider.dart` thêm `Future<int> addPhotosBatch(paths, currentUser, progress)`: sở hữu loading lifecycle CHO CẢ BATCH (1 overlay, KHÔNG bật/tắt từng ảnh), mỗi ảnh chỉ cập nhật `loadingMessage` qua `progress(i+1, total)` rồi notify (overlay không nhấp nháy); 1 ảnh lỗi (`PhotoSyncException`) → nhớ message, **tiếp tục** phần còn lại; trả về số thành công. Analytics `logPhotoPosted/setHasPostedPhoto` chỉ khi ≥1 thành công.
- `gallery_screen.dart` `_pickMultiplePhotos` refactor: dùng `addPhotosBatch` với `progress: uploadingPhotoProgress(current,total)`; cuối báo gộp — đủ → `multiplePhotosAdded(n)`, có lỗi → `multiPhotosResultPartial(success,total,failed)`.

## i18n (en+vi, đã gen-l10n)
- `uploadingPhotoProgress(current,total)` — "Đang đăng {current}/{total}..." / "Uploading {current}/{total}...".
- `galleryLoadErrorTitle` — "Chưa tải được ảnh" / "Couldn't load photos".
- `galleryLoadErrorSubtitle` — "Kỷ niệm của bạn vẫn an toàn — chỉ là chưa kết nối tới được lúc này." / "Your memories are safe — we just couldn't reach them right now."
- `galleryRetryBtn` — "Thử lại" / "Try again".
- `multiPhotosResultPartial(success,total,failed)` — "Đã đăng {success}/{total}, {failed} ảnh lỗi" / "Posted {success}/{total}, {failed} failed".

## Verify
- `fvm flutter analyze` → **No issues found!** (0 issue).
- `fvm flutter test` → 28 pass / 1 fail. Fail là **pre-existing** `widget_test.dart` "renders login screen scaffold" (l10n mismatch, không liên quan pass này — đã `git stash` xác nhận fail trên cây sạch). Không có test ảnh/gallery widget-level nên perf cần Tester soi runtime.

## Rủi ro / giả định cần Tester soi runtime
- **Trade-off nén 1920/85:** ảnh upload sẽ nhỏ hơn đáng kể; với ảnh điện thoại 4000px+, downscale về 1920 cạnh dài → chấp nhận được khi xem trong app, nhưng người dùng zoom/crop/in ngoài app sẽ thấy mất chi tiết so với gốc. Đây là quyết định PO. Ảnh CŨ (đã upload full-res trước Pass 2) không đổi.
- **Đảo ưu tiên remote-trước-local trong SharedPhotoView:** trước đây local-trước. Giờ khi có remoteUrl, render từ CachedNetworkImage (cache đĩa của lib), local file chỉ dùng làm errorWidget/khi chưa upload. Hệ quả mong đợi: thoáng đầu có thể thấy shimmer (placeholder remote) thay vì hiện ngay local — nhưng sau cache lần đầu là tức thì, và bỏ được existsSync mỗi build. Tester xác nhận ảnh vẫn hiện đúng ở: feed, today strip, home recent, avatar couple, fullscreen.
- **decodeWidth × DPR:** thumbnail giờ decode nhỏ — Tester soi xem có ảnh nào bị mờ rõ ở thumbnail không (nếu mờ, tăng hệ số). Fullscreen PHẢI vẫn nét khi zoom 4x.
- **Batch upload:** chọn nhiều ảnh → overlay 1 lần, message chạy i/n không nháy; rút 1 ảnh hỏng (vd quyền/Storage) → các ảnh còn lại vẫn lên, snackbar báo "Đã đăng x/n, y ảnh lỗi". Tester thử mix ảnh ok + ảnh lỗi.
- **Pull-to-refresh khi stream treo:** kéo xuống Gallery/Home → re-arm sync, ảnh xuất hiện lại; error card "Thử lại" cũng re-arm.

## Nhật ký implement
- [2026-06-04] [Dev] Pass 2 photo perf + gallery UX: picker nén 1920/85 (gallery x2 + home); decodeWidth/Height (cacheWidth+memCacheWidth) cho SharedPhotoView/SharedCouplePhotoView + 9 call-site thumbnail truyền `size*dpr`, fullscreen giữ null; đảo ưu tiên remote-trước (bỏ existsSync mỗi build); error state phân biệt empty-vs-lỗi + RefreshIndicator (gallery+home); `addPhotosBatch` (1 overlay, progress i/n, lỗi-không-bỏ-ảnh) + `_pickMultiplePhotos` báo gộp. i18n 5 key mới en+vi + gen-l10n. analyze sạch; test 28/29 (1 fail pre-existing). Client-only, không deploy.
