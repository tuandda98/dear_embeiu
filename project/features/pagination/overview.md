# Pagination — phân trang 3 danh sách dài (gallery / journal / love-note history)

> File PO sở hữu.

- **Feature:** pagination
- **Ưu tiên:** P1 (perf + chi phí Firestore — couple lâu năm có nghìn ảnh)
- **Trạng thái:** 🧪 Test PASS-có-điều-kiện code-level (đợt 1 FAIL 3 major → Dev-fix → đợt 2 PASS) — chờ smoke-test 2 thiết bị (8 mục trong test.md)
- **Tạo ngày:** 2026-06-11
- **Liên quan:** [dev.md](dev.md) · [test.md](test.md) · features gốc: gallery / couple-journal / love-note-history

## 1. Vấn đề & giá trị
- Gallery watch FULL collection không limit (`photo_service.dart` ~49) → mở app tải mọi doc ảnh, tốn read + chậm + tốn RAM khi couple tích ảnh lâu năm.
- Love-note history stream `limit 200` cứng — note 201 trở đi biến mất vĩnh viễn, không load thêm được.
- Journal ĐÃ chuẩn (pageSize 30 + cursor + Xem thêm) — làm mẫu pattern.

## 2. Quyết định đã chốt (PO/Lead, 2026-06-11)
- **D1 — Gallery = window realtime + trang cũ tĩnh:** watch realtime CHỈ 30 ảnh mới nhất (limit 30); cuộn gần cuối → `loadMore` fetch `get()` 30 ảnh cũ hơn (cursor `startAfter` uploadDate); merge bằng MAP tích lũy theo id (ảnh rớt khỏi window không biến mất).
- **D2 — Đếm tổng ảnh = aggregate `count()`** (Profile stats + composer): không phụ thuộc số ảnh đã tải; refresh khi watch emit đầu + sau add/delete. Local mode fallback length.
- **D3 — On-this-day (Home cinema) = query riêng theo ngày:** range query `uploadDate` trong [ngày-này-năm-X, +1ngày) cho từng năm từ anniversary→nay, merge — KHÔNG dựa vào full list nữa.
- **D4 — Hạn chế chấp nhận:** ảnh bị partner XOÁ sau khi đã rớt khỏi window realtime sẽ còn hiển thị (stale) tới lần mở app sau — hiếm, đổi lấy đơn giản; ghi nợ.
- **D5 — Love-note history:** watch realtime 50 mới nhất + loadMore 50/lần (get + cursor createdAt), UI nút "Xem thêm" cuối list giống journal. Local mode load all (dữ liệu nhỏ).
- **D6 — KHÔNG sửa rules/functions/index** (orderBy/range single-field = index tự động; aggregate dùng quyền read sẵn có).

## 3. Acceptance criteria
1. Mở Gallery chỉ đọc ≤30 doc ảnh (+count); cuộn xuống tự load thêm 30, có loader cuối feed, hết thì thôi.
2. Ảnh mới partner đăng vẫn realtime vào đầu feed; xoá ảnh trong window realtime biến mất ở cả 2 máy.
3. Home cinema vẫn có on-this-day dù ảnh đó nằm ngoài 30 ảnh đầu; Profile đếm đúng TỔNG số ảnh.
4. History lời nhắn: 50 đầu realtime, "Xem thêm" tải tiếp, note >200 giờ xem được.
5. Journal giữ nguyên hành vi (đã có phân trang).
6. `fvm flutter analyze` 0 issue + `fvm flutter test` pass; không đụng rules/functions.

## 4. Nhật ký
- [2026-06-11] [po] Recon 3 màn, chốt D1–D6, giao Dev.
