#!/bin/bash
# Feature home-widget: compile the widget's DayMath.swift with the check
# harness (scripts/widget-daymath-check/main.swift) as a plain macOS binary and
# run it. No Xcode project, no simulator — a few seconds.
set -euo pipefail
cd "$(dirname "$0")/.."
OUT="$(mktemp -d)/daymath"
xcrun swiftc -O ios/DearEmbeiuWidget/DayMath.swift scripts/widget-daymath-check/main.swift -o "$OUT"
# -AppleLocale th_TH makes Calendar.current Buddhist for this process: the
# default-calendar check only means something under a non-Gregorian locale.
"$OUT" -AppleLocale th_TH
