# Firebase deploy log — tự động (hook trace-firebase-deploy.sh)

> Mỗi deploy = 1 dòng dưới đây + 1 folder snapshot `<UTC-timestamp>/`. Dùng để RESTORE khi deploy hỏng.
>
> **Cách restore:**
> - **Rules (lúc deploy sạch, dirty=0):** `git checkout <git_head> -- firestore.rules storage.rules` → deploy lại.
> - **Rules (lúc deploy dirty):** lấy file trong `project/.firebase-deploy-log/<ts>/firestore.rules|storage.rules`, copy đè vào repo → deploy lại.
> - **Functions:** `git checkout <git_head> -- functions` → `npx firebase-tools deploy --only functions --project tonyembeiu`.
> - **Hoặc** dùng lịch sử bản rules có sẵn trong Firebase Console (Firestore/Storage → Rules → history).

- [20260604T051438Z] head=d6a7157 dirty=21 exit=? · `cd /Users/tony.tuando/StudioProjects/dear_embeiu
npx firebase-tools deploy --only firestore:rules --project tonyembeiu 2>&1 | tail -25` · snapshot `20260604T051438Z/`
- [20260604T060623Z] head=d6a7157 dirty=37 exit=? · `cd /Users/tony.tuando/StudioProjects/dear_embeiu
npx firebase-tools deploy --only firestore:rules,firestore:indexes,functions:notifyPhotoReaction,functions:deleteCoupleCompletely --project tonyembeiu 2>&1 | tail -35` · snapshot `20260604T060623Z/`
- [20260604T060923Z] head=d6a7157 dirty=37 exit=? · `cd /Users/tony.tuando/StudioProjects/dear_embeiu
npx firebase-tools deploy --only firestore:rules,firestore:indexes,functions:notifyPhotoReaction,functions:deleteAccount --project tonyembeiu 2>&1 | tail -30` · snapshot `20260604T060923Z/`
- [20260604T083055Z] head=d6a7157 dirty=47 exit=? · `cd /Users/tony.tuando/StudioProjects/dear_embeiu
npx firebase-tools deploy --only firestore:rules --project tonyembeiu 2>&1 | tail -8` · snapshot `20260604T083055Z/`
- [20260605T060843Z] head=cd32f4d dirty=15 exit=? · `npx firebase-tools deploy --only firestore:rules,firestore:indexes,storage --project dev 2>&1 | grep -v "DeprecationWarning\|trace-deprecation\|punycode" | tail -40` · snapshot `20260605T060843Z/`
- [20260605T105348Z] head=cd32f4d dirty=41 exit=? · `cd /Users/tony.tuando/StudioProjects/dear_embeiu
npx firebase-tools deploy --only functions:sendCustomVerificationEmail --project dev 2>&1 | grep -v "punycode\|DeprecationWarning\|trace-deprecation" | tail -40
echo "DEPLOY_EXIT=${PIPESTATUS[0]}"` · snapshot `20260605T105348Z/`
- [20260605T135534Z] head=77a217e dirty=16 exit=0 · `npx firebase-tools deploy --only functions:sendCustomVerificationEmail --project prod` · snapshot `20260605T135534Z/` · (manual trace — prod email-verify deploy + secret copy dev→prod)
- [20260605T144321Z] head=77a217e branch=phase2 exit=0 · DEV `deploy --only functions,firestore:rules,firestore:indexes,storage --project dev` (full parity: tạo 8 function thiếu; 6 Firestore-trigger phải retry vì Eventarc first-time) · snapshot `20260605T144321Z/`
- [20260605T144321Z] head=77a217e branch=phase2 exit=0 · PROD `deploy --only functions:notifyPartnerLeft --project prod --force` (CF mới báo partner rời couple) · snapshot `20260605T144321Z/`
- [20260605T144321Z] head=77a217e branch=phase2 exit=0 · DEV retry `deploy --only functions:{6 Firestore-trigger} --project dev --force` → 6/6 OK · snapshot `20260605T144321Z/`
- [20260605T150000Z] branch=phase2 exit=0 · DEV+PROD `deploy --only firestore:rules` · feature couple-code: thêm couple_codes collection rules + coupleCode field vào couple rules · snapshot `20260605T150000Z/`
- [20260606T034810Z] head=16dd17b branch=phase2 exit=0 · PROD `deploy --only firestore:rules,storage,functions:leaveCoupleCleanup --project prod` · fix backward-compat (coupleCode+languageCode dùng data.get) + tạo CF leaveCoupleCleanup · snapshot `20260606T034810Z/`
- [20260606T notifications] head=781cdc4 branch=phase2 dirty=28 exit=0 · DEV `deploy --only firestore:rules,firestore:indexes,functions --project dev --force` · feature **notification center**: rules `users/{uid}/notifications` (create=admin-only) + composite index (coupleId+createdAt) + 11 functions update (6 sender thêm `writeInboxNotifications`, deleteAccount thêm recursiveDelete notifications) · (manual trace — chạy nền nên hook không tự ghi) · **PROD CHƯA deploy (chờ lệnh user)** · restore: `git checkout 781cdc4 -- firestore.rules firestore.indexes.json functions` (lưu ý: working tree dirty, dùng file repo hiện tại)
- [20260608T064709Z] head=5d606eb dirty=32 exit=? · `cd /Users/tony.tuando/StudioProjects/dear_embeiu
npx firebase-tools deploy --only firestore:rules,functions --project dev 2>&1 | grep -vE "DeprecationWarning|trace-deprecation|punycode" | tail -50
echo "DEPLOY_EXIT=${PIPESTATUS[0]}"` · snapshot `20260608T064709Z/`
- [20260610T080702Z] head=454983e dirty=28 exit=? · `npx firebase-tools deploy --only firestore:rules 2>&1 | tail -5` · snapshot `20260610T080702Z/`
- [20260611T113157Z] head=5bf467c dirty=68 exit=? · `npx firebase-tools deploy --only firestore:rules 2>&1 | tail -10` · snapshot `20260611T113157Z/`
- [20260611T113415Z] head=5bf467c dirty=68 exit=? · `npx firebase-tools deploy --only functions:notifyChatMessage 2>&1 | tail -15` · snapshot `20260611T113415Z/`
