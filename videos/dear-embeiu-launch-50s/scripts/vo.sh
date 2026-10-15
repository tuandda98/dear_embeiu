#!/usr/bin/env bash
# Render the voice-over lines of src/copy/vo.ts with edge-tts (vi-VN-HoaiMyNeural) to public/vo/<set>/<id>.mp3 + .wav
# (48 kHz mono) and write public/vo/<set>/index.json {id, at, file, duration}. Usage (project root):
#   scripts/vo.sh film|demo [rate]      e.g. scripts/vo.sh film -3%
set -euo pipefail
cd "$(dirname "$0")/.."
SET="${1:-film}"; RATE="${2:--3%}"
EDGE="${EDGE_TTS:-/private/tmp/claude-501/-Users-dodaoanhtuan/c7eb350e-e3b6-4bdd-bcfb-0e3f3e0d07e8/scratchpad/venv-tts/bin/edge-tts}"
VOICE="${VO_VOICE:-vi-VN-HoaiMyNeural}"
OUT="public/vo/$SET"
mkdir -p "$OUT"
node --input-type=module -e "
import { FILM_VO, DEMO_VO } from './src/copy/vo.ts';
const lines = '$SET' === 'film' ? FILM_VO : DEMO_VO;
console.log(JSON.stringify(lines));
" > "$OUT/lines.json"
python3 - "$OUT" "$EDGE" "$VOICE" "$RATE" <<'EOF'
import json, subprocess, sys, os, time
out, edge, voice, rate = sys.argv[1:5]
lines = json.load(open(f"{out}/lines.json"))
index = []
for l in lines:
    mp3 = f"{out}/{l['id']}.mp3"; wav = f"{out}/{l['id']}.wav"
    if os.path.exists(mp3) and os.path.getsize(mp3) < 1000: os.remove(mp3)  # a failed download leaves a stub
    if not os.path.exists(mp3):
        for attempt in range(6):  # edge-tts drops connections now and then: retry with a pause
            r = subprocess.run([edge, "--voice", voice, f"--rate={rate}", "--text", l["text"], "--write-media", mp3], capture_output=True, text=True)
            if r.returncode == 0 and os.path.exists(mp3) and os.path.getsize(mp3) > 1000: break
            if os.path.exists(mp3): os.remove(mp3)
            time.sleep(2 + 2 * attempt)
        else:
            raise SystemExit(f"edge-tts failed 6 times on {l['id']}")
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", mp3, "-af", "silenceremove=start_periods=1:start_threshold=-45dB,areverse,silenceremove=start_periods=1:start_threshold=-45dB,areverse", "-ar", "48000", "-ac", "1", "-c:a", "pcm_s16le", wav], check=True)
    d = float(subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", wav], capture_output=True, text=True).stdout.strip())
    index.append({"id": l["id"], "at": l["at"], "file": f"vo/{os.path.basename(out)}/{l['id']}.wav", "duration": round(d, 3)})
    print(f"{l['id']:14s} at {l['at']:5d}  {d:5.2f} s  ends {l['at'] + d*60:7.0f}  | {l['text']}")
for a, b in zip(index, index[1:]):
    end = a["at"] + a["duration"] * 60
    if end > b["at"]: print(f"OVERLAP: {a['id']} ends at f{end:.0f} but {b['id']} starts at f{b['at']}")
json.dump(index, open(f"{out}/index.json", "w"), ensure_ascii=False, indent=1)
EOF
