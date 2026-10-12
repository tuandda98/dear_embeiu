#!/usr/bin/env bash
# Đưa AAB vào ô "Tải lên" của trang Chuẩn bị bản phát hành (Play Console) đang mở trong Chrome.
# Cầu nối Chrome MCP giới hạn 10MB nên KHÔNG dùng file_upload; thay vào đó:
#   1) Claude (Chrome MCP) bấm nút "Tải lên" trong dropzone → macOS mở hộp thoại chọn file
#   2) script này dán đường dẫn vào hộp thoại (Cmd+Shift+G) rồi Enter → Play bắt đầu upload
# Dùng: scripts/store-upload/upload-android-play.sh --focus   — đưa tab Play (URL chứa /releases/…/prepare) lên foreground.
#        ⚠️ BẮT BUỘC chạy TRƯỚC khi Claude bấm "Tải lên": tab MCP nằm ở cửa sổ/Space nền thì Chrome KHÔNG mở file chooser
#        (bài học 2026-09-14 — bấm 2 lần không có hộp thoại). Kiểm có hộp thoại: `.bin/winlist "Google Chrome" | grep "\[Mở\]"`.
#      scripts/store-upload/upload-android-play.sh [path.aab]   — chạy NGAY SAU khi bấm "Tải lên" (hộp thoại đang mở).
# ⚠️ Dán qua clipboard, KHÔNG keystroke (Telex biến "aab" → "âb"). Chrome có thể ở Space khác — không sao, keystroke đi theo process frontmost.
set -euo pipefail
if [ "${1:-}" = "--focus" ]; then
  osascript -e 'tell application "Google Chrome"' -e 'repeat with w in windows' -e 'set i to 1' -e 'repeat with t in tabs of w' \
    -e 'if URL of t contains "play.google.com/console" and URL of t contains "/prepare" then' -e 'set active tab index of w to i' -e 'set index of w to 1' -e 'activate' -e 'return "focused"' -e 'end if' \
    -e 'set i to i + 1' -e 'end repeat' -e 'end repeat' -e 'return "not found"' -e 'end tell'
  exit 0
fi
AAB="${1:-build/app/outputs/bundle/release/app-release.aab}"; AAB="$(cd "$(dirname "$AAB")" && pwd)/$(basename "$AAB")"
[ -f "$AAB" ] || { echo "✗ không thấy $AAB"; exit 1; }
printf '%s' "$AAB" | pbcopy
osascript <<'AS'
tell application "Google Chrome" to activate
delay 1.5
tell application "System Events" to tell process "Google Chrome"
  set frontmost to true
  keystroke "g" using {command down, shift down}
  delay 1.5
  keystroke "a" using {command down}
  keystroke "v" using {command down}
  delay 1.5
  keystroke return
  delay 2.5
  keystroke return
  delay 2
  return "sheets còn lại: " & (count of sheets of front window)
end tell
AS
echo "✓ đã dán đường dẫn + Enter — Claude chụp lại tab Play để xác nhận 'Đang tải app-release.aab lên'"
