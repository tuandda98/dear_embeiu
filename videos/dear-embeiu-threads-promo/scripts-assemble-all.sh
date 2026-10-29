#!/bin/bash
# Ghép trọn: khôi phục video → assemble → transitions → bo góc video hoist → lint.
set -eu
cd "$(dirname "$0")"
S=~/.claude/skills/product-launch-video/scripts
./scripts-restore-videos.sh
node $S/assemble-index.mjs --storyboard ./STORYBOARD.md --hyperframes . 2>&1 | grep -E "wrote|sfx|total duration|anomal|✗|error" || true
node $S/transitions.mjs inject --storyboard ./STORYBOARD.md --hyperframes . 2>&1 | tail -1
node $S/transitions.mjs verify --storyboard ./STORYBOARD.md --index ./index.html 2>&1 | tail -1
./scripts-postfix-index.sh
NODE_OPTIONS=--dns-result-order=ipv4first npx hyperframes lint 2>&1 | tail -1
grep -c "<video" index.html
