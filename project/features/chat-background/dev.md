# 💻 Dev — Chat background

> Đọc [overview.md](overview.md) trước. Bám pattern "Ảnh nền thẻ đếm" (counter-bg).

- **Trạng thái dev:** xong code-level, `analyze` sạch — chờ smoke-test + deploy rules
- **Người/role:** Dev

## Kế hoạch kỹ thuật (đã làm)
- *Cách tiếp cận:* clone pattern counter-bg nhưng single-select + lọc kích thước. Nền dùng chung qua `prefs/home`.
- *File đụng tới:*
  - `firestore.rules` — thêm `chatBgPhotoId` (string ≤200) vào whitelist `hasOnly` + validate ở `match /prefs/{prefId}`. **Additive**, backward-compat.
  - `firebase_rules_test/test/firestore.couples-sub.test.js` — +2 case (set/clear `chatBgPhotoId`; reject >200). Emulator: **172 passing**.
  - `lib/services/home_prefs_service.dart` — thêm `watchChatBg(coupleId)→Stream<String?>` (null/'' = không nền) + `setChatBg(coupleId, photoId)` (''=xoá), MERGE, fail-soft.
  - `lib/screens/chat_bg_screen.dart` — **MỚI**. Picker: candidate = cover ('couple') + ảnh gallery; decode kích thước thật qua `ImageStream` (`_minShortSide=720`, valid = `h≥w && w≥720`); grid 3 cột tile dọc; tile [0] = "Mặc định" (xoá); Save → Hive `chat_bg_photo_<coupleId>` + `setChatBg`; PopScope discard-guard. Hiện trạng đo: "Đang lọc ảnh…" → nếu 0 ảnh hợp lệ hiện empty-hint.
  - `lib/screens/home_screen.dart` — **render nền Ở TẦNG SHELL để full-bleed** (2026-06-18, sau khi user yêu cầu "full screen"): ChatScreen nằm trong `SafeArea`+`IndexedStack` dùng chung → KHÔNG tự tràn lên status bar được (bị IndexedStack clip). Nên: piggyback watch `watchChatBg` vào `_ensureCounterBgLoaded` (`_chatBgKey` + `_chatBgSub`, seed Hive); `_resolveChatBg(couple, photos)`; restructure body `Stack` = `Positioned.fill(gradient base)` → `if chatTab && chatBg!=null` `Positioned.fill(Image cover)` + `Positioned.fill(scrim)` → `SafeArea(IndexedStack)` (trong suốt) → nav. Ảnh phủ cả vùng status bar; chip/hội thoại/composer vẫn nằm trong SafeArea. `_chatBgSub` cancel ở dispose.
  - `lib/screens/chat_screen.dart` — giữ **trong suốt** (không tự vẽ nền); bản nháp đầu từng bọc Stack trong ChatScreen nhưng bị IndexedStack clip nên đã **chuyển lên HomeScreen**.
  - `lib/screens/settings_screen.dart` — `_navRow` "Ảnh nền đoạn chat" (icon `message`) → `ChatBgScreen` (route `ChatBg`).
  - `lib/l10n/app_en.arb` + `app_vi.arb` — +12 key (`settingsChatBg*`, `chatBg*`); `gen-l10n` đã chạy.
- *Thay đổi backend:* +1 field `prefs/home.chatBgPhotoId`. Không CF, không native.
- *Cần deploy?* **rules** (additive). Chưa deploy — chờ user (theo lệ "prod chờ lệnh"; DEV cũng chưa deploy).

## Edge case đã xử lý
- Ảnh đã chọn bị xoá khỏi gallery → `_resolveBg` trả null → tự về gradient.
- Local fallback (không Firebase) → watch rỗng, chỉ dùng Hive cache; Save vẫn ghi cache.
- Decode ảnh lỗi/undecodable → coi là không hợp lệ (ẩn khỏi picker).
- Đo kích thước cache theo key, không decode lại; chỉ kick 1 lần/candidate (`_requested`).
- Scrim gradient nhẹ (0x33/0x14/0x3D) giữ ngày tháng + bong bóng đọc rõ mà vẫn thấy ảnh.

## Còn lại / lưu ý
- ⚠️ Branch `phase3` có sẵn lỗi compile ở `lib/screens/love_tree_screen.dart` (WIP khác, 6–8 lỗi) — KHÔNG thuộc feature này, chưa fix.
- Lọc bằng decode ảnh: gallery couple nhỏ nên chấp nhận chi phí; ảnh remote-only sẽ tải full để đo (đã cache qua CachedNetworkImageProvider).

## Nhật ký implement
- [2026-06-18] [Dev] Code xong toàn bộ: rules+test (172 pass), service, picker, render, settings row, l10n. `flutter analyze` sạch.
- [2026-06-18] [Dev] **Deploy rules DEV** (`tonyembeiu-dev`) — fix bug "lưu nhưng không hiện" (write bị rules từ chối vì field chưa có trong whitelist deploy).
- [2026-06-18] [Dev] User yêu cầu **full screen** → chuyển render nền từ ChatScreen lên **shell HomeScreen** (Positioned.fill sau SafeArea) để ảnh tràn cả status bar; ChatScreen về trong suốt. analyze sạch. PROD rules vẫn chờ lệnh.
- [2026-06-18] [Dev] **Header chat nâng cao tối đa** (top padding 16→0, sát status bar; chỉ tab Chat vì là drill-in).
- [2026-06-18] [Dev/Designer] **Gỡ avatar chữ-cái cạnh bong bóng tin đến** (user hỏi). Chat 1-1: vị trí trái/phải + màu bong bóng đã đủ phân biệt người gửi → avatar là idiom group-chat, ở đây chỉ là chấm thừa (theo iMessage/Zalo 1-1). Bong bóng partner giờ sát trái; dọn plumbing `partnerInitial` (`_ChatBubble`/`_MessageList`/build) + skeleton bỏ slot 32px. analyze sạch.
- [2026-06-18] [Dev] Fix **nút back chìm trên ảnh tối**: thêm param `HeaderIconButton.backed` (mặc định false) → khi icon-trên-ảnh thì glyph cưỡi đĩa frosted GIỐNG `EyebrowChip` (trắng .72 + viền .65 + bóng rose, ink navy) → đọc được trên cả ảnh sáng lẫn tối. ChatScreen nhận `hasBackground` từ HomeScreen (`chatBg != null`) → bật `backed` cho nút back. Header gradient (không ảnh) vẫn bare-ink như cũ. analyze sạch.
