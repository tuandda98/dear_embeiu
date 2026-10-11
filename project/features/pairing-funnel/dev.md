# 💻 Dev — pairing-funnel

> Dev sở hữu. Đọc `overview.md` + `design.md` trước. Implement đúng logic + đúng design. Bám kiến trúc Provider + service (`../../../CLAUDE.md` mục 2).

- **Trạng thái dev:** đang làm (2026-10-11)
- **Người/role:** Dev — 2 agent song song trên 2 worktree, mỗi agent CHỈ ghi vào phần của mình bên dưới.

## Ranh giới file giữa 2 phần (để merge không đụng nhau)
- **Phần A (Apple):** `auth_service.dart`, `auth_provider.dart`, `guest_counter_screen.dart`, `login_screen.dart`, `register_screen.dart`, `settings_screen.dart`, `widgets/apple_sign_in_button.dart` (mới), `theme/app_colors.dart`, `app/app_urls.dart` (chỉ hằng `privacyPolicy`), `ios/Runner/Runner.entitlements`, ARB (chèn sau `authFirebaseAuthGeneric` + sửa `guestCtaSignIn`).
- **Phần B (QR + bộ nhớ tạm + lời nhắc):** `invite_action_buttons.dart`, `widgets/invite_qr_sheet.dart` (mới), `services/invite_clipboard.dart` (mới), `home_screen.dart`, `setup_screen.dart`, `profile_screen.dart`, `reminder_provider.dart`, `reminder_service.dart`, `app/app_urls.dart` (chỉ thêm hằng link mời ở CUỐI class), `ios/Runner/AppDelegate.swift`, `docs/get.html`, `pubspec.yaml`/`pubspec.lock`, ARB (chèn sau `inviteFollowUpBody72h` + sửa `homeWaitingStep1Desc`, metadata `inviteFollowUpBody24h`).

---

## Phần A — Đăng nhập với Apple (PF1–PF6, PF11)

- *Trạng thái:* chưa bắt đầu

<!-- Dev A ghi kế hoạch, edge case, checklist, nhật ký vào giữa 2 dòng đánh dấu này -->
<!-- /Phần A -->

---

## Phần B — Ghép đôi tại chỗ + lời nhắc mời (PF7–PF10, PF12–PF13)

- *Trạng thái:* đã implement xong, sẵn sàng test (2026-10-11) — chưa merge, chưa đẩy `docs/get.html` lên `phase3`

<!-- Dev B ghi kế hoạch, edge case, checklist, nhật ký vào giữa 2 dòng đánh dấu này -->

### Đã làm (file → việc)

