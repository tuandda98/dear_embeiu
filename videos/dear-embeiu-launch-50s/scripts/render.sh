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
# AAC overshoots the PCM master's true peak by ~0.8 dB, so the lossy path gets a −1.8 dBTP ceiling first (loudness
# moves < 0.1 LU: only the few peaks are touched)
ffmpeg -y -v error -i "$D/${NAME}_prores422hq.mov" -c:v libx264 -preset slow -profile:v high -pix_fmt yuv420p \
  -b:v 24M -minrate 24M -maxrate 24M -bufsize 24M -x264-params nal-hrd=cbr \
  -color_primaries bt709 -color_trc bt709 -colorspace bt709 \
  -af "alimiter=limit=0.813:attack=2:release=60:level=false" -c:a aac -b:a 320k -ar 48000 -movflags +faststart \
  "$D/${NAME}_h264.mp4"
# a light preview for sharing (not a brief deliverable): 8 Mbps, same audio
ffmpeg -y -v error -i "$D/${NAME}_h264.mp4" -c:v libx264 -preset slow -crf 20 -maxrate 8M -bufsize 16M -pix_fmt yuv420p \
  -color_primaries bt709 -color_trc bt709 -colorspace bt709 -c:a copy -movflags +faststart "$D/${NAME}_preview.mp4"
node scripts/check-delivery.ts
