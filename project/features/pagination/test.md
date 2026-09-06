# Pagination — Test log

> File Tester sở hữu (PO dán hộ — tester read-only). Spec: [overview.md](overview.md) · Dev: [dev.md](dev.md).

## [2026-06-11] [tester] Nghiệm thu code-level đợt 1 — **FAIL** (3 major)

### Verify chung
- `fvm flutter analyze` → No issues found. `fvm flutter test` → 18/18 pass. [VERIFIED]
- KHÔNG đụng `firestore.rules` / `storage.rules` / `functions/` / `firestore.indexes.json` (git diff không chứa) — D6 đạt. [VERIFIED]
- Journal: `journal_provider.dart` không đổi; `journal_screen.dart` chỉ đổi header (feature design-unify trộn working tree, không liên quan pagination). AC5 đạt. [VERIFIED]
- Cursor đúng kiểu (trục 1): `uploadDate` ghi DateTime→Timestamp, đọc lại micro-lossless (`photo.dart:130-138`) → `Timestamp.fromDate(cursor)` tái tạo đúng; `createdAt` serverTimestamp tương tự (`love_note.dart:74-81`). Không có silent-empty-page do sai kiểu. [VERIFIED]
- Partner-delete detection (trục 3): KHÔNG false-positive khi 30+ ảnh mới cùng emission đẩy ảnh cũ khỏi window (ảnh rớt window LUÔN cũ hơn windowOldest mới → `isAfter` false → giữ lại, `photo_provider.dart:208-221`); false-negative chỉ rơi vào đúng phạm vi D4 đã chấp nhận. [VERIFIED]
- On-this-day: 29/02 skip năm thường đúng (`photo_service.dart:119-122`); anniversary năm nay → loop 0 vòng → `[]` không crash (`:118`); dedup key theo (couple, ngày, năm anniversary) + guard couple-đổi-giữa-fetch (`photo_provider.dart:313-327`); Home re-arm postFrame cover ngày đổi (nhánh Firebase). [VERIFIED]
- History: dedup id window-vs-pages qua map `_historyById`; nút Xem thêm đặt trên cùng (chat-style), `ListView reverse:true` neo đáy → prepend trang cũ không nhảy scroll (code-level); `startHistory` guard double-call, `dispose→stopHistory` không leak; note pending serverTimestamp (updatedAt null) không crash `_TimeDivider` (separator chỉ set khi non-null). [VERIFIED]
- Teardown: `clearForSignOut`/no-couple/đổi-couple reset đủ map+cursor+hasMore+count+onThisDay+lastWindowIds (`photo_provider.dart:117-126,146-160,542-550`); love-note `clear()`/`watchForCouple` reset history. NGOẠI LỆ: race in-flight → BUG-3. [VERIFIED]
- UI footer: <30 ảnh → hasMore=false ngay emission đầu, không loader; dòng kết chỉ khi `!hasMore && length > 30`; entrance chỉ 6 card đầu (`originalIndex < 6`) không re-animate trang sau; NotificationListener lọc `depth==0 && axis vertical` → marquee/scroller ngang không trigger nhầm (`gallery_screen.dart:1753-1761,1827-1852`). [VERIFIED]

### Bảng AC
| AC | Kết quả | Ghi chú |
|---|---|---|
| 1. Mở Gallery ≤30 doc + loadMore + loader | ⚠️ PASS code-level, trừ BUG-1 (edge gap) | limit 30 + startAfter + count [VERIFIED]; số read thực tế [CẦN TEST runtime] |
| 2. Realtime ảnh mới + xoá in-window 2 máy | ⚠️ PASS code-level, trừ BUG-1 | detect delete đúng [VERIFIED]; 2 máy [CẦN TEST runtime] |
| 3. On-this-day ngoài window + Profile tổng đúng | ⚠️ PASS Firebase-mode; **FAIL local-mode** (BUG-2) + count drift realtime (BUG-5) | |
| 4. History 50 + Xem thêm + note >200 xem được | ✅ PASS code-level | window 50 + cursor + dedup id [VERIFIED]; >200 [CẦN TEST runtime] |
| 5. Journal giữ nguyên | ✅ PASS | provider không đổi [VERIFIED] |
| 6. analyze 0 + test pass + không đụng rules/functions | ✅ PASS | [VERIFIED] |

