# What's New — Dear Embeiu 1.8.0 (build 25)

> Copy vào **CẢ HAI**: App Store Connect → 1.8.0 → "What's New" · Google Play → "Có gì mới".
> ℹ️ 1.8.0 = **MINOR**: tính năng mới **Giấc ngủ** (feature `sleep`), **Cây Tình Yêu v3** (chòm sao hôm nay), rà văn phong toàn app, App Check (không nêu công khai). ĐỤNG backend (rules giấc ngủ + 22 Cloud Functions), deploy PROD cùng đợt.
> ⚠️ CHỈ nêu thay đổi CÔNG KHAI.

## 🇻🇳 Tiếng Việt (primary) — ≤500 ký tự (giới hạn Play)
```
Giấc ngủ của chúng mình 🌙

• Lịch trăng ghi lại từng đêm: trăng càng tròn, ngủ càng đủ giấc.
• iPhone lấy dữ liệu từ ứng dụng Sức khoẻ, Android ước lượng qua lúc màn hình tắt và sáng.
• Bật chia sẻ thì người ấy thấy bạn ngủ, dậy lúc mấy giờ. Tắt thì chỉ mình bạn xem được.
• Đêm nào sửa hay ghi tay đều có nhãn.
• Cây Tình Yêu có bầu trời đêm: mỗi người 3 ngôi sao cho câu hỏi, tâm trạng và tin nhắn hôm nay.
• Câu chữ trong app tự nhiên hơn.

Cảm ơn hai bạn đã cùng nhau lưu giữ kỷ niệm 🌷
```

## 🇬🇧 English — ≤500 ký tự
```
Our sleep 🌙

• A moon calendar of your nights: the fuller the moon, the better you slept.
• iPhone reads sleep from Apple Health; Android estimates it from screen off/on times.
• Share with your person and they see when you slept and woke. Turn it off and only you can see it.
• Edited or hand-logged nights are labeled.
• The Love Tree has a night sky: 3 stars each for today's question, mood and message.
• Smoother wording across the app.

Thanks for keeping your memories together with us 🌷
```

### Bản dán cho App Store (không emoji, gạch "-"; bỏ dòng Android vì đây là store iOS)
```
Giấc ngủ của chúng mình

- Lịch trăng ghi lại từng đêm: trăng càng tròn, ngủ càng đủ giấc.
- Giấc ngủ lấy từ ứng dụng Sức khoẻ (Apple Health) khi bạn cho phép.
- Bật chia sẻ thì người ấy thấy bạn ngủ, dậy lúc mấy giờ. Tắt thì chỉ mình bạn xem được.
- Đêm nào sửa hay ghi tay đều có nhãn.
- Cây Tình Yêu có bầu trời đêm: mỗi người 3 ngôi sao cho câu hỏi, tâm trạng và tin nhắn hôm nay.
- Câu chữ trong app tự nhiên hơn.

Cảm ơn hai bạn đã cùng nhau lưu giữ kỷ niệm.
```

### Thêm vào phần Mô tả trên App Store (Apple đòi nêu tích hợp Sức khoẻ — guideline 2.5.1)
```
Giấc ngủ: xem mỗi đêm ngủ bao lâu trên lịch trăng. Trên iPhone, app đọc dữ liệu giấc ngủ từ ứng dụng Sức khoẻ (Apple Health) khi bạn cho phép, chỉ đọc, không ghi gì vào Sức khoẻ.
```

---

## Ghi chú nội bộ — 1.8.0 (build 25)
- Nội dung: `feature/sleep` (gồm `feature/app-check`): Giấc ngủ Phase 1, Cây Tình Yêu v3, rà văn phong + sửa lỗi Firebase/CF lọt tiếng Anh, App Check (chế độ thu thập, KHÔNG enforce), sửa ô lịch trăng lệch trái.
- Backend PROD: `firestore:rules` (thêm `couples/{id}/sleep/...`, chỉ thêm) + 22 function gọi đích danh (copy push/lỗi, prompt AI, dọn dữ liệu giấc ngủ ở `notifyPartnerLeft`/`deleteAccount`/`leaveCoupleCleanup`). KHÔNG dùng `--only functions` trần: PROD còn `birthdayGreeting`/`birthdayWish` deploy từ nhánh `phase3`, deploy trần sẽ đòi xoá 2 hàm này.
- Feature tour: 2 entry `sinceBuild: 25` (Giấc ngủ, Chòm sao hôm nay).
- Khai báo store: App Privacy (Health) trên App Store Connect, An toàn dữ liệu (Thông tin sức khoẻ) + khai báo ứng dụng sức khoẻ trên Play, chính sách quyền riêng tư có mục giấc ngủ.
- Mixed-version: người ấy còn 1.7.x không có màn Giấc ngủ nên không xem/chia sẻ được; autoStoreForce ép cập nhật khi 1.8.0 live.
- Force-update: không nâng `minBuildNumber` (quyết định 2026-09-07).
