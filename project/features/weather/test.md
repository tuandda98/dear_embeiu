# 🧪 Test — <Tên feature>

> Tester sở hữu. Đọc cả `overview.md` + `design.md` + `dev.md`. CHỈ test, KHÔNG sửa code. Output: PASS hoặc FAIL (kèm bug report).

- **Trạng thái test:** <chưa test | đang test | PASS | FAIL>
- **Người/role:** Master Tester

## Phạm vi test
<feature/case nào>

## Test case
| # | Loại | Mô tả | Kỳ vọng | Kết quả |
|---|------|-------|---------|---------|
| 1 | happy | <…> | <…> | ⬜ |
| 2 | edge | <…> | <…> | ⬜ |
| 3 | negative | <…> | <…> | ⬜ |
| 4 | đa ngôn ngữ | <…> | <…> | ⬜ |
| 5 | offline / 2 thiết bị couple | <…> | <…> | ⬜ |
| 6 | cold start | <…> | <…> | ⬜ |

*(Kết quả: ✅ pass · ❌ fail · ⬜ chưa chạy)*

## Bug report (nếu FAIL)
### BUG-1: <tiêu đề>
- **Severity:** <critical | major | minor>
- **File/màn hình:** <file:line>
- **Expected:** <…>
- **Actual:** <…>
- **Steps to reproduce:** 1) … 2) … (ghi nhánh Firebase/local nếu liên quan)

## Nhật ký test
- [<YYYY-MM-DD>] [Tester] <đã test gì / kết quả>

## [2026-10-22] [Tester] Nghiệm thu code-level — PASS có điều kiện
`feature/daily-open-2`: analyze 0 · 4 file test weather 81 pass · functions 99 pass · rules-test (Lead) 513 pass. Không có High.
- [Med] Spike D3 (độ chính xác báo mưa VN) chưa làm — AC §9 dòng 1.
- [Med] Privacy policy (`phase3`) chưa nhắc thành phố/MET Norway; chưa khai Coarse Location (ASC) / Vị trí gần đúng (Play).
- [Low] `lib/utils/weather_logic.dart:284` — số của mình cũ/hỏng làm ẩn nút nhắc ở làn người ấy dù số người ấy còn tươi.
- [Low] `weather_provider.dart:261` — người ấy rời lúc app tắt thì thông báo 07:30 đã arm vẫn nổ về người cũ (1 lần).
- [Low] `weather_notice_log` không xoá khi đăng xuất → tài khoản sau bị tính chung trần 3/7.
- [Low] `weather_sheets.dart:805` — `weather_city_set` log trước khi biết ghi thành công.
- [Low] `getCityWeather` không giới hạn theo user / App Check.
- [Low] `weather_card.dart:215` — câu tình trạng chỉ tính lại khi build hoặc 0:00 giờ máy.
- [Low] Copy `weatherCareUmbrellaBody` "sắp mưa" cả khi đang mưa.
- [Low] Hive `weather_cache` nằm trong thư mục được sao lưu.
Cần smoke: chọn giúp realtime 2 máy · 1 lượt MET/thành phố/30' trên log CF · 1160 nổ thật + chạm 3 trạng thái app · máy bay 3 mức cache · app 1.11.0 song song · rời couple xoá doc.
