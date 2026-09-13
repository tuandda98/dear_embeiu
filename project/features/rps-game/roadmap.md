# 🗺️ Roadmap riêng — Oẳn tù tì (rps-game)

> Kế hoạch chi tiết NỘI BỘ feature này. PO sở hữu.

- **Trạng thái feature:** 🎨 Design + 💻 Dev (backend + client nền song song) — 2026-09-13

## Phân phase (Now / Next / Later)

### 🟢 Phase 1 — v1 chơi được 2 máy (P1) — đang làm
- [ ] Backend: rules `games`/`moves` + 2 index + 4 CF (`notifyRpsInvite`, `resolveRpsGame`, `finishRpsGame`, `notifyRpsResult`) + rules-test ≥14 + deploy DEV
- [ ] Client nền: model/service/provider + wire session_resolver + push tap routing + l10n cơ bản + unit test judge
- [ ] Design spec: điểm vào Home/Profile, 4 trạng thái màn chơi, màn lịch sử, copy vi/en
- [ ] Client UI: `RpsGameScreen` + `RpsHistoryScreen` + entry + badge lời mời
- [ ] Tester: rules + logic + smoke 2 máy DEV (test1/test2)
- *Xong khi:* acceptance §7 overview pass; PROD deploy chờ lệnh user; ship trong release kế (1.7.0 MINOR).

### 🟡 Phase 2 — Nice to have
- [ ] Best-of-3 / chuỗi thắng liên tiếp hiển thị ở Profile
- [ ] Âm thanh + rung theo nhịp "1-2-3"
- [ ] Pref tắt push `rps_invite` riêng (map vào `PUSH_TYPE_PREF_FIELD`)

### ⚪ Phase 3 (Later)
- [ ] Trò chơi khác dùng chung khung `games` (đoán số, tung xúc xắc…)

## Mốc đã đạt
- [2026-09-13] Spec PO chốt (overview §3–§7); spawn 3 agent song song.

## Ghi chú phụ thuộc
- Push DEV iOS chưa có APNs key (CLAUDE.md §5) → smoke-test push dùng Android thật hoặc kiểm tra CF log.
- Cần release MINOR mới (client) + deploy PROD rules/indexes/CF trước khi user dùng thật.
