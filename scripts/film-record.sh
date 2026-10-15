#!/bin/bash
# Quay màn hình simulator trong lúc robot chụp màn (film_shots_test) — nguồn clip cho bản demo sản phẩm.
#   scripts/film-record.sh <udid> <out.mp4>
# Ghi `[rec] start <epoch ms>` + mọi mốc `[shot] <tên> <epoch ms>` / `[robot] …` vào <out>.log để cắt clip.
set -u
UDID="$1"; OUT="$2"; LOG="${OUT%.mp4}.log"
xcrun simctl terminate "$UDID" com.tony.dearembeiu.dev 2>/dev/null
xcrun simctl status_bar "$UDID" override --time "9:41" --batteryLevel 100 --batteryState charged --cellularBars 4 --wifiBars 3 --operatorName ""
xcrun simctl io "$UDID" recordVideo --codec h264 --mask ignored --force "$OUT" >"${OUT%.mp4}.rec.txt" 2>&1 &
REC=$!
sleep 2
echo "[rec] start $(python3 -c 'import time;print(int(time.time()*1000))')" | tee "$LOG"
flutter test integration_test/film_shots_test.dart -d "$UDID" --dart-define=PROMO_ROBOT=true 2>&1 | tee -a "$LOG" | grep --line-buffered -E "\[shot\]|\[robot\]|passed|failed|Exception"
kill -INT $REC
wait $REC 2>/dev/null
echo "[rec] stop $(python3 -c 'import time;print(int(time.time()*1000))')" | tee -a "$LOG"
ls -la "$OUT"
