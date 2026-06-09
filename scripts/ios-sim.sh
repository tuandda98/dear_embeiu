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

# ── Toolchain: dùng đúng Flutter của máy ──────────────────────────────────────
# Một số máy (vd máy cty) có bare `flutter` SAI version (3.5.4) → phải qua fvm;
# máy khác (bare flutter đúng version, vd máy nhà) dùng trực tiếp. Tự chọn: có
# `fvm` + repo pin version (`.fvmrc`/`.fvm/`) → `fvm flutter`, ngược lại `flutter`.
# ⚠️ Subprocess trong script KHÔNG bị hook ép-fvm chặn, nên phải tự chọn ở đây —
# nếu để bare `flutter` thì máy cty chạy nhầm 3.5.4 (đọc config cũ, native-assets
# off → "require the native assets feature to be enabled").
if command -v fvm >/dev/null 2>&1 && { [[ -f "$PROJECT_DIR/.fvmrc" ]] || [[ -d "$PROJECT_DIR/.fvm" ]]; }; then
  FLUTTER="fvm flutter"
else
  FLUTTER="flutter"
fi

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
echo "🛠  Toolchain: $FLUTTER"

cd "$PROJECT_DIR"

# ── flutter clean nếu cần ─────────────────────────────────────────────────────
if [[ "$CLEAN" == true ]]; then
  echo "🧹 $FLUTTER clean..."
  $FLUTTER clean
  $FLUTTER pub get
fi

# ── Fix native_assets simulator bug ───────────────────────────────────────────
echo "🔧 Fix simulator native_assets..."
bash "$SCRIPT_DIR/fix-simulator-native-assets.sh"

# ── Run ────────────────────────────────────────────────────────────────────────
echo "🚀 $FLUTTER run -d $DEVICE_ID"
$FLUTTER run -d "$DEVICE_ID" --no-pub
