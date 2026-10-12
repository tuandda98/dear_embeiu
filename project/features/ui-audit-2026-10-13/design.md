# Design — UI audit 2026-10-13

## Soát UX (UI UX Pro Max)

Query đã tra (`search.py`):
- `--domain ux "edge-to-edge safe area scroll content inset"` -> không có rule mobile riêng; áp nguyên tắc nền tảng (content cuộn dưới status bar/home indicator, inset vào padding). Đối chiếu pattern có sẵn `notification_center_screen.dart:40,145` (SafeArea(bottom:false) + `padding.bottom + 28`) và `settings_screen.dart:179-182` (đã sửa).
- `--domain ux "duplicate label form field accessibility"` -> "Form Labels" (High): mỗi input một nhãn gắn kèm; không lặp tiêu đề + nhãn cùng chữ. Áp: bỏ tiêu đề thừa, giữ nhãn gắn field.
- `--domain ux "touch target contrast small text"` -> "Touch Target Size" iOS 44pt / Android 48dp; "Contrast Readability" (chữ xám trên nền sáng cần ≥4.5:1). Áp: textTertiary #A0A0B0 trên trắng ~2.5:1 -> không dùng cho chữ; textSecondary #6B6B7B ~5.2:1.
- `--domain typography "type scale"` -> thang cố định, không cỡ lẻ. Áp: type scale design-system (10 11 12 13 14 15 16 18 20 21 22 26 30/32 40 56 76).
- `--stack flutter "safe area scroll"` -> không rule trực tiếp; dùng quy ước đã nêu.

Quy ước sửa edge-to-edge (áp F3–F16):
- **A. Header là item đầu vùng cuộn** (ListView/SingleChildScrollView/CustomScrollView): bỏ `SafeArea` bọc scroll; padding scroll = `EdgeInsets.fromLTRB(16, 16 + MediaQuery.paddingOf(context).top, 16, 24 + MediaQuery.paddingOf(context).bottom)`. Màn có `bottomNavigationBar` riêng: body đã bị Scaffold trừ inset đáy, chỉ cần top.
- **B. Header PINNED + `Expanded(scroll)`**: `SafeArea(bottom: false)` (chỉ bảo vệ header), padding đáy của list cộng `MediaQuery.paddingOf(context).bottom`. Mẫu: `notification_center_screen.dart`.
- **C. Form auth (Center + SingleChildScrollView trên gradient)**: bỏ SafeArea, padding scroll `fromLTRB(20, 20 + top, 20, 20 + bottom)`; chỗ có `Positioned` top-bar (back/language) bọc riêng `SafeArea(bottom:false)` hoặc `top: 8 + top`.
- Không đổi: `home_screen.dart:1236` (SafeArea(bottom:false) quanh 4 tab pinned-header), `profile_screen.dart:89`, `notification_center_screen.dart:40`, `create_post_screen.dart:164` (có thanh đáy cố định), `intro_screen.dart:101`, `force_update_screen.dart:48` (nội dung căn giữa, không cuộn dài), mọi bottom sheet (`gallery_screen.dart:554,686`).

## Findings

### Nhãn / tiêu đề trùng lặp
- **F1 · Register · register_screen.dart:278-286 · P1** · Tiêu đề "Tên hiển thị" (16 w800) rồi `_buildFieldBlock(label: displayNameLabel)` ngay dưới = trùng chữ y hệt lỗi login. Fix: xoá `Text(l10n.displayNameLabel…)` + `SizedBox(height: 18)` liền sau; để nhãn của field block dẫn đầu thẻ. Sau khi xoá, đảm bảo khoảng cách trên thẻ vẫn 20 (padding GlassCard).
- **F2 · Forgot password · forgot_password_screen.dart:262-269 · P1** · Heading `forgotPasswordEmailHeading` = "Email" (arb vi:1154) + nhãn `emailLabel` = "Email" ngay dưới. Fix: xoá `Text(l10n.forgotPasswordEmailHeading…)` + `SizedBox(18)`. Key ARB mồ côi sau đó: Dev gỡ khỏi `app_en.arb` + `app_vi.arb` rồi gen-l10n.
- **F3 · Setup (create) · setup_screen.dart:714-716 · P3** · Mode create hiện title 32 + subtitle ngay dưới chip, trong khi mode edit dùng `SubScreenHeader` mà title/subtitle (param đã deprecated, không render) lại vẫn được truyền ở `:655-659`. Fix: xoá `title:`/`subtitle:` truyền vào `SubScreenHeader` ở setup_screen:658-659, settings_screen (`~:188-190`), counter_bg:187-191, chat_bg:261-264, custom_reminders, milestone_reminders:48-51, reminders:38-41, notification_center, custom_reminder_form:253-256 để khỏi tưởng có hiển thị. Không đổi giao diện.

