#!/usr/bin/env bash
# Chạy TOÀN BỘ unit test cho Firestore + Storage security rules trên Firebase
# emulator. Tự bật/tắt emulator (firebase emulators:exec) nên không cần quản lý
# tiến trình thủ công. Portable giữa các máy: tự dò JDK 21+ (firebase-tools 15
# yêu cầu Java >= 21).
#
# Exit codes:
#   0  = tất cả test pass
#   1  = có test FAIL (hoặc lỗi khi chạy)
#   3  = thiếu hạ tầng (không tìm thấy JDK 21+) -> hook coi là non-blocking
#
# Dùng: scripts/test-firebase-rules.sh
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TEST_DIR="$ROOT/firebase_rules_test"

# --- 1. Dò JDK 21+ ----------------------------------------------------------
# In ra JAVA_HOME cần set (rỗng = java hiện tại đã >= 21). return 1 = không thấy.
java_major() { # $1 = path tới bin/java
  "$1" -version 2>&1 | head -1 | sed -nE 's/.*version "([0-9]+).*/\1/p'
}

find_java21() {
  # (1) java đang trên PATH
  if command -v java >/dev/null 2>&1; then
    local v; v="$(java_major "$(command -v java)")"
    if [ -n "$v" ] && [ "$v" -ge 21 ] 2>/dev/null; then echo ""; return 0; fi
  fi
  # (2) macOS java_home — LƯU Ý: `java_home -v 21` có thể fallback trả về JDK
  #     khác (vd 17) khi không có 21 thật, nên phải validate version thực.
  if [ -x /usr/libexec/java_home ]; then
    local jh; jh="$(/usr/libexec/java_home -v 21 2>/dev/null || true)"
    if [ -n "$jh" ] && [ -x "$jh/bin/java" ]; then
      local v; v="$(java_major "$jh/bin/java")"
      if [ -n "$v" ] && [ "$v" -ge 21 ] 2>/dev/null; then echo "$jh"; return 0; fi
    fi
  fi
  # (3) Android Studio bundled JBR (thường là JDK 21)
  local p
  for p in \
    "/Applications/Android Studio.app/Contents/jbr/Contents/Home" \
    "$HOME/Applications/Android Studio.app/Contents/jbr/Contents/Home" \
    "/Applications/Android Studio Preview.app/Contents/jbr/Contents/Home"; do
    if [ -x "$p/bin/java" ]; then
      local v; v="$(java_major "$p/bin/java")"
      if [ -n "$v" ] && [ "$v" -ge 21 ] 2>/dev/null; then echo "$p"; return 0; fi
    fi
  done
  # (4) Homebrew openjdk
  for p in \
    /opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home \
    /opt/homebrew/opt/openjdk/libexec/openjdk.jdk/Contents/Home \
    /usr/local/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home \
    /usr/local/opt/openjdk/libexec/openjdk.jdk/Contents/Home; do
    if [ -x "$p/bin/java" ]; then echo "$p"; return 0; fi
  done
  return 1
}

if JH="$(find_java21)"; then
  if [ -n "$JH" ]; then
    export JAVA_HOME="$JH"
    export PATH="$JH/bin:$PATH"
  fi
else
  echo "✗ Không tìm thấy JDK 21+ (firebase-tools 15 yêu cầu Java >= 21)." >&2
  echo "  Cài: brew install openjdk@21   — hoặc dùng JBR của Android Studio." >&2
  exit 3
fi

# --- 2. Đảm bảo deps đã cài --------------------------------------------------
if [ ! -d "$TEST_DIR/node_modules" ]; then
  echo "• Cài deps test (lần đầu)…"
  ( cd "$TEST_DIR" && npm install ) || { echo "✗ npm install thất bại" >&2; exit 1; }
fi

# --- 3. Check cú pháp Cloud Functions (functions chưa có unit test riêng) ----
if [ -f "$ROOT/functions/index.js" ]; then
  if ! node -c "$ROOT/functions/index.js"; then
    echo "✗ functions/index.js có lỗi cú pháp" >&2
    exit 1
  fi
  echo "✓ functions/index.js cú pháp OK"
fi

# --- 4. Chọn binary firebase-tools ------------------------------------------
if command -v firebase >/dev/null 2>&1; then
  FIREBASE=(firebase)
else
  FIREBASE=(npx --yes firebase-tools)
fi

# --- 5. Chạy rules test trong emulator --------------------------------------
cd "$ROOT"
"${FIREBASE[@]}" emulators:exec --only firestore,storage --project demo-dear-embeiu \
  "cd firebase_rules_test && npx mocha"
