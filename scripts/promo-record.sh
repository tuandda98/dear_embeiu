#!/bin/bash
# Quay màn hình simulator trong lúc robot bấm theo kịch bản (feature promo-video).
#   scripts/promo-record.sh <udid> <out.mp4> [log]
# In mốc `[robot] <nhãn> <epoch ms>` từ flutter test + `[rec] start <epoch ms>` để cắt đoạn.
set -u
UDID="$1"; OUT="$2"; LOG="${3:-${OUT%.mp4}.log}"
xcrun simctl terminate "$UDID" com.tony.dearembeiu.dev 2>/dev/null
xcrun simctl status_bar "$UDID" override --time "9:41" --batteryLevel 100 --batteryState charged --cellularBars 4 --wifiBars 3 --operatorName ""
xcrun simctl io "$UDID" recordVideo --codec h264 --mask ignored --force "$OUT" >"${OUT%.mp4}.rec.txt" 2>&1 &
REC=$!
sleep 2
echo "[rec] start $(python3 -c 'import time;print(int(time.time()*1000))')" | tee "$LOG"
flutter test integration_test/promo_robot_test.dart -d "$UDID" --dart-define=PROMO_ROBOT=true 2>&1 | tee -a "$LOG" | grep --line-buffered "\[robot\]\|Error\|error\|passed\|failed\|Exception" 
kill -INT $REC
wait $REC 2>/dev/null
echo "[rec] stop $(python3 -c 'import time;print(int(time.time()*1000))')" | tee -a "$LOG"
ls -la "$OUT"