### Edge-to-edge (SafeArea cắt phẳng) — Pattern A (header trong vùng cuộn)
- **F4 · Journal · journal_screen.dart:68 · P2** · `SafeArea` bọc `Consumer`; danh sách `:214-216` và `:506-508` padding `(20,16,20,32)`, header cố định `:103`. Fix: bỏ SafeArea; hai ListView -> `fromLTRB(16, 16 + top, 16, 32 + bottom)`; `_withFixedHeader` `:103` -> `fromLTRB(16, 16 + top, 16, 0)` (và bọc phần Expanded child bottom bằng `bottom` inset nếu căn giữa).
- **F5 · Sleep · sleep_screen.dart:103-106 · P2** · SafeArea + SingleChildScrollView `(16,16,16,24)`. Fix: bỏ SafeArea; padding `fromLTRB(16, 16 + top, 16, 24 + bottom)`. Màn nền trời đêm tối nên cắt phẳng càng lộ.
- **F6 · Lunar calendar · lunar_calendar_screen.dart:50-53 · P2** · Như F5. Cùng fix.
- **F7 · Milestone reminders · milestone_reminders_screen.dart:42-44 · P2** · SafeArea + ListView `(16,16,16,24)`. Fix: bỏ SafeArea, `(16, 16 + top, 16, 24 + bottom)`.
- **F8 · Reminders hub · reminders_screen.dart:34-36 · P2** · SafeArea + ListView `(16,16,16,32)`. Fix: `(16, 16 + top, 16, 32 + bottom)`.
- **F9 · Custom reminder form · custom_reminder_form_screen.dart:246-248 · P2** · SafeArea + SingleChildScrollView `(16,16,16,32)`; form dài, cuộn khi bàn phím mở bị cắt sát status bar. Fix: bỏ SafeArea, `(16, 16 + top, 16, 32 + bottom)`.
- **F10 · Counter background · counter_bg_screen.dart:178-184,202 · P2** · SafeArea trong body có `bottomNavigationBar` (đã tự SafeArea `:235`). Lưới ảnh bị cắt ở status bar. Fix: bỏ SafeArea quanh CustomScrollView; header sliver padding `(16, 16 + top, 16, 4)` (đổi 20 -> 16, xem F17); không cộng inset đáy (Scaffold đã trừ).
- **F11 · Chat background · chat_bg_screen.dart:252-258,269 · P2** · Như F10. Cùng fix cho sliver `:258` và `:269`.

### Edge-to-edge — Pattern B (header pinned + list)
- **F12 · Care timeline · care_timeline_screen.dart:222; list `:283`,`:530` · P2** · SafeArea cắt cả list ở đáy (danh sách phân trang, cuộn dưới home indicator được). Fix: `SafeArea(bottom: false)`; list padding bottom `32` -> `32 + MediaQuery.paddingOf(context).bottom`.
- **F13 · RPS history · rps_history_screen.dart:90; list `:145`,`:574` · P2** · Cùng fix F12.
- **F14 · Care message · care_message_screen.dart:147; list `:161-166` · P2** · SafeArea + padding đáy `24 + MediaQuery.of(context).viewInsets.bottom` (context nằm TRÊN Scaffold nên thấy full keyboard inset trong khi `resizeToAvoidBottomInset: true` đã co body) -> khoảng trống gấp đôi chiều cao bàn phím khi gõ. Fix: `SafeArea(bottom:false)`; padding đáy `24 + MediaQuery.paddingOf(context).bottom`, BỎ `viewInsets.bottom`.
- **F15 · Custom reminders list · custom_reminders_screen.dart:77; list `:111`,`:480` · P2** · Cùng fix F12; `:480` đáy `96` (chừa FAB) -> `96 + paddingOf(context).bottom`.
- **F16 · RPS game · rps_game_screen.dart:730 · P3** · SafeArea bọc Stack có header pinned; Dev kiểm vùng cuộn bên trong, áp Pattern B nếu có scroll.

