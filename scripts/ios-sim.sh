#!/usr/bin/env bash
# ios-sim.sh — Wrapper chạy app iOS trên simulator, tự fix native_assets bug.
#
# Usage:
#   ./scripts/ios-sim.sh                  # run trên simulator mặc định (device đầu tiên)
#   ./scripts/ios-sim.sh <device-id>      # run trên device cụ thể
#   ./scripts/ios-sim.sh --clean          # flutter clean rồi fix rồi run
#
# Thay thế cho lệnh: flutter run -d <simulator-id>

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

CLEAN=false
DEVICE_ID=""

for arg in "$@"; do
  case "$arg" in
    --clean) CLEAN=true ;;
    *)       DEVICE_ID="$arg" ;;
  esac
done

# ── Auto-detect simulator nếu không chỉ định ──────────────────────────────────
if [[ -z "$DEVICE_ID" ]]; then
  DEVICE_ID=$(xcrun simctl list devices available 2>/dev/null \
    | grep "iPhone.*Booted" | head -1 \
    | grep -oE '\([A-F0-9-]{36}\)' | tr -d '()')
  if [[ -z "$DEVICE_ID" ]]; then
    # Boot iPhone 16 Plus nếu chưa boot
    DEVICE_ID=$(xcrun simctl list devices available 2>/dev/null \
      | grep "iPhone 16" | head -1 \
      | grep -oE '\([A-F0-9-]{36}\)' | tr -d '()')
    [[ -n "$DEVICE_ID" ]] && xcrun simctl boot "$DEVICE_ID" 2>/dev/null || true
  fi
fi

if [[ -z "$DEVICE_ID" ]]; then
  echo "❌ Không tìm thấy iOS simulator. Mở Xcode > Simulator trước." >&2
  exit 1
fi

echo "📱 Simulator: $DEVICE_ID"

cd "$PROJECT_DIR"

# ── flutter clean nếu cần ─────────────────────────────────────────────────────
if [[ "$CLEAN" == true ]]; then
  echo "🧹 flutter clean..."
  flutter clean
  flutter pub get
fi

# ── Fix native_assets simulator bug ───────────────────────────────────────────
echo "🔧 Fix simulator native_assets..."
bash "$SCRIPT_DIR/fix-simulator-native-assets.sh"

# ── Run ────────────────────────────────────────────────────────────────────────
echo "🚀 flutter run -d $DEVICE_ID"
flutter run -d "$DEVICE_ID" --no-pub
