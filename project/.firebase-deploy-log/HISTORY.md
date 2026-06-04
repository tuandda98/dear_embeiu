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