### Edge-to-edge — Pattern C (auth/onboarding)
- **F17 · Login/Register/Forgot/Setup/Guest/Verify · login_screen.dart:96 · register_screen.dart:125 · forgot_password_screen.dart:126 · setup_screen.dart:580 · guest_counter_screen.dart:184 · verify_email_screen.dart:210 · P3** · Form cuộn bị cắt phẳng ở status bar khi bàn phím mở / máy nhỏ. Fix theo Pattern C. Riêng login/register/forgot có `Positioned` back + language toggle, giữ chúng trong `SafeArea(bottom:false)` riêng.

### Lệch gutter
- **F18 · 8 màn con · P2** · Gutter 16 là chuẩn, nhưng header+list dùng 20: care_timeline:227,283,530 · rps_history:95,145,574 · care_message:152,162-164 · counter_bg:184 · chat_bg:258,269 · journal:103,216,508 · custom_reminders list:111 (header cùng màn lại 16 ở `:82`, và list kia `:480` 16) · rps_game:~735. Mũi tên back/chip nhảy 4px khi chuyển màn. Fix: tất cả `20` ngang -> `16`.
- **F19 · Notification center · notification_center_screen.dart:162,187 · P3** · Row trong tile padding trái `22`, phải `16`, tile `(16,5,16,5)`; không cùng gutter 16 với header `:93`. Fix: section label `(16,14,16,8)`.

### Cỡ chữ ngoài type scale
- **F20 · care_timeline_screen.dart:452 (12.5), 462 (11.5), 480 (13.5) · P2** · Fix: 12.5 -> 12, 11.5 -> 12 (giờ phút, w500), 13.5 -> 14.
- **F21 · care_message_screen.dart:355,482 (13.5), 470,491 (11.5) · P2** · Fix: 13.5 -> 14; 11.5 -> 12.
- **F22 · chat_bg_screen.dart:572 (12.5), 644 (17), 654 (13.5) · P2** · Fix: 12.5 -> 12; 17 -> 16 (w700 tiêu đề trạng thái trống; hoặc 18 nếu muốn nhấn); 13.5 -> 14.
- **F23 · gallery_screen.dart:740 (12.5), 892 (15.5) · P3** · Fix: 12.5 -> 12; 15.5 -> 16.
- **F24 · home_screen.dart:2196 (24), 2316/2389 (12.5 ở 2389) · P2** · Mã mời ở thẻ chờ: 24 w900 ls4. Fix: 26 (headline) cho cùng họ với code 30 ở Setup; `:2389` 12.5 -> 12.
- **F25 · profile_screen.dart:961 (13.5) · settings_screen.dart:1959 (11.5) · P3** · 13.5 -> 14; 11.5 -> 12.
- **F26 · records_sheet.dart:193 · couple_info_card.dart:104 · app_time_picker.dart:182 · P3** · 17 -> 16 (w700/w800 giữ). Không đụng emoji 17 ở `answer_reaction_row.dart:237,284` (nội dung emoji, cho phép).

