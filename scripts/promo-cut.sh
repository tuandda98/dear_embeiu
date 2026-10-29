#!/bin/bash
# Cắt 1 đoạn từ bản quay simulator (1206x2622, 60fps) → clip màn hình cho video quảng cáo:
# phủ Dynamic Island, 30 fps, h264 yuv420p, không tiếng.
#   scripts/promo-cut.sh <in.mp4> <start_s> <dur_s> <out.mp4> [island.png]
set -eu
IN="$1"; START="$2"; DUR="$3"; OUT="$4"; ISLAND="${5:-}"
if [ -n "$ISLAND" ]; then
  ffmpeg -hide_banner -loglevel error -y -ss "$START" -t "$DUR" -i "$IN" -i "$ISLAND" \
    -filter_complex "[0:v]fps=30,eq=contrast=1.04[v];[v][1:v]overlay=(W-w)/2:33" \
    -an -c:v libx264 -preset slow -crf 17 -pix_fmt yuv420p -movflags +faststart "$OUT"
else
  ffmpeg -hide_banner -loglevel error -y -ss "$START" -t "$DUR" -i "$IN" \
    -vf "fps=30,eq=contrast=1.04" -an -c:v libx264 -preset slow -crf 17 -pix_fmt yuv420p -movflags +faststart "$OUT"
fi
ffprobe -v error -show_entries format=duration -of csv=p=0 "$OUT"
