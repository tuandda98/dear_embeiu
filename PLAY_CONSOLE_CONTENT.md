# Play Console — Nội dung Store Listing & Data Safety

## Store Listing

### App name
```
Dear Embeiu
```

### Short description (≤ 80 ký tự)
```
Đếm ngày yêu, lưu ảnh kỷ niệm và chia sẻ khoảnh khắc chỉ dành cho hai người.
```
*(79 ký tự)*

### Full description (≤ 4000 ký tự)
```
💌 Dear Embeiu — Không gian riêng tư dành cho hai người yêu nhau.

Bạn đã yêu nhau bao lâu rồi? Còn bao nhiêu ngày nữa đến kỷ niệm? Khoảnh khắc đẹp hôm qua được lưu ở đâu?

Dear Embeiu là ứng dụng nhỏ nhưng ý nghĩa, giúp hai bạn kết nối và lưu giữ hành trình yêu nhau — từng ngày, từng bức ảnh, từng khoảnh khắc đáng nhớ.

✨ TÍNH NĂNG NỔI BẬT

🗓️ Đếm ngày yêu nhau
Xem chính xác bạn đã ở bên nhau bao nhiêu ngày, bao nhiêu tháng, bao nhiêu năm. Kỷ niệm các mốc quan trọng — 100 ngày, 365 ngày, 1000 ngày — tự động được ghi nhận.

📸 Thư viện ảnh chung
Upload ảnh từ hai phía, thêm caption và xem lại kỷ niệm dưới dạng lưới ảnh đẹp mắt. Ai đã chụp ảnh nào cũng được ghi rõ.

🔔 Thông báo cho nhau
Khi người kia đăng ảnh mới, bạn sẽ nhận thông báo ngay. Một cách nhỏ nhắn để luôn cảm thấy gần nhau dù xa cách.

📅 Đếm ngược kỷ niệm
Biết chính xác còn bao nhiêu ngày đến ngày kỷ niệm tình yêu của hai bạn để chuẩn bị bất ngờ.

🔐 Hoàn toàn riêng tư
Chỉ hai người được ghép cặp bằng mã mời mới xem được dữ liệu của nhau. Không bạn bè, không mạng xã hội, không ai khác.

🌐 Hỗ trợ 2 ngôn ngữ
Chuyển đổi giữa Tiếng Việt và English trong phần Hồ sơ.

---
Dear Embeiu — lưu giữ từng ngày, vì mỗi ngày bên nhau đều đáng nhớ 💕
```

### Category
- Primary: **Lifestyle**
- Secondary: **Social**

### Content rating
- **Everyone** (ESRB) / **PEGI 3**
- Không có nội dung bạo lực, người lớn, hay ngôn từ xúc phạm.

### Tags / Keywords
```
cặp đôi, yêu nhau, kỷ niệm, ảnh đôi, đếm ngày yêu, couple app, anniversary, love diary, ký ức, thư viện ảnh
```

---

## Data Safety (Google Play)

Điền theo thứ tự trong Play Console > App content > Data safety.

### Bước 1: Data collection and security
- **Does your app collect or share any of the required user data types?** → ✅ YES
- **Is all of the user data collected by your app encrypted in transit?** → ✅ YES
- **Do you provide a way for users to request that their data is deleted?** → ✅ YES

### Bước 2: Data types collected

#### Personal info
| Data type     | Collected | Shared | Purpose              | Optional? |
|---------------|-----------|--------|----------------------|-----------|
| Name          | ✅        | ✅ (partner only) | App functionality | No |
| Email address | ✅        | ❌     | Account management   | No |

#### Photos and videos
| Data type | Collected | Shared | Purpose            | Optional? |
|-----------|-----------|--------|--------------------|-----------|
| Photos    | ✅        | ✅ (partner only) | App functionality | Yes |

#### App activity
| Data type        | Collected | Shared | Purpose             | Optional? |
|------------------|-----------|--------|---------------------|-----------|
| App interactions | ✅        | ❌     | Analytics/crash fix | No |
| Crash logs       | ✅        | ❌     | App stability       | No |

#### Device or other identifiers
| Data type   | Collected | Shared | Purpose             | Optional? |
|-------------|-----------|--------|---------------------|-----------|
| Device ID   | ✅        | ❌     | Push notifications  | No |

### Bước 3: Data usage and handling

Với từng loại dữ liệu, khai báo:
- **Purpose**: App functionality / Analytics / Account management
- **Data is encrypted in transit**: YES (Firebase uses TLS)
- **Users can request deletion**: YES (in-app + email)
- **Data is shared with third parties**: ONLY Firebase (Google) — khai báo Firebase là third-party service provider

---

## Các URL cần điền trong Play Console

Sau khi deploy Firebase Hosting (`firebase deploy --only hosting --project prod`):

| Mục | URL |
|-----|-----|
| Privacy Policy | `https://<project-id>.web.app/privacy-policy.html` |
| Account deletion | `https://<project-id>.web.app/account-deletion.html` |

> Lấy `<project-id>` từ Firebase Console > Project settings > Project ID.

---

## Checklist cuối cùng trước khi Submit

- [ ] `firebase deploy --only hosting --project prod` để host Privacy Policy + Account Deletion page
- [ ] Điền Privacy Policy URL vào Play Console > App content > Privacy policy
- [ ] Điền Account Deletion URL vào Play Console > App content > Data safety > Account deletion
- [ ] Chạy `assets/branding/export_assets.sh` để tạo PNG assets
- [ ] Upload `store_icon_512x512.png` vào Store listing > App icon
- [ ] Upload `feature_graphic_1024x500.png` vào Store listing > Feature graphic
- [ ] Chụp tối thiểu 4 screenshots từ máy thật/emulator, upload vào Store listing
- [ ] Hoàn thành IARC content rating questionnaire
- [ ] Build release AAB: `flutter build appbundle --release`
- [ ] Upload AAB lên Internal testing track trước
- [ ] Test trên máy thật qua Internal testing
- [ ] Promote lên Production khi ổn
