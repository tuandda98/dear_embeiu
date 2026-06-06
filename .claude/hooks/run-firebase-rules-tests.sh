#!/usr/bin/env bash
# Stop hook: ĐẢM BẢO mỗi lần logic Firebase (firestore.rules / storage.rules /
# functions/index.js) thay đổi thì TOÀN BỘ unit test rules được chạy lại trước
# khi kết thúc lượt, và FAIL sẽ chặn để bắt sửa.
#
# Cơ chế "chỉ chạy khi thật sự đổi": băm nội dung 3 file logic Firebase, so với
# hash của lần PASS gần nhất (lưu ở .firebase_rules_test.cache). Bằng nhau ->
# bỏ qua (không tốn ~15s emulator cho mỗi lần Stop). Khác nhau -> chạy test.
#
# Exit: 0 = ok/bỏ qua (không chặn) · 2 = test FAIL (chặn Stop, feedback cho Claude)
#
# KHÔNG dùng `set -e`: hook chỉ được chặn có chủ đích qua exit 2.
set -uo pipefail

# --- xác định ROOT (portable giữa các máy) ----------------------------------
ROOT="${CLAUDE_PROJECT_DIR:-}"
if [ -z "$ROOT" ]; then
  ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
fi
if [ -z "$ROOT" ]; then
  ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
fi

# Không phải repo Firebase này -> thoát êm.
[ -f "$ROOT/firestore.rules" ] || exit 0
[ -x "$ROOT/scripts/test-firebase-rules.sh" ] || exit 0

input="$(cat 2>/dev/null || true)"
active="$(printf '%s' "$input" | jq -r '.stop_hook_active // false' 2>/dev/null || echo false)"

# --- hash 3 file logic Firebase ---------------------------------------------
sha() { if command -v shasum >/dev/null 2>&1; then shasum -a 256; else sha256sum; fi; }
cur="$(cat "$ROOT/firestore.rules" "$ROOT/storage.rules" "$ROOT/functions/index.js" 2>/dev/null | sha | awk '{print $1}')"

cache="$ROOT/.firebase_rules_test.cache"
prev="$(cat "$cache" 2>/dev/null || echo "")"

# Không đổi so với lần PASS gần nhất -> không cần chạy lại.
[ "$cur" = "$prev" ] && exit 0

# --- chạy toàn bộ test ------------------------------------------------------
log="$ROOT/firebase_rules_test/.last-run.log"
"$ROOT/scripts/test-firebase-rules.sh" >"$log" 2>&1
rc=$?

if [ "$rc" -eq 0 ]; then
  printf '%s' "$cur" > "$cache"
  exit 0
fi

if [ "$rc" -eq 3 ]; then
  # Thiếu JDK 21+ -> không chặn (máy chưa đủ hạ tầng), chỉ cảnh báo.
  echo "⚠ Bỏ qua Firebase rules tests: $(tail -2 "$log" | tr '\n' ' ')" >&2
  exit 0
fi

# rc khác 0/3 => test FAIL.
if [ "$active" = "true" ]; then
  # Đã ở trong vòng continuation rồi -> không chặn lại (tránh loop vô hạn).
  echo "⚠ Firebase rules tests VẪN FAIL (xem $log)." >&2
  exit 0
fi

{
  echo "✗ FIREBASE RULES UNIT TESTS FAIL — thay đổi logic Firestore/Storage rules làm hỏng test."
  echo "  Chạy lại để xem chi tiết:  scripts/test-firebase-rules.sh   (log: $log)"
  echo "  --- tóm tắt ---"
  grep -E "passing|failing|^\s+[0-9]+\)|Error:" "$log" | tail -25
} >&2
exit 2
