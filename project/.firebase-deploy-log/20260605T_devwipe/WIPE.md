# Dev Firestore Wipe — 2026-06-05

**Action:** `firestore:delete --all-collections --project dev --force`  
**Project:** tonyembeiu-dev (DEV ONLY)  
**Lý do:** Reset sạch để test lại từ đầu feature couple-code  
**Collections đã xóa:** couples, invite_codes, users  
**Collections không tồn tại (0 docs):** couple_codes, reports  
**Storage:** KHÔNG xóa được qua CLI — xóa thủ công nếu cần  
**Auth users:** KHÔNG xóa — cần xóa thủ công trên Firebase Console  
**Prod (tonyembeiu):** KHÔNG đụng  

## Restore
Không có snapshot để restore — đây là dev data test, không có data thật.
