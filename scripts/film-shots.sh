#!/bin/bash
# Chụp từng màn hình app theo mốc `[shot] <tên>` mà integration_test/film_shots_test.dart in ra
# (tư liệu cho phim videos/dear-embeiu-launch-50s). Chạy SAU `node scripts/dev-seed-promo.js`.
#   scripts/film-shots.sh ios <udid> <thư mục ra>
#   scripts/film-shots.sh android <emulator-5554> <thư mục ra>
set -u
PLAT="$1"; DEV="$2"; OUT="$3"
mkdir -p "$OUT"
export PATH="$PATH:$HOME/Library/Android/sdk/platform-tools"

snap() {
  local n="$1"
  if [ "$PLAT" = ios ]; then
    xcrun simctl io "$DEV" screenshot --type=png "$OUT/$n.png" >/dev/null 2>&1
  else
    adb -s "$DEV" exec-out screencap -p > "$OUT/$n.png"
  fi
  echo "[snap] $n"
}

if [ "$PLAT" = ios ]; then
  xcrun simctl terminate "$DEV" com.tony.dearembeiu.dev 2>/dev/null
  xcrun simctl status_bar "$DEV" override --time "9:41" --batteryLevel 100 --batteryState charged --cellularBars 4 --wifiBars 3 --operatorName ""
else
  adb -s "$DEV" shell settings put global sysui_demo_allowed 1
  adb -s "$DEV" shell am broadcast -a com.android.systemui.demo -e command enter >/dev/null
  adb -s "$DEV" shell am broadcast -a com.android.systemui.demo -e command clock -e hhmm 0941 >/dev/null
  adb -s "$DEV" shell am broadcast -a com.android.systemui.demo -e command battery -e level 100 -e plugged false >/dev/null
  adb -s "$DEV" shell am broadcast -a com.android.systemui.demo -e command network -e wifi show -e level 4 >/dev/null
  adb -s "$DEV" shell am broadcast -a com.android.systemui.demo -e command network -e mobile show -e datatype none -e level 4 >/dev/null
  adb -s "$DEV" shell am broadcast -a com.android.systemui.demo -e command notifications -e visible false >/dev/null
fi

flutter test integration_test/film_shots_test.dart -d "$DEV" --dart-define=PROMO_ROBOT=true 2>&1 | tee "$OUT/run.log" | while IFS= read -r line; do
  case "$line" in
    *"[shot] "*) n=$(printf '%s' "$line" | sed -E 's/.*\[shot\] ([A-Za-z0-9_-]+).*/\1/'); snap "$n" ;;
    *"[robot]"*|*"All tests passed"*|*"Some tests failed"*|*Exception*|*"Error:"*) echo "$line" ;;
  esac
done

if [ "$PLAT" = android ]; then
  adb -s "$DEV" shell am broadcast -a com.android.systemui.demo -e command exit >/dev/null
fi
ls "$OUT"/*.png 2>/dev/null | wc -l