### Contrast
- **F27 · Lunar calendar · lunar_calendar_screen.dart:236-247 · P1** · Nhãn ngày âm 9pt `textTertiary` (#A0A0B0 trên trắng ~2.5:1) trong ô nhỏ; vừa nhỏ vừa nhạt, người dùng nhìn không ra. Fix: cỡ 10, màu `textSecondary` (#6B6B7B, ~5.2:1); ngày nhắc giữ `accentLoveDeep` w800. Kiểm ô vẫn đủ rộng khi chữ 10 ("mùng 10" / "1/1").
- **F28 · Chữ phụ textTertiary cỡ 11-12 · P2** · #A0A0B0 làm CHỮ trên nền trắng/blush: rps_history_screen.dart:440,529 · care_timeline:462 · milestone_reminders:220,230 · custom_reminders:652,663 · custom_reminder_form:472 · rps_game:1740 · lunar_calendar:183 · home_screen:2316,2389 · mood_card:249,312 · answer_reaction_row:255 · catchup_gate:259 · couple_info_card:89 · care_message:470. Fix: chuyển các chữ này sang `AppColors.textSecondary`. `textTertiary` chỉ còn cho icon trang trí, đường kẻ, placeholder disabled.
- **F29 · Profile hero · profile_screen.dart:336-343 · P2** · Nhãn `ourStoryBadge` 10pt trắng alpha .72 nằm trên ảnh/gradient hồng nhạt -> dưới 3:1 với ảnh sáng. Fix: alpha .72 -> .92 + `shadows: [Shadow(color: black .32, blurRadius: 8)]` (chuẩn chữ trắng trên ảnh trong design-system), hoặc nâng scrim đáy hero.
- **F30 · Gallery preview · gallery_screen.dart:2853,2863,2914 · P3** · Chữ trắng alpha .72-.82 cỡ 12 trên ảnh toàn màn. Kiểm có scrim đáy; nếu không, thêm gradient đen .45 -> 0 phía dưới panel info hoặc bóng chữ như F29.

### Touch target
- **F31 · Login · login_screen.dart:307-325 · P2** · Link "Quên mật khẩu" 13pt, padding 0, `shrinkWrap` + `minimumSize: Size.zero` -> vùng chạm ~18px cao, dễ bấm trượt. Fix: `minimumSize: const Size(44, 44)`, `tapTargetSize: padded`, bỏ `shrinkWrap`; giữ chữ 13.
- **F32 · Setup · setup_screen.dart:~706-728 · P2** · Pill Đăng xuất: padding dọc 8 + icon 13 + chữ 12 -> cao ~32. Fix: padding dọc 12 (cao 44), chữ 13 w600 (đủ ≥12, đồng bộ `EyebrowChip`).
- **F33 · Register · register_screen.dart:455-466 · P3** · Checkbox `shrinkWrap` + `compact` = vùng ~32. Fix: bọc cả hàng checkbox + chữ trong `InkWell` min height 44 (nếu chữ đã bấm được thì chỉ cần `materialTapTargetSize: padded`).
- **F34 · Gallery composer · gallery_screen.dart:1280-1330 · P3** · Hai nút "Chụp hình"/"Thêm hình" 13pt, padding dọc 11 -> cao ~40 và ngoài quy tắc nút (15 w600). Fix: padding dọc 14 (cao ≥ 44), chữ 14 w700 theo "action section" của design-system.

### Chuyển động / icon
- **F35 · streak_chip.dart:92-103 · P2** · Emoji 🌸/✨ làm icon + fade lặp vô tận, KHÔNG check Reduce Motion (WCAG 2.3.3, luật 2026-06-10). Fix: bọc `AppMotion.reduceMotion(context)` -> hiện tĩnh opacity 1; thay emoji bằng `IconsaxPlusBold.star_1` / `IconsaxPlusBold.heart` (accentLove) cỡ 14 để cùng bộ icon.
- **F36 · compose_pill.dart:80-90 · P3** · Pulse scale 1.018 lặp vô tận không check Reduce Motion. Fix: `if (!emphasized && !AppMotion.reduceMotion(context))`.

## Thứ tự Dev nên làm
1. F1, F2 (trùng nhãn, 2 chỗ, xoá vài dòng) cùng F27 (contrast lịch âm).
2. F14 (khoảng trống gấp đôi bàn phím — lỗi nhìn thấy rõ nhất) rồi F12, F13, F15, F18 (làm chung một lượt vì cùng file pinned-header).
3. F4–F11 (Pattern A) rồi F17 (Pattern C), F16.
4. F28, F29, F30 (contrast chữ).
5. F20–F26 (sweep cỡ chữ lẻ; làm bằng grep `fontSize: [0-9]+\.[0-9]` và các 17/24).
6. F31–F34 (touch target), F35, F36.
7. F3, F19 (dọn tham số chết, không đổi giao diện).
8. Sau khi sửa: `flutter analyze`, mở 6 màn Pattern A trên iPhone có notch + máy Android có gesture bar, cuộn đến cuối.

Không báo (đã đúng): hex cứng chỉ ở sleep/love tree (có chủ đích), profile palette, chat bubble grey; icon dùng Iconsax; Reduce Motion đã có ở aurora/cinema/marquee/entrance/couple name.

## Acceptance criteria
- Không còn màn nào có nhãn/tiêu đề trùng chữ liền kề.
- Cuộn mọi màn trượt sát mép trên/dưới màn hình, nội dung dừng đúng trên home indicator.
- `grep -rE "fontSize: *[0-9]+\.[0-9]+"` trong `lib/screens` + `lib/widgets` (trừ `sleep/`, `today_constellation`) = 0; không còn 9/17/24.
- Chữ nền sáng ≥4.5:1 (không còn textTertiary làm chữ).
- Mọi nút/link bấm được ≥44x44.