| File | Việc |
|---|---|
| `pubspec.yaml` / `.lock` | `qr_flutter: ^4.1.0` (bản 4.x mới nhất, kéo theo `qr 3.0.2`). |
| `lib/app/app_urls.dart` | Cuối class: `inviteBase = 'https://dearembeiu.com/get'` + `inviteLink(code)` (in hoa mã). Không đụng `privacyPolicy`. |
| `lib/widgets/invite_qr_sheet.dart` (mới) | `InviteQrSheet.show(context, code:)`: log `invite_shared('qr')` + `markInviteShared()` rồi mở sheet. QR 220 trong `ContentCard` rộng 260, ECC M, gapless, module + mắt `textPrimary`, nền trắng, `padding: zero` (vùng trắng = padding 20 của thẻ). Semantics `image` + `inviteQrSemantics(code)`. Kèm `InviteSheetFrame` = khung sheet chuẩn (trắng, r28, handle 40×4, cuộn trong 90% màn) dùng chung cho sheet gợi ý ở Setup. |
| `lib/widgets/invite_action_buttons.dart` | Row → `Wrap(8, 8)`. Pill dựng lại bằng `TextButton.icon` (iconOnly: `IconButton(tooltip:)`), `minimumSize` cao 36, `tapTargetSize: padded` → vùng chạm 48. Biến thể sáng: chữ `textPrimary` w700, icon rose, nền rose .12, ripple rose .08. Thêm pill "Mã QR" (`IconsaxPlusLinear.scan_barcode`). Copy/Share gọi thêm `markInviteShared()`. |
| `lib/screens/home_screen.dart` | Thẻ chờ: `Align(Sao chép mã)` → `Wrap` 2 pill tonal [Sao chép mã][Mã QR] qua `_buildWaitingPill` (stadium, cao 36/chạm 48, chữ navy 13 w700). Khoảng cách nút "Gửi cho người ấy" → hàng pill 8 → 2. `_shareInviteCode`/`_copyInviteCode` gọi `markInviteShared()`. Comment call site `refreshInviteFollowUps` theo lịch mới. |
| `lib/screens/setup_screen.dart` | `WidgetsBindingObserver`. `_checkClipboardInvite()` chạy sau frame đầu + 500ms; iOS chạy lại mỗi lần `resumed` (PF12), Android chỉ lúc mở màn. Điều kiện: đã đăng nhập, `!user.hasCouple` (tức không phải chế độ sửa), không đang loading, Setup là route trên cùng, mã khác `inviteCode`/`coupleCode` của mình. Đánh dấu "đã hỏi" TRƯỚC khi hiện sheet. Sheet `_ClipboardInviteSheet` (W9, nút chính navy). "Ghép đôi ngay" → điền mã + tab Tham gia + chờ 300ms + `_submitJoin()`; "Bỏ qua"/vuốt → vẫn điền mã, không đổi tab. `_submitJoin` tách mã khi người dùng dán cả link (và hiện lại mã trong ô). Khoảng cách quanh cụm nút: mã → cụm 10 → 4, cụm → mô tả 8 → 2. |
| `lib/screens/profile_screen.dart` | `_buildDetailTile`: value → cụm nút 10 → 4 (belowValue chỉ dùng cho cụm mời). |
| `lib/services/invite_clipboard.dart` (mới) | `parseInviteCode(text)` thuần (regex dựng từ `AppUrls.inviteBase`: host không phân biệt hoa thường, có/không `https://`/`www.`, không dính domain khác, `code` ở vị trí bất kỳ trong query, đúng 6 ký tự chữ-số) → mã IN HOA. `peekInviteCode()`: iOS kênh `dear_embeiu/clipboard` `probe` → không có URL thì thôi; `changeCount` trùng lần đọc trước (Hive) thì thôi; lưu `changeCount` rồi mới `Clipboard.getData`. Android: `hasStrings` → đọc. Mã đã hỏi → null. Mọi lỗi → null. Không log nội dung. `markAsked(code)`. |
| `lib/services/reminder_service.dart` | `enum InviteFollowUp { after2h(1180, 2h), after20h(1181, 20h), after72h(1182, 72h) }`. `@visibleForTesting static inviteFollowUpSlots({anchor, now, shared})` thuần. `scheduleInviteFollowUps({anchor, shared, copy})` (huỷ cả band rồi lập theo slot). `cancelInviteFollowUp(kind)`. BỎ cơ chế "đã qua hết thì nhắc now + 24h". |
| `lib/providers/reminder_provider.dart` | `markInviteShared()`: ghi `invite_shared_at` (epoch ms) vào Hive `app_settings` + huỷ id 1180. `_inviteSharedFor(anchor)` = `lastShared >= anchor − 1h`. `refreshInviteFollowUps` truyền copy theo mốc (2h: `inviteFollowUpTitle2h`/`Body2h`; 20h: `inviteFollowUpTitle`/`Body24h`; 72h: `inviteFollowUpTitle`/`Body72h`); chữ ký debounce thêm `shared`. |
| `ios/Runner/AppDelegate.swift` | `InviteClipboardChannel` đăng ký trong khối `registrar(forPlugin: "AppChannels")`. `UIPasteboard.general.detectPatterns(for: [\.probableWebURL])` (bản key-path iOS 15, bản `DetectionPattern` đã deprecated từ iOS 15), trả `{hasUrl, changeCount}` về main queue. |
| `docs/get.html` | CSS giữ nguyên. `COPY` vi/en theo bảng design (`msgWithCode`, `subNote` đổi; thêm `copyHint`/`copyHintDone`/`copyHintFail`/`subNoteAuto`). Nhận diện nền tảng đưa ra ngoài `routeByPlatform`. Có mã hợp lệ: bấm `#iosBtn`/`#androidBtn`/`#openApp` → chép `https://dearembeiu.com/get?code=<MÃ>` ngay trong click (`writeText` không await, lỗi thì `legacyCopy`), không `preventDefault`. Điện thoại có mã: ẩn nút store sai nền tảng, `#redirectNote` hiện `copyHint` → `copyHintDone`/`copyHintFail`, `#subNote` = `subNoteAuto`. Không mã: luồng tự chuyển store 1,2 giây như cũ. |
| `lib/l10n/app_en.arb` + `app_vi.arb` | 12 key mới ngay sau `inviteFollowUpBody72h` (`@inviteQrSemantics` có placeholder `code` String ở cả 2 file); đổi `homeWaitingStep1Desc`; en thêm `@inviteFollowUpBody24h` (mốc 20 giờ) + description cho `inviteQrBtn`/`clipboardInviteTitle`/`inviteFollowUpTitle2h`. `flutter gen-l10n` đã chạy. |
| `test/invite_clipboard_test.dart`, `test/invite_follow_up_slots_test.dart` (mới) | 7 + 7 test. |

Model/Firestore/Function/rules: **không đổi**. Không deploy gì. Native: chỉ iOS (kênh mới); Android không đổi.