### Bug
1. **BUG-1 · major · Gap ẩn vĩnh viễn trong feed khi >30 ảnh mới giữa 2 lần đồng bộ window.**
   - Lỗi: `_applyWindowEmission` chỉ init cursor 1 lần (`lib/providers/photo_provider.dart:231-234`), giả định emission sau luôn chồng lấn prefix đã tải — sai khi stream re-sync (resume/reconnect/cache→server) mà có > pageSize ảnh mới.
   - Actual: ảnh rank 31..N (mới hơn cursor, ngoài top-30) không vào map → feed có lỗ ẩn; loadMore đào dưới cursor nên không bao giờ lấp; pull-to-refresh không lành (same-couple giữ map+cursor, `:157-160`); chỉ cold restart hết.
   - Repro: couple ≥40 ảnh, máy A background → máy B batch-upload 35 ảnh → A resume → 5 ảnh "giữa" mất tích trong phiên.
2. **BUG-2 · major · Vòng lặp rebuild vô hạn ở nhánh local fallback.** `refreshOnThisDay` nhánh local notify vô điều kiện TRƯỚC dedup key (`photo_provider.dart:301-311` vs `:313-318`); Home gọi trong postFrame mỗi build dưới Consumer → notify→build→postFrame… mỗi frame, CPU/pin cháy khi Firebase chưa sẵn.
3. **BUG-3 · major (race + privacy) · `loadMorePhotos` thiếu guard couple sau await** (`photo_provider.dart:254-266`): sign-out/đổi couple khi fetch in-flight → ảnh couple CŨ upsert map mới + GHI `StorageService.savePhotos` (cache JSON nhiễm chéo). `_refreshTotalCount`/`refreshOnThisDay` có guard, loadMore bị sót.
4. **BUG-4 · minor · `loadMoreHistory` cùng lớp race** (`love_note_provider.dart:230-245`) — in-memory only.
5. **BUG-5 · minor · `photoCount` không refresh khi PARTNER add/delete** (`_countRefreshPending` 1 lần/sync) — tổng ở Profile đứng yên tới refresh.
6. **BUG-6 · minor (theoretical) · cursor theo GIÁ TRỊ timestamp** — 2 ảnh trùng uploadDate đến micro giây tại biên trang → skip 1 ảnh; fix chuẩn `startAfterDocument`. Ghi nợ.

### Ghi nhận không tính bug
- Ảnh trượt VÀO window sau khi partner xoá (cũ hơn cursor) ẩn tới lần loadMore kế — tự lành, cosmetic.
- Note pending serverTimestamp sai vị trí thoáng chốc — transient.
- Đổi couple khi history đang mở không tự re-arm stream (Dev đã ghi nợ, chấp nhận).

### [CẦN TEST runtime] (2 thiết bị / smoke)
1. 2 máy: partner đăng ảnh realtime đầu feed; xoá in-window mất 2 máy (AC2).
2. Couple >30 ảnh: loadMore nhiều trang, loader/dòng kết, entrance, đếm read Firestore (AC1).
3. Repro BUG-1: batch-upload 35 ảnh khi máy kia background → resume.
4. Repro BUG-2: nhánh local fallback, DevTools rebuild counter ở Home.
5. On-this-day ảnh năm trước NGOÀI window + qua nửa đêm app mở.
6. History >200 notes: Xem thêm 4+ trang, scroll không nhảy.
7. Counter bg đặt ảnh cũ ngoài window → fallback ảnh đầu.
8. Profile count sau partner add (BUG-5).

### Verdict đợt 1
**FAIL** — BUG-1/2/3 major cần Dev fix; BUG-4/5 fix cùng vòng (rẻ); BUG-6 ghi nợ. Sau fix: re-verify code-level + smoke 2 máy.

## [2026-06-11] [po-gate] Re-verify đợt 2 sau Dev-fix — **PASS-có-điều-kiện (code-level)**
- 5/5 bug đã fix, PO đọc đĩa xác nhận từng hunk: BUG-1 khối re-sync detection + invariant "feedPhotos = prefix liên tục" (`photo_provider.dart` `_applyWindowEmission`) · BUG-2 dedup key trước nhánh local + notify-chỉ-khi-đổi (`refreshOnThisDay`) · BUG-3 guard `coupleId == _currentUser?.coupleId` sau await bọc upsert+cursor+`savePhotos` (`loadMorePhotos`) · BUG-4 guard tương tự (`love_note_provider.loadMoreHistory`) · BUG-5 `_applyWindowEmission` trả `membershipChanged` → refresh aggregate count khi partner add/delete.
- `fvm flutter analyze` 0 issue · `fvm flutter test` 18/18. BUG-6 ghi nợ (startAfterDocument).
- **Điều kiện còn lại:** 8 mục [CẦN TEST runtime] ở trên (2 thiết bị) — đặc biệt repro BUG-1 (batch 35 ảnh + resume) và BUG-5 (count partner-add).
