#!/usr/bin/env bash
# The 45 s product demo (composition "Demo"): soundtrack → picture (H.264, CRF 16, muted) → mux with the master
# (AAC 256k behind a −1.8 dBFS limiter: AAC overshoots the PCM true peak) → a light preview → technical check.
# Usage (project root): bash scripts/render-demo.sh        CONCURRENCY=n to change the number of Chrome tabs (≤ 4).
set -euo pipefail
cd "$(dirname "$0")/.."
NAME=dear-embeiu-demo-45s
D=out/deliver
M=out/master
mkdir -p "$D" "$M"

node audio/demo/build.ts
npx remotion render src/index.ts Demo "$M/demo.mp4" --codec=h264 --crf=16 --color-space=bt709 --muted \
  --concurrency="${CONCURRENCY:-4}"
ffmpeg -y -v error -i "$M/demo.mp4" -i out/audio/demo-master.wav -map 0:v -map 1:a -c:v copy \
  -af "alimiter=limit=0.813:attack=2:release=60:level=false" -c:a aac -b:a 256k -ar 48000 -movflags +faststart \
  "$D/$NAME.mp4"
# a light preview for sharing: CRF 20 capped at 8 Mbps, same audio
ffmpeg -y -v error -i "$D/$NAME.mp4" -c:v libx264 -preset slow -crf 20 -maxrate 8M -bufsize 16M -pix_fmt yuv420p \
  -color_primaries bt709 -color_trc bt709 -colorspace bt709 -c:a copy -movflags +faststart "$D/${NAME}_preview.mp4"
node scripts/check-demo.ts
