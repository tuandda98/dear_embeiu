# Pagination — Dev log

> File Dev sở hữu. Spec/quyết định D1–D6: [overview.md](overview.md).

## Trạng thái
- [2026-06-11] [dev] Implement xong Gallery + Love-note history theo D1–D6. Journal không đụng. `fvm flutter analyze` 0 issue, `fvm flutter test` pass, `fvm flutter gen-l10n` sạch. CHƯA commit, không đụng rules/functions/index (D6).
- [2026-06-11] [dev] **Fix vòng 2 theo test.md đợt 1 (FAIL):** vá BUG-1/2/3/4/5; BUG-6 ghi nợ theo verdict Tester. Chỉ đụng 2 file provider, KHÔNG đổi UI/ARB/rules. `fvm flutter analyze` 0 issue, `fvm flutter test` 18/18 pass. CHƯA commit.

## Fix vòng 2 (2026-06-11) — chi tiết

- **BUG-1** `photo_provider.dart` `_applyWindowEmission`: thêm phát hiện re-sync ĐỨT QUÃNG trước khi merge — điều kiện: cursor đã init + window ĐẦY + `windowOldest.isAfter(cursor)` + `newIds ∩ prefixIds == ∅` (prefixIds = id trong map có `uploadDate >= cursor`, tức window cũ + pages đã tải; on-this-day extras nằm ngoài nên không nhiễu). Khi trúng: `_paginationCursor = windowOldest`, `_hasMorePhotos = true` → toàn bộ prefix cũ tự rớt khỏi `feedPhotos` (getter lọc theo cursor) nên feed KHÔNG hở lỗ — invariant "feedPhotos = prefix liên tục" ghi comment ngay tại chỗ. Ảnh cũ vẫn nằm trong map (như on-this-day) và được loadMore upsert-dedup lấp lại dần khi user cuộn. Delete-detection trong cùng emission KHÔNG false-positive (ảnh window cũ đều CŨ hơn windowOldest mới → `isAfter` false → giữ).
- **BUG-2** `refreshOnThisDay`: dedup key (couple|ngày|năm anniversary) chuyển lên TRƯỚC nhánh local; nhánh local set key + chỉ `notifyListeners()` khi list id ĐỔI (helper `_samePhotoIds`, so cả thứ tự — 2 list đều newest-first). Gọi lặp từ postFrame mỗi build → lần 2 trở đi return sớm; lần đầu kết quả không đổi (vd rỗng→rỗng) cũng không notify → đứt vòng notify→build→postFrame. Nhánh Firebase giữ nguyên (key set trước fetch, catch reset key để retry).
- **BUG-3** `loadMorePhotos`: sau `await fetchOlderPhotos` → `if (coupleId == _currentUser?.coupleId)` mới upsert/dời cursor/hasMore/`StorageService.savePhotos`; lệch → bỏ nguyên trang (không nhiễm cache JSON). Cùng pattern guard `_refreshTotalCount`/`refreshOnThisDay`.
- **BUG-4** `love_note_provider.dart` `loadMoreHistory`: sau `await fetchOlderHistory` → `if (coupleId == _coupleId)` mới merge map/cursor/hasMore.
- **BUG-5** `_applyWindowEmission` trả `bool membershipChanged` (true khi có id CHƯA TỪNG có trong map, hoặc partner-delete được detect); listener trong `syncForUser`: emission đầu vẫn đi nhánh `_countRefreshPending`, các emission sau chỉ gọi `_refreshTotalCount` khi `membershipChanged` (caption edit / emission trùng id → không gọi = debounce).
- **Trade-off ghi nhận:**
  - BUG-1: sau reset, các ảnh older-pages đã tải tạm BIẾN khỏi feed tới khi user cuộn loadMore lại (đổi UX nhỏ lấy tính đúng — không thể hở lỗ ẩn). Map giữ nguyên nên StorageService cache không mất ảnh.
  - BUG-2: local mode giờ dedup 1 lần/ngày — nếu map local được nạp SAU lần gọi đầu trong cùng ngày thì on-this-day không tự tính lại; thực tế an toàn vì `syncForUser` local await `loadPhotos` xong mới tới lượt `refreshOnThisDay` (resolver + Home postFrame đều chạy sau), và ảnh add hôm nay có year == năm nay không bao giờ match, delete thì `deletePhoto` đã tự cập nhật `_onThisDayPhotos`.
  - BUG-3/4: stale completion vẫn set `_isLoadingMore/_historyLoadingMore = false` + notify — vô hại (state đã reset từ teardown), giữ code phẳng.
