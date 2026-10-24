#!/usr/bin/env bash
# per-act loudness of a wav: bash scripts/loud.sh out/audio/master.wav
f=${1:-out/audio/master.wav}
for seg in "A1 0 4" "A2 4 8" "A3 12 8" "A4 20 12" "A5 32 6" "A6 38 6" "A7 44 6"; do
  set -- $seg
  r=$(ffmpeg -hide_banner -nostats -ss $2 -t $3 -i "$f" -af ebur128=peak=true -f null - 2>&1 | grep -E "I:|Peak:" | tail -2 | tr -s ' ' | tr '\n' ' ')
  echo "$1 ($2s +$3s): $r"
done
