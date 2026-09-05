# Onboarding — Test (Tester sở hữu)

## [2026-09-05] [Tester] Vòng 1 code-level (commit e613e70) — ❌ FAIL → [Dev] đã vá cùng ngày → chờ vòng 2 / smoke-test máy thật

Pre-flight: analyze 0 · test 81/81 · ARB JSON hợp lệ, 0 key lệch vi/en.

### PASS (verified)
- Intro gate chỉ chèn trước route `guest`, force-update/authed không bị che; Hive `Box<String>` đúng cả `onboarding_seen_v1` lẫn `feature_tour_seen_build`.
- Mã hiển thị `coupleCode ?? inviteCode` = đúng mã B nhập (khớp `couple_service.joinCoupleByCode`), là sửa đúng banner cũ.
- `inviteShareMessage` + link `dearembeiu.com/get?code={code}`; trang live 200, khớp `docs/get.html`; XSS sạch (textContent), store id đúng.
- Band 1180–1189 không giao band nào (bản đồ đầy đủ ở dev.md).

### FAIL → trạng thái sau khi Dev vá (cùng ngày)
| # | Mức | Bug | Vá |
|---|---|---|---|
| 1 | P0 | Feature tour KHÔNG hiện ở chính bản debut (key `feature_tour_seen_build` mới sinh ở build 20 ⇒ mọi máy nâng cấp bị coi là cài mới) | ✅ `InstallStateService.isFreshInstallLaunch` (main set sau `handleFreshInstall`) — cài mới: ghi im lặng; nâng cấp: `seen=0` ⇒ hiện. `showAll` lọc `sinceBuild <= current`. |
| 2 | P0 | Nhắc "Người ấy chưa vào nè" vẫn nổ SAU khi ghép đôi (signature per-process ⇒ cold start không cancel) | ✅ `refreshInviteFollowUps(waiting:false)` cancel 1 lần/process (`_inviteFollowUpCleared`), reset khi arm lại. |
| 3 | P1 | Landing tự chuyển store sau 1.2s làm ô mã vô dụng, người đã cài bị đá sang store | ✅ có `?code=` hợp lệ → đứng yên (nút store + "Mở app"); chỉ auto-redirect khi link không có mã. Đã publish `phase3`. |
| 4 | P1 | User cũ nâng cấp → đăng xuất → bị xem intro | ✅ route authed → `markSeen()` ngầm. |
| 5 | P2 | Hàng "Gửi quan tâm" trong tour có chevron nhưng bấm không đi đâu | ✅ `FeatureTourEntry.onOpen` (push màn qua host context), chevron chỉ hiện khi có action. |
| 6 | P2 | `_finishIntro` re-entrancy | ✅ cờ `_finishingIntro`. |
| 7 | P2 | Popover share iPad neo toàn màn (`context` của HomeScreen) | ⏳ CHƯA vá (chỉ ảnh hưởng iPad, không crash). |
| 8 | P2 | Sheet tour đệm đáy 2 lần | ✅ bỏ `viewPadding.bottom`, giữ `SafeArea`. |
| 9 | P2 | `mainAxisAlignment.center` vô tác dụng trong scroll view | ✅ `LayoutBuilder` + `ConstrainedBox(minHeight)`. |
| 10 | P2 | Band 1180 không dọn khi sign-out | ✅ gộp với #2 (cancel một lần/process ở mọi couple không-waiting). |

### Chỉ test được máy thật
BUG-2 (2 máy + đổi giờ), permission notification, trần 64 pending iOS, share sheet iPad/Android, `dearembeiu://invite`, intro màn 320dp/font 200%, feature tour ở build 20 thật.

## Vòng 2 — [2026-09-05] [Tester] Xác minh bản vá (commit `fe53eaa`, 1.6.0+20) — ✅ PASS
analyze 0 · test 81/81 · rules-test 241 · ARB parity 0 lệch. 10/10 bug vòng 1 vá đạt (feature tour cài-mới vs nâng-cấp, `seenBuild` promotion, `showAll` lọc build, `_actionFor`, nhắc mời cancel cold start, intro không hiện cho user cũ, `LayoutBuilder` bounded, scope `code` trong get.html, pubspec↔`sinceBuild`).
- BUG mới P2: route `forceUpdate` cũng `markSeen` intro → **[Dev] đã vá cùng ngày** (loại `forceUpdate` khỏi điều kiện).
- Còn [CẦN TEST runtime]: intro máy nhỏ + Reduce Motion; nhắc mời 24h/72h sau khi kill app; get.html trên Safari iOS/Chrome Android thật.