- **Rà repro test.md:** (1) B batch 35 ảnh, A resume → emission top-30 mới không giao prefix → reset cursor → loadMore trang kế trả rank 31–60 (gồm 5 ảnh "giữa") → không còn lỗ. (2) Local fallback: postFrame lặp → key-match return / no-change no-notify. (3) Sign-out giữa fetch → coupleId != null-user → bỏ trang. (4) tương tự với `_coupleId`. (5) partner add/delete → membershipChanged → count refresh. Các hành vi PASS đợt 1 (delete-detection, teardown, dedup window-vs-pages, footer UI) không đổi logic.

## Thay đổi theo file

### Gallery (D1–D4)
- `lib/services/photo_service.dart`
  - `watchCouplePhotos(coupleId, {limit = 30})` — thêm `.limit()` (window realtime D1).
  - MỚI `fetchOlderPhotos(coupleId, {required DateTime startAfter, limit = 30})` — orderBy uploadDate desc + `.startAfter([Timestamp.fromDate(...)])` + `.get()`.
  - MỚI `countPhotos(coupleId)` — AggregateQuery `.count().get()`, trả `null` khi local/lỗi (D2).
  - MỚI `fetchOnThisDay(coupleId, {today, since})` — 1 range query/năm từ `since.year`→`today.year-1`, skip năm không có ngày đó (29/02 — check `DateTime` normalize), chạy `Future.wait` (D3).
- `lib/providers/photo_provider.dart` (viết lại phần state)
  - Bộ nhớ ảnh = **map tích lũy `_photosById`** (D1); `_upsert` giữ semantics bảo toàn local path như cũ. `sortedPhotos` desc từ map.
  - MỚI `feedPhotos`: CHỈ prefix liên tục (uploadDate ≥ cursor) — ảnh on-this-day cũ upsert vào map nhưng KHÔNG render thành "lỗ thời gian" cuối feed.
  - `hasMorePhotos` / `isLoadingMore` / `loadMorePhotos()` — guard re-entrancy; **cursor `_paginationCursor` tracked RIÊNG** (oldest của window+pages), không lấy min của map (vì map còn chứa on-this-day extras → lấy min sẽ skip cả đoạn giữa).
  - Delete: client tự xoá → remove khỏi map ngay (kể cả ảnh ngoài window). Partner xoá TRONG window: detect từ emission — id biến mất khỏi window mà uploadDate MỚI HƠN oldest của window mới (hoặc window chưa đầy) thì không thể "rớt window" → là delete thật → remove (thỏa AC2; ảnh ngoài window stale theo D4).
  - `photoCount` = `_totalCount` (aggregate, refresh: emission đầu mỗi lần syncForUser + sau add/addBatch/delete thành công) fallback `map.length` (D2).
  - `onThisDayPhotos` + `refreshOnThisDay({required anniversary})` — dedup key (coupleId, ngày hôm nay); local mode filter in-memory từ map. Kết quả upsert vào map cho cinema/preview.
  - Local mode: load toàn bộ JSON như cũ, hasMore=false. `clearForSignOut`/đổi couple → reset toàn bộ state phân trang; re-sync CÙNG couple (pull-to-refresh) giữ map để feed không blank.
  - `updatePhotoCaption`: update map ngay cả Firebase mode (ảnh ngoài window không có emission để phản ánh).
- `lib/screens/gallery_screen.dart`
  - Feed đổi nguồn `sortedPhotos` → `feedPhotos` (cả chỗ mở preview từ feed card — index khớp).
  - `NotificationListener<ScrollNotification>` quanh CustomScrollView: `depth == 0 && axis vertical && extentAfter < 600` → `loadMorePhotos()`.
  - Footer feed: `isLoadingMore` → `ShimmerSkeleton` (120, r24); `!hasMorePhotos && length > 30` → dòng kết `galleryEndOfFeed` (13, textSecondary). Bottom inset tách thành SliverPadding cuối.
  - Showcase header (composer + compact) đổi `photos.length` → `photoProvider.photoCount` (D2).
  - Entrance animation giữ nguyên 6 item đầu.
- `lib/screens/home_screen.dart`
  - On-this-day rewire: `_onThisDayPhoto(provider.onThisDayPhotos)` thay vì lọc từ sortedPhotos; gọi `refreshOnThisDay(anniversary: couple.anniversaryDate)` trong postFrame re-arm block (dedup trong provider, cover ngày đổi khi app mở lâu).
- `lib/app/session_resolver.dart` — sau `syncForUser` khi couple active: `unawaited(refreshOnThisDay(...))` (fire-and-forget, không chặn resolve).

