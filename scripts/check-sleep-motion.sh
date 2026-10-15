#!/bin/bash
# Feature sleep (motion fallback): compile ios/Runner/MotionSpanBuilder.swift with
# the check harness as a plain macOS binary and run it. No Xcode project, no simulator.
set -euo pipefail
cd "$(dirname "$0")/.."
OUT="$(mktemp -d)/motion"
trap 'rm -rf "$(dirname "$OUT")"' EXIT
xcrun swiftc -O ios/Runner/MotionSpanBuilder.swift scripts/sleep-motion-check/main.swift -o "$OUT"
"$OUT"
