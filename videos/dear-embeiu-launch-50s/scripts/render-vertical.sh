#!/usr/bin/env bash
# The 9:16 cut (composition "Vertical", VERTICAL.md): soundtrack → picture (H.264, CRF 16, muted) → mux with the master
# (AAC 256k behind a −1.8 dBFS limiter: AAC overshoots the PCM true peak) → a ≤ 9.5 MB copy for browser upload
# (1080p30, two-pass) → the poster (last frame) → technical check.
# Usage (project root): bash scripts/render-vertical.sh        CONCURRENCY=n to change the number of Chrome tabs (≤ 4).
set -euo pipefail
cd "$(dirname "$0")/.."
NAME=dear-embeiu-vertical-20s
D=out/deliver
M=out/master
mkdir -p "$D" "$M"

node audio/vertical/build.ts
npx remotion render src/index.ts Vertical "$M/vertical.mp4" --codec=h264 --crf=16 --color-space=bt709 --muted \
  --concurrency="${CONCURRENCY:-4}"
ffmpeg -y -v error -i "$M/vertical.mp4" -i out/audio/vertical-master.wav -map 0:v -map 1:a -c:v copy \
  -af "alimiter=limit=0.813:attack=2:release=60:level=false" -c:a aac -b:a 256k -ar 48000 -movflags +faststart \
  "$D/$NAME.mp4"
# ≤ 9.5 MB for uploading through the browser bridge (10 MB cap): 30 fps, two-pass ≈ 3.3 Mbps video + 160k audio
P="$M/vertical-x264"
ffmpeg -y -v error -i "$D/$NAME.mp4" -vf fps=30 -c:v libx264 -preset slow -tune animation -b:v 3300k -maxrate 6000k \
  -bufsize 6000k -pass 1 -passlogfile "$P" -an -f mp4 /dev/null
# audio straight from the PCM master through the same limiter (re-encoding the AAC overshoots the true peak)
ffmpeg -y -v error -i "$D/$NAME.mp4" -i out/audio/vertical-master.wav -map 0:v -map 1:a -vf fps=30 -c:v libx264 \
  -preset slow -tune animation -b:v 3300k -maxrate 6000k -bufsize 6000k -pass 2 -passlogfile "$P" -pix_fmt yuv420p \
  -color_primaries bt709 -color_trc bt709 -colorspace bt709 \
  -af "alimiter=limit=0.813:attack=2:release=60:level=false" -c:a aac -b:a 160k -ar 48000 -movflags +faststart \
  "$D/${NAME}_threads.mp4"
rm -f "$P"*.log*
npx remotion still src/index.ts Vertical "$D/${NAME}_poster.png" --frame=1199
node scripts/check-vertical.ts
