# 💻 Dev — Reactions ❤️ trên ảnh

> Dev sở hữu. Đọc `overview.md` + `design.md` trước. Implement đúng logic + đúng design. Bám kiến trúc Provider + service (`../../../CLAUDE.md` mục 2).

- **Trạng thái dev:** xong (full-stack) — chờ PO deploy rules+functions+index rồi mới test runtime
- **Người/role:** Dev

## Kế hoạch kỹ thuật
- *Cách tiếp cận:* subcollection `couples/{coupleId}/photos/{photoId}/reactions/{uid}` (doc id = uid), denormalise `coupleId` vào doc để watch toàn bộ reaction của couple bằng MỘT `collectionGroup('reactions').where('coupleId', ==)`. Provider riêng `ReactionProvider` (giống love_note/daily_question) optimistic update + rollback. Widget tái dùng `reaction_bar.dart` cho 2 surface (feed + fullscreen on-dark) + badge read-only ở Home.
- *File tạo:*
  - `lib/models/photo_reaction.dart` — model `PhotoReaction` + `kReactionEmojis` (6 emoji) + `kDefaultReactionEmoji`.
  - `lib/services/reaction_service.dart` — `watchCoupleReactions` (collectionGroup), `setReaction`, `removeReaction`. Firebase-only, no-op khi local/guest.
  - `lib/providers/reaction_provider.dart` — `reactionsFor`/`myReaction`/`partnerReaction`/`hasError`, action `toggleHeart`/`setReaction`/`remove` optimistic + rollback.
  - `lib/widgets/reaction_bar.dart` — `ReactionBar`, `ReactionChip`, picker pill (blur overlay), `HeartBurstOverlay` (tự vẽ particle, không dùng confetti), `ReactionCountBadge`.
  - `firestore.indexes.json` (mới) — single-field collection-group index cho `reactions.coupleId`.
- *File sửa (file:line tham chiếu):*
  - `lib/main.dart` — đăng ký `ReactionProvider` trong MultiProvider.
  - `lib/app/session_resolver.dart` — `watchForCouple` khi couple active / `clear` khi sign-out/no-couple.
  - `lib/screens/gallery_screen.dart` — `_buildPhotoFeedCard`: double-tap (`_onDoubleTapPhoto`) + `HeartBurstOverlay` + `_buildReactionBar` sau caption; `_FullscreenPhotoPreview`: double-tap + burst trong PageView itemBuilder + `_buildPreviewReactionRow` (on-dark) cuối panel info đen.
  - `lib/screens/home_screen.dart` — `_buildHomeTab`: thêm `ReactionProvider.watchForCouple`; `_buildRecentPhotosSection`: `ReactionCountBadge` góc top-right (read-only, onTap giữ nguyên chuyển tab).
  - `lib/services/push_notification_service.dart` — map `type:'photo_reaction'` → tab Gallery(1).
  - `lib/services/analytics_service.dart` — event `reaction_set` (param action add/change/remove, không log emoji/ảnh).
  - `firestore.rules` — ADDITIVE path `reactions/{uid}` trong block photos.
  - `functions/index.js` — `notifyPhotoReaction` (onCreate, D3 skip self, debounce: chỉ onCreate) + `REACTION_COPY`/`buildReactionText`; `deleteCoupleCompletely` recursiveDelete reactions/photo.
  - `firebase.json` — thêm `firestore.indexes`.
  - `lib/l10n/app_en.arb` + `app_vi.arb` — 8 key reaction* (đã gen-l10n).
- *Thay đổi model / Firestore / CF / native:* model mới `PhotoReaction`; Firestore subcollection mới + index; CF mới `notifyPhotoReaction` + sửa teardown; KHÔNG đổi native.
- *Cần deploy (PO làm — Dev KHÔNG tự deploy):*
  - `firestore.rules` (path reactions) — BẮT BUỘC trước, không thì client permission-denied.
  - `functions` (`notifyPhotoReaction` + teardown) — để có push + dọn reactions khi xoá couple.
  - `firestore.indexes.json` — collection-group single-field index cho `reactions.coupleId`. Nếu watch báo `failed-precondition` (cần index) thì deploy index này; Firebase cũng có thể auto-gợi ý link tạo index khi query chạy lần đầu.

