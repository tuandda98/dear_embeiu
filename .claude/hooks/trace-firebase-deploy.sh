#!/usr/bin/env bash
# Ghi VẾT mỗi lần deploy Firebase để có thể RESTORE.
# Trigger: PostToolUse trên Bash, khi lệnh chứa `firebase ... deploy` / `firebase-tools ... deploy`.
# Lưu vào project/.firebase-deploy-log/:
#   - HISTORY.md : 1 dòng/deploy (có hướng dẫn restore ở đầu file)
#   - <UTC-ts>/  : snapshot firestore.rules + storage.rules + MANIFEST.txt (git HEAD, dirty, lệnh, exit)
# Restore: checkout đúng git_head rồi deploy lại; nếu lúc deploy bị dirty thì dùng file snapshot.
# KHÔNG dùng `set -e`: hook chỉ ghi log, luôn exit 0, không bao giờ chặn/giật tool.
ROOT="/Users/tony.tuando/StudioProjects/dear_embeiu"
input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // ""' 2>/dev/null)

# Chỉ ghi khi `firebase`/`npx firebase-tools` thật sự ĐỨNG Ở VỊ TRÍ LỆNH (đầu lệnh,
# sau ; & | (, hoặc sau `npx`) + theo sau là `deploy`. Neo như vậy để KHÔNG bắt nhầm
# các lệnh chỉ NHẮC TỚI chuỗi "firebase deploy" trong echo/grep/comment.
# Bỏ qua functions:log, projects:list, firestore:delete, v.v. (không có `deploy` ngay sau).
printf '%s' "$cmd" | grep -qiE '(^|[;&|(])[[:space:]]*(npx[[:space:]]+(-y[[:space:]]+)?)?firebase(-tools)?[[:space:]]+deploy([[:space:]]|$)' || exit 0

ts=$(date -u +%Y%m%dT%H%M%SZ)
log_dir="$ROOT/project/.firebase-deploy-log"
snap="$log_dir/$ts"
mkdir -p "$snap"

head=$(git -C "$ROOT" rev-parse --short HEAD 2>/dev/null || echo "no-git")
branch=$(git -C "$ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "?")
# dirty = số file thay đổi NGOÀI thư mục log (loại chính log để khỏi tự nhiễu)
dirty=$(git -C "$ROOT" status --porcelain 2>/dev/null | grep -vc '.firebase-deploy-log')
exit_code=$(printf '%s' "$input" | jq -r '.tool_response.exit_code // .tool_response.exitCode // "?"' 2>/dev/null)

# Snapshot artifact restore-được-bằng-file (rules nhỏ → copy luôn)
for f in firestore.rules storage.rules; do
  [ -f "$ROOT/$f" ] && cp "$ROOT/$f" "$snap/$f"
done

{
  echo "command : $cmd"
  echo "time_utc: $ts"
  echo "git_head: $head ($branch)"
  echo "dirty   : $dirty file thay đổi ngoài commit (0 = sạch → restore bằng git checkout $head)"
  echo "exit    : $exit_code"
  echo "snapshot: firestore.rules / storage.rules (nếu có) trong folder này"
  echo "functions: restore bằng \`git checkout $head -- functions\` rồi redeploy"
} > "$snap/MANIFEST.txt"

hist="$log_dir/HISTORY.md"
if [ ! -f "$hist" ]; then
  cat > "$hist" <<'EOF'
# Firebase deploy log — tự động (hook trace-firebase-deploy.sh)

> Mỗi deploy = 1 dòng dưới đây + 1 folder snapshot `<UTC-timestamp>/`. Dùng để RESTORE khi deploy hỏng.
>
> **Cách restore:**
> - **Rules (lúc deploy sạch, dirty=0):** `git checkout <git_head> -- firestore.rules storage.rules` → deploy lại.
> - **Rules (lúc deploy dirty):** lấy file trong `project/.firebase-deploy-log/<ts>/firestore.rules|storage.rules`, copy đè vào repo → deploy lại.
> - **Functions:** `git checkout <git_head> -- functions` → `npx firebase-tools deploy --only functions --project tonyembeiu`.
> - **Hoặc** dùng lịch sử bản rules có sẵn trong Firebase Console (Firestore/Storage → Rules → history).

EOF
fi
echo "- [$ts] head=$head dirty=$dirty exit=$exit_code · \`$cmd\` · snapshot \`$ts/\`" >> "$hist"
exit 0
