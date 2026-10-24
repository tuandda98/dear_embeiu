# Maestro cho Sổ tiền (expenses, mốc A)

Soạn 2026-10-23, **chưa chạy lần nào** (lúc soạn 2 máy ảo đang được dùng việc khác). Lần chạy đầu cứ sửa selector theo thực tế rồi ghi vào `project/features/expenses/test.md`.

## Máy và tài khoản (DEV, appId `com.tony.dearembeiu.dev`, app tiếng Việt)

| Máy | Id | Tài khoản |
|---|---|---|
| Android emulator | `emulator-5554` | `test3@gmail.com` (Tuấn, đã có ví Cash và vài khoản chi) |
| iOS simulator | `23B763A6-DF45-4E75-9112-F9636CCB983B` | `test4@gmail.com` (Thảo, sổ riêng còn trống) |

Hai tài khoản đã ghép đôi. Reset dữ liệu mẫu: `node scripts/dev-seed-widget-accounts.js`.

## Lệnh chạy

```
export PATH="$PATH:$HOME/Library/Android/sdk/platform-tools"
maestro --device emulator-5554 test maestro/expenses/03_expense_own_android.yaml
maestro --device 23B763A6-DF45-4E75-9112-F9636CCB983B test maestro/expenses/30_own_expense_ios.yaml
```

Flow KHÔNG `clearState`, bắt đầu bằng `launchApp` (khởi động lại app, đứng ở Home). Chạy lại bao nhiêu lần cũng được: mỗi lần dùng ghi chú có mã `RUN` riêng (`MTO<mã>`, `MTS<mã>`...) để tìm đúng khoản vừa tạo. Không truyền `-e RUN=...` thì flow tự sinh mã từ giờ máy.

## Flow độc lập, 1 máy (thứ tự tuỳ ý)

| File | Case (xem `project/features/expenses/test-cases.md`) |
|---|---|
| `01_open_menu_android` | từ Home vào Sổ tiền, 2 tab, đổi tháng, menu 5 mục |
| `02_amount_keypad_android` | bàn phím k/triệu/củ/000/dấu phẩy, gợi ý "Bạn gõ", quá 10 tỷ, bỏ khoản đang ghi |
| `03_expense_own_android` | chi 50k sổ Của mình |
| `04_edit_delete_own_android` | sửa số tiền, xoá + Hoàn tác, xoá thật |
| `06_quick_repeat_android` | "Ghi lại khoản quen" 2 chạm |
| `07_wallet_create_android` | tạo ví MTW (chỉ khi chưa có), sửa số dư |
| `09_budget_android` | đặt ngân sách cả sổ |
| `10_report_android` | báo cáo tháng, 6/12 tháng |
| `11_search_android` | tìm khoản, không phân biệt hoa thường, trống |
| `12_categories_android` | thêm rồi xoá danh mục tự thêm |
| `13_language_switch_android` | vi -> en -> vi: tên ví mặc định + danh mục dịch lại (commit b7e0e88) |
| `30_own_expense_ios` | iOS: first-run (nếu có) + chi 50k sổ riêng |

## Cặp 2 máy: chạy ĐÚNG thứ tự, cùng một mã

> 2026-10-25 (D34): đã gỡ flow thu (05), chuyển (08), thanh toán (22, 23), trả hộ (31, 32); 20/21 sửa theo mô hình mới nhưng CHƯA chạy lại cả bộ 2 máy.

```
RUN=$(date +%H%M%S)
A="maestro --device emulator-5554 test -e RUN=$RUN"
I="maestro --device 23B763A6-DF45-4E75-9112-F9636CCB983B test -e RUN=$RUN"
$A maestro/expenses/03_expense_own_android.yaml        # 1. Tuấn ghi 1 khoản RIÊNG (để bước 6 kiểm riêng tư)
$A maestro/expenses/20_shared_add_android.yaml         # 2. Tuấn chi 1 củ bằng tiền riêng
$I maestro/expenses/21_shared_see_ios.yaml             # 3. Thảo thấy khoản
$I maestro/expenses/24_privacy_ios.yaml                # 6. sổ riêng của Tuấn không lộ sang Thảo
$A maestro/expenses/25_shared_offline_android.yaml     # 7. Tuấn mất mạng ghi 20k, có mạng lại
$I maestro/expenses/26_shared_offline_seen_ios.yaml    # 8. Thảo thấy khoản đó
```

Chạy xong 22 và 32 cân bằng về 0, nên chạy lại cả chuỗi không để dư nợ.

## Lưu ý khi chạy

- Selector Maestro là regex, khớp **nguyên chuỗi**, **không phân biệt hoa thường**, `.*` ăn cả xuống dòng. Chuỗi có dấu chấm tiền (`50\.000`) phải escape; dấu nháy cong “ ” viết thành `.`.
- Số tiền trên nút Lưu có NBSP trước "₫", nên regex để `.*` phía sau.
- iOS simulator vẽ emoji thành "?": flow không assert emoji.
- Bàn phím số của form ghi khoản là phím tự vẽ, nhãn: `0-9`, `000`, `,`, `nghìn`, `triệu`, `củ`, `Xoá một ký tự`.
- `25_shared_offline_android` dùng `setAirplaneMode` (Android). Nếu emulator vẫn còn mạng, tắt Wi-Fi bằng tay rồi bỏ 2 dòng `setAirplaneMode`.
- `13_language_switch_android` có `onFlowComplete` trả về Tiếng Việt; flow chết giữa chừng thì app vẫn được đưa về Tiếng Việt.
- `06_quick_repeat_android`: chip "Ghi lại khoản quen" chỉ lấy 3 danh mục chi dùng nhiều nhất; nếu danh mục mặc định của khoản mới lọt ngoài top 3 thì chip không hiện và flow fail. Đó là kỳ vọng sai của flow, không phải lỗi app.
- Bước nào trong `01..13` nằm ngoài những gì máy ảo làm được (đổi múi giờ, chuyển ngày, cắt mạng iOS, push thật) thì ghi `thủ công` trong `test-cases.md`.
