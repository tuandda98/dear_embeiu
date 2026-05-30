# 🗺️ Roadmap riêng — Language (đa ngôn ngữ)

> Kế hoạch nội bộ feature. Toàn cảnh mọi feature: [`../../ROADMAP.md`](../../ROADMAP.md). Spec: [overview.md](overview.md).

- **Trạng thái feature:** ✅ Done (2026-05-31)

## Phân phase

### 🟢 Phase 1 — Bịt rò rỉ ngôn ngữ (P0) — ✅ Done
- [x] **Gap A** — ngày tháng theo locale (`Intl.defaultLocale` + `initializeDateFormatting`; dùng `feedDateFormat` + key mới `fullDateFormat`; bỏ "thg")
- [x] **Gap B** — push partner-photo đa ngôn ngữ (lưu `languageCode` vào devices + `functions/index.js` chọn text theo locale + **deployed 2026-05-31**)
- *Xong khi:* đổi EN → không còn ngày/notification tiếng Việt; 2 thiết bị couple nhận đúng ngôn ngữ. ✅

### 🟡 Phase 2 — Đúng chuẩn nền tảng (P1) — ✅ Done
- [x] **Gap C** — iOS Info.plist (`CFBundleLocalizations [en,vi]` + `CFBundleAllowMixedLocalizations`)
- [x] **Gap D** — preload locale (đọc Hive trước runApp + `LocaleProvider(initialLocale:)`) chống nhấp nháy cold start
- *Xong khi:* iOS Settings hiện đủ EN/VI; mở app lạnh không nháy sai ngôn ngữ. ✅

### ⚪ Phase 3 — Polish + UI chip (P2) — ✅ Done (trừ G)
- [x] **D2** — bỏ cờ → letter chip (Designer handoff xong)
- [x] **D3** — áp bảng format ngày (feedDateFormat + fullDateFormat)
- [x] **Gap E** — dọn ARB key chết (xoá `languageEnglish`/`languageVietnamese`, dùng `languageSystemDesc`)
- [x] **Gap F** — pill "System default" hiện `🌐 {mã}` (không còn "—")
- [ ] **Gap G** — log analytics `language_changed` — ⏸️ hoãn, **phụ thuộc feature analytics** (chưa có)

### 🔭 Tương lai (Later)
- [ ] Thêm ngôn ngữ thứ 3 (vd Hàn/Trung) — chỉ làm khi có nhu cầu thị trường.

## Mốc đã đạt
- [2026-05-30] PO chốt spec + decision log (D2, D3), xác định 7 gap A–G.
- [2026-05-30] Designer handoff chip → Dev code 7 gap (analyze sạch) → Tester verify.
- [2026-05-31] User test runtime pass + duyệt deploy → PO deploy functions (gap B) → **✅ Done** (trừ Gap G hoãn theo analytics).

## Ghi chú phụ thuộc
- Gap G phụ thuộc feature **analytics** (chưa có).
- Phase 3 (D2) cần **Designer** xuất chip chữ trước khi Dev làm.