### Love-note history (D5)
- `lib/services/love_note_service.dart` — `watchHistory` default 200→**50**; MỚI `fetchOlderHistory(coupleId, {required DateTime startAfterCreatedAt, limit = 50})` `.get()` + cursor `Timestamp.fromDate`; local → `[]`.
- `lib/models/love_note.dart` — thêm field optional `id` (doc id, cần cho dedup window vs pages; additive, local notes id=null).
- `lib/providers/love_note_provider.dart` — XÓA `watchHistory()` (stream-cho-screen); MỚI `startHistory()`/`stopHistory()` (screen mở/đóng), map tích lũy `_historyById` (history append-only nên không cần delete-detection), `historyEntries`/`historyHasMore`/`historyLoadingMore`/`historyLoading`, `loadMoreHistory()` guard re-entrancy. Local mode: load all, hasMore=false. `clear()` + `watchForCouple` đổi couple → reset history state.
- `lib/screens/love_note_history_screen.dart` — Stateless→Stateful: `initState` startHistory / `dispose` stopHistory (giữ ref provider, không read context trong dispose); consume provider thay StreamBuilder; nút `_LoadMoreButton` copy y style journal (pill outline accentLove, w700, spinner inline, label tái dùng `journalLoadMore`) — đặt giữa header và note CŨ NHẤT (chat load older từ trên), chevron UP. Skeleton/empty giữ nguyên.

### i18n
- `app_en.arb` + `app_vi.arb`: key MỚI `galleryEndOfFeed` (vi "Đã hết kỷ niệm 💕, hãy tạo thêm kỷ niệm mới cùng nhau nhé" / en "That's every memory 💕 — go make some new ones together") → `fvm flutter gen-l10n`.

## Quyết định kiểu cursor (edge d)
- `photos.uploadDate`: app ghi `DateTime` qua `toFirestore()` → SDK convert **Timestamp**; `Photo._parseDateTime` đọc lại bằng `microsecondsSinceEpoch` (lossless) → `Timestamp.fromDate(cursor)` tái tạo ĐÚNG giá trị lưu. Không phải String ISO.
- `noteHistory.createdAt`: `FieldValue.serverTimestamp()` → **Timestamp**; `LoveNote._parseDateTime` cũng micro-lossless → cursor `Timestamp.fromDate` chuẩn.

## Edge đã rà
- (a) Đăng ảnh khi ở trang sâu: watch emission upsert theo id → hiện đầu feed, không duplicate, cursor không đổi.
- (b) loadMore spam: `_isLoadingMore` guard (photo + history).
- (c) 0 ảnh → empty state, cursor null, loadMore no-op; <30 ảnh → hasMore=false ngay emission đầu, không loader/không dòng kết; đúng 30 ảnh → 1 lần loadMore rỗng rồi tắt, không dòng kết (chỉ hiện khi >30).
- (e) 29/02: skip năm thường (DateTime(Y,2,29) normalize → 1/3 → bị check loại).
- (f) Sign-out/leaveCouple/đổi couple: reset map + cursor + count + onThisDay (photo) và history state (love note).
- Partner xoá ảnh trong window → biến mất 2 máy (detect emission); ngoài window → stale tới lần mở sau (D4, chấp nhận).

## Nợ / lưu ý cho Tester
- **Counter bg (prefs `counterBgPhotoId`)**: nếu ảnh nền là ảnh cũ ngoài window 30 → không còn trong candidates → fallback ảnh đầu. Tồn tại từ trước về logic, nhưng pagination làm dễ lộ hơn — cần smoke-test couple nhiều ảnh có bg đặt ảnh cũ.
- Deep-link mở ảnh từ notification chỉ tìm trong feed đã tải (ảnh quá cũ → land grid) — hành vi cũ với push photo mới thì luôn trong window, không regress.
- Đổi couple TRONG LÚC màn history đang mở → state reset, stream không tự re-arm (phải thoát mở lại màn) — case cực hiếm.
- Brief có ký tự lỗi mojibake trong chuỗi vi ("kỷ niệm �") — Dev chọn 💕 khớp bản en; PO confirm lại emoji.
- Spec ghi "cursor = uploadDate nhỏ nhất trong map" — Dev đổi thành cursor tracked riêng vì map còn chứa on-this-day extras (lấy min map sẽ skip toàn bộ ảnh giữa chừng). Cùng lý do thêm getter `feedPhotos` để feed không có "lỗ thời gian".

## Verify
- `fvm flutter analyze` → No issues found.
- `fvm flutter test` → All tests passed (18).
- `fvm flutter gen-l10n` → sạch, key mới có trong generated en+vi.
- Runtime 2 máy (realtime + loadMore + count) → chờ Tester smoke-test.
