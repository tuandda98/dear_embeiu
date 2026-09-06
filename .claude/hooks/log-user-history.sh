#!/usr/bin/env bash
# Append the user's activity to project/USER_HISTORY.md.
# Registered for BOTH hook events in .claude/settings.json:
#   - SessionStart     → writes a "phiên mới" marker (mỗi khi mở Claude lên)
#   - UserPromptSubmit  → writes the user's prompt (mỗi khi bắt Claude làm gì)
# Pure logging: always exits 0, NEVER blocks the prompt. The event type is read
# from the hook JSON on stdin (`hook_event_name`), so one script covers both.
set -u
ROOT="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
OUT="$ROOT/project/USER_HISTORY.md"

python3 -c '
import sys, json, datetime
out = sys.argv[1]
try:
    d = json.load(sys.stdin)
except Exception:
    d = {}
ev = d.get("hook_event_name", "")
now = datetime.datetime.now()
ts = now.strftime("%Y-%m-%d %H:%M:%S")
line = ""
if ev == "SessionStart":
    src = d.get("source", "")
    line = "\n\n---\n## Phien moi - " + ts + ((" (source: " + str(src) + ")") if src else "") + "\n"
elif ev == "UserPromptSubmit":
    p = (d.get("prompt") or "").strip().replace("\r", " ").replace("\n", " ")
    if len(p) > 600:
        p = p[:600] + " ...[cat]"
    if p:
        line = "- [" + now.strftime("%H:%M") + "] " + p + "\n"
if line:
    try:
        with open(out, "a", encoding="utf-8") as f:
            f.write(line)
    except Exception:
        pass
' "$OUT"

exit 0
