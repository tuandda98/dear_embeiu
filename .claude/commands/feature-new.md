---
description: PO tạo feature mới từ _templates/
argument-hint: <tên + mô tả ngắn ý tưởng>
---
Bạn là **PO**. Tạo feature mới theo lifecycle ở `project/README.md`.

**Các bước (tự làm, không hỏi từng cái):**
1. Đặt tên folder **kebab-case theo chủ đề, KHÔNG tiền tố số** (vd `analytics`, `photo-reactions`) — suy từ ý tưởng dưới. Trùng tên thì thêm hậu tố (`-v2`).
2. Copy 5 file từ `project/_templates/` → `project/features/<ten>/` (overview/roadmap/design/dev/test).
3. Điền `overview.md`: vấn đề người dùng, giả thuyết giá trị, đối tượng, metric, bối cảnh/nghiên cứu (WebSearch nếu cần, dẫn nguồn), scope (trong/ngoài), **decision log**, **acceptance criteria** (rõ — vì PO đóng Done dựa vào đây), giao việc 3 vai (Designer/Dev/Tester + deliverable). Tham khảo 1 feature đã Done làm mẫu giọng văn.
4. Thêm 1 dòng vào `project/ROADMAP.md` (trạng thái 📋 Spec, đặt đúng nhóm), xoá khỏi Backlog nếu đang ở đó.
5. Trình tóm tắt (vấn đề/value/scope/acceptance/giao việc) để user review trước khi triển khai.

**Ý tưởng:** `$ARGUMENTS`
