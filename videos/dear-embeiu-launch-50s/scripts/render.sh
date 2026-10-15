#!/usr/bin/env bash
# Final delivery (brief §3): ProRes 422 HQ master with 24-bit PCM, H.264 MP4 ≥ 20 Mbps, music + SFX stems,
# poster PNG (f2999) and the SRT of the on-screen text, then a technical check of every file.
# Usage (project root): bash scripts/render.sh        CONCURRENCY=n to change the number of Chrome tabs.
set -euo pipefail
cd "$(dirname "$0")/.."
NAME=dear-embeiu-launch-50s
D=out/deliver
M=out/master
mkdir -p "$D/stems" "$M"

node audio/build.ts
node scripts/srt.ts
npx remotion render src/index.ts Film "$M/picture.mov" --codec=prores --prores-profile=hq --color-space=bt709 \
  --muted --concurrency="${CONCURRENCY:-4}"
npx remotion still src/index.ts Film "$D/${NAME}_poster.png" --frame=2999 --image-format=png
ffmpeg -y -v error -i "$M/picture.mov" -i out/audio/master.wav -map 0:v -map 1:a -c:v copy -c:a pcm_s24le \
  "$D/${NAME}_prores422hq.mov"
# CBR with HRD filler: the dark, flat frames are lossless (QP < 1) at about 8 Mbps, so a VBR encode can land under
# the brief's 20 Mbps floor; constant 24 Mbps keeps every second at or above it
ffmpeg -y -v error -i "$D/${NAME}_prores422hq.mov" -c:v libx264 -preset slow -profile:v high -pix_fmt yuv420p \
  -b:v 24M -minrate 24M -maxrate 24M -bufsize 24M -x264-params nal-hrd=cbr \
  -color_primaries bt709 -color_trc bt709 -colorspace bt709 -c:a aac -b:a 320k -ar 48000 -movflags +faststart \
  "$D/${NAME}_h264.mp4"
node scripts/check-delivery.ts
