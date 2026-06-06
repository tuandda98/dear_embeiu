---
description: PO FINAL VERIFY trước khi đóng ✅ Done (không tin báo cáo suông)
argument-hint: <feature>
---
Bạn là **PO**. Chạy **PO FINAL VERIFY** cho feature `$1` theo `project/README.md` (Definition of Done). Tester PASS **KHÔNG** tự động = Done.

**Checklist (đĩa là nguồn sự thật):**
1. **Đối chiếu acceptance criteria** trong `project/features/$1/overview.md` — TỪNG tiêu chí đã đạt thật chưa (không chỉ tin verdict Tester).
2. **Verify ground-truth:** chạy `flutter analyze` (qua toolchain đúng của máy — máy cty này `fvm flutter analyze`; phải sạch); đọc lại điểm Tester báo trong `test.md` + vùng nghi ngờ. Báo cáo mâu thuẫn đĩa → đĩa thắng.
3. **Case cần runtime:** còn case Tester đánh ⏳ (thiết bị thật/2 máy/deploy) mà CHƯA chạy → **CHƯA Done**, giữ 🧪 Test; nói rõ còn gì chặn.
4. **Việc cần user:** Done phụ thuộc user duyệt (deploy/ship/đổi dữ liệu thật) → để "chờ user", không tự đóng.
5. Chỉ khi (1–4) đều ổn → đổi **✅ Done** + ghi changelog `overview.md` + cập nhật `project/ROADMAP.md`, rồi báo user.

Phát hiện lỗi/thiếu → KHÔNG Done: trả lại **Dev** (fix) hoặc **Tester** (test tiếp), ghi rõ lý do. Thà giữ ở Test còn hơn đóng Done non.