### Edge case đã xử lý
- **Lịch nhắc:** mốc đêm dời TRƯỚC rồi mới lọc theo `now` ⇒ mở app lúc 23:30 khi mốc 2h (23:00) vừa qua thì nó vẫn nổ 08:30 sáng mai, không bị bỏ. Couple tạo ≥ 3 ngày (cụ thể: mọi mốc đã qua) ⇒ không lập gì, kể cả khi mở app. Bản cũ để lại id 1180 "now + 24h" ⇒ lần refresh đầu sau khi cập nhật huỷ cả band 1180–1189 rồi lập lại.
- **"Đã gửi":** sao chép mã cá nhân ở Setup trong vòng 1 giờ trước khi tạo couple vẫn tính. Lần chia sẻ cho couple cũ (trước khi rời và tạo lại) không tính.
- **Bộ nhớ tạm iOS:** không URL ⇒ không đọc ⇒ không có hộp "Cho phép dán". Một nội dung chỉ đọc một lần (`changeCount`), kể cả khi nó không phải link mời hay người dùng bấm "Không cho phép". Hộp hệ thống làm app `inactive → resumed` ⇒ cờ `_clipboardCheckBusy` chặn kiểm chồng.
- Sheet gợi ý không hiện khi đang có dialog/route khác đè lên Setup, khi đang ghép đôi, hoặc với mã của chính mình.
- Pill Wrap xuống dòng thay vì tràn ở tile Profile (cột 253pt). Sheet QR cuộn được khi chữ to.

### Checklist
- [x] `flutter analyze` → **No issues found!**
- [x] `flutter test` → **235/235 pass** (221 cũ + 14 mới)
- [x] `xcrun swiftc -parse ios/Runner/AppDelegate.swift` → OK. Thêm: type-check riêng `InviteClipboardChannel` với `Flutter.xcframework` + SDK iOS 15 → sạch, không warning.
- [x] `docs/get.html`: `node --check` OK + chạy script trong DOM giả 6 kịch bản (iPhone/Android/desktop/iPad có mã, iPhone không mã, mã 7 ký tự) → đúng spec.
- [x] Smoke test bố cục tạm (đã xoá, không commit): 3 pill trong cột 253pt mỗi nút cao 48, hình 36, không tràn; sheet QR ở cỡ chữ ×2 trên máy 375×667 không tràn, cuộn tới "Xong" được.
- [ ] Chạy thật trên máy: quét QR bằng Camera iPhone, hộp "Cho phép dán", luồng đã-cài-sẵn (PF12), toast Android.

### Khác spec / cần biết
- **Khoảng icon → chữ trong pill = 8** (khoảng cố định của `TextButton.icon`), design ghi 6 (thẻ chờ) và cụm cũ là 4. Rộng thêm 2–4pt mỗi pill; cụm 3 pill vẫn vừa 1 hàng ở Setup máy 375.
- **Ripple:** dùng `copyWith(overlayColor:)` để ra đúng rose .08 / trắng .12 (styleFrom chỉ cho .10).
- **Hợp đồng analytics:** `invite_shared` nay có thêm `method = qr` (theo design 4a). `project/features/analytics/overview.md` (file PO) vẫn ghi `copy | share_sheet` — PO cần bổ sung.
- **Hive:** `markInviteShared` / bộ nhớ tạm chỉ đọc-ghi khi box `app_settings` đã mở (main() luôn mở trước `runApp`); không gọi `openBox` dự phòng vì Hive ném lỗi bất đồng bộ ngoài try/catch khi mở thất bại.
- Mốc `anchor + 7 ngày` hiện không bao giờ chặn mốc nào (mốc xa nhất là +72h dời đêm); giữ làm chốt chặn theo PF10 cho ai thêm mốc sau này.
- **Chưa làm (việc của Lead):** đẩy `docs/get.html` lên nhánh `phase3`. Trước khi đẩy, app bản cũ (không đọc bộ nhớ tạm) vẫn chạy bình thường: trang chỉ chép thêm link.
- **Merge với Phần A:** 2 bên cùng sinh lại `lib/l10n/app_localizations*.dart` ⇒ sau khi gộp ARB, chạy lại `flutter gen-l10n` thay vì gộp tay file sinh.

### Nhật ký
- [2026-10-11] [Dev B] Worktree bị tạo từ `main`@1c982ea thay vì `00ce671` → reset nhánh worktree về `00ce671` (cây sạch, chưa có commit riêng) rồi mới làm.
- [2026-10-11] [Dev B] Implement Phần B: QR (PF7) + pill dựng lại vùng chạm 48, gợi ý mã từ bộ nhớ tạm ở Setup (PF9/PF12/PF13) + kênh iOS `dear_embeiu/clipboard`, trang get chép link mời (PF8/PF12), lịch nhắc mời +2h/+20h/+72h dời đêm 08:30, bỏ nhắc lặp (PF10). analyze 0, test 235/235.
<!-- /Phần B -->

---

## Nhật ký chung (Lead ghi khi merge)
- [2026-10-11] [Lead] Chia 2 phần A/B, chạy song song trên worktree riêng.