## Edge case kỹ thuật cần xử lý
- React ảnh của CHÍNH MÌNH được (D3); CF chỉ KHÔNG push khi reactor == author ảnh.
- Double-tap chỉ THÊM ❤️ (không toggle-off) — tránh vô tình gỡ; muốn gỡ thì tap nút tim.
- Double-tap fullscreen KHÔNG kích hoạt zoom (InteractiveViewer mặc định không double-tap-zoom; burst overlay `IgnorePointer` không chặn pan/zoom).
- Optimistic: `_pendingMine[photoId]` override state ngay; stream server xác nhận → drop override; ghi fail → rollback về giá trị cũ + SnackBar lỗi.
- Guest / couple==null / không Firebase → ẩn toàn bộ reaction bar (provider `isReady=false`).
- Emoji `❤️` có variation selector U+FE0F — đã verify model/rules byte-identical.

## Checklist implement
- [x] Model + service + provider (optimistic + rollback)
- [x] 3 surface UI (feed bar / fullscreen on-dark / home badge read-only)
- [x] firestore.rules ADDITIVE (chưa deploy)
- [x] CF notifyPhotoReaction + teardown recursiveDelete reactions (chưa deploy)
- [x] Deep-link photo_reaction → Gallery
- [x] i18n 8 key en+vi + gen-l10n
- [x] `fvm flutter analyze` sạch (No issues found)
- [x] `node --check functions/index.js` PASS
- [x] `fvm flutter test` — 21 pass, chỉ pre-existing `widget_test.dart` fail (Provider/SecureStorage/l10n setup, không liên quan reactions)
- [x] Không hardcode chuỗi UI (qua l10n); push copy localize trong CF (không qua ARB client)

## Nhật ký implement
- [2026-06-04] [Dev] Implement full-stack Reactions ❤️: model `PhotoReaction`+6 emoji, `ReactionService` (collectionGroup watch), `ReactionProvider` optimistic+rollback, widget `reaction_bar.dart` (heart 3 state + chip + picker pill blur + heart-burst tự vẽ + badge read-only). Chèn vào feed card + fullscreen on-dark + Home badge. rules ADDITIVE, CF `notifyPhotoReaction` (D3 skip self, chỉ onCreate), teardown recursiveDelete reactions, deep-link, i18n. analyze sạch, node-check PASS. CHƯA deploy — chờ PO deploy rules+functions+index.
- [2026-06-08] [Dev] **FIX crash khi tap thả tim** (`reaction_bar.dart:241`): animation "pop" của `_HeartButton` dùng `TweenSequence(1.0→1.25→1.0).animate(CurvedAnimation(curve: Curves.easeOutBack))`. `easeOutBack` là curve **overshoot** (trả `t > 1.0`) → nuôi vào `TweenSequence.transform` vốn assert `t ∈ [0,1]` → ngay khi tap reaction (hoặc khi `didUpdateWidget` pop lúc Gallery có ảnh đã-react) **vỡ assertion trong performLayout** → kéo theo **bão lỗi semantics mỗi frame** (`!semantics.parentDataDirty`, `Each child must be laid out exactly once`…). Stack báo nhầm về `home_screen.dart:297` (Scaffold) vì Gallery là tab trong IndexedStack của Home; trình báo-lỗi (WidgetInspector→Crashlytics) còn tự vấp khi `_AnimatedEvaluation.toString()` eval lại animation out-of-range. **Fix:** đổi sang `curve: AppMotion.curve` (`easeOutCubic`, bounded [0,1]) — TweenSequence vẫn tự tạo cú pop, `t` luôn hợp lệ. Quét `lib/`: đây là **TweenSequence DUY NHẤT** + overshoot-curve duy nhất → nguồn phát duy nhất. analyze sạch; verify runtime trên iOS sim (log khởi động 0 lỗi). Debug-only (release strip assertion + không inspector) nhưng vẫn fix tận gốc.
