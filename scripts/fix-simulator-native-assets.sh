#!/usr/bin/env bash
# fix-simulator-native-assets.sh
#
# Workaround: Flutter 3.22+ bug — khi `flutter run` build cho iOS simulator,
# native_assets hooks không nhận được SdkRoot → objective_c.framework bị
# compile cho device (platform iphoneos) thay vì iphonesimulator → crash
# "DOBJC_initializeApi / objective_c.dylib not found".
#
# Script này tự compile objective_c.framework đúng cho simulator.
# Chạy trước `flutter run` hoặc sau `flutter clean`.
#
# Usage:
#   ./scripts/fix-simulator-native-assets.sh            # auto-detect version
#   ./scripts/fix-simulator-native-assets.sh --force    # force recompile dù đúng rồi

set -euo pipefail

FORCE=false
[[ "${1:-}" == "--force" ]] && FORCE=true

# ── Detect objective_c package version from pubspec.lock ──────────────────────
PUBSPEC_LOCK="$(cd "$(dirname "$0")/.." && pwd)/pubspec.lock"
if [[ ! -f "$PUBSPEC_LOCK" ]]; then
  echo "❌ pubspec.lock not found. Run flutter pub get first." >&2
  exit 1
fi

PKG_VERSION=$(awk '/^  objective_c:/{found=1} found && /version:/{gsub(/[^0-9.]/, "", $2); print $2; exit}' "$PUBSPEC_LOCK")
if [[ -z "$PKG_VERSION" ]]; then
  echo "❌ Could not find objective_c version in pubspec.lock" >&2
  exit 1
fi

# Locate the package src under whichever pub host mirror cached it. Packages may
# come from pub.dev OR a mirror (e.g. pub.flutter-io.cn) depending on
# PUB_HOSTED_URL at `pub get` time — the lock records the mirror url, and the
# cache lands in hosted/<mirror>/ not hosted/pub.dev/. Search all hosts and
# respect PUB_CACHE if the env overrides the default location.
PUB_CACHE_DIR="${PUB_CACHE:-$HOME/.pub-cache}"
SRC_DIR=""
for cand in "$PUB_CACHE_DIR"/hosted/*/objective_c-"${PKG_VERSION}"/src; do
  if [[ -d "$cand" ]]; then SRC_DIR="$cand"; break; fi
done
if [[ -z "$SRC_DIR" ]]; then
  echo "❌ Source not found under $PUB_CACHE_DIR/hosted/*/objective_c-${PKG_VERSION}/src" >&2
  echo "   Run: flutter pub get" >&2
  exit 1
fi

# ── Target paths ───────────────────────────────────────────────────────────────
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
FRAMEWORK_DIR="$PROJECT_DIR/build/native_assets/ios/objective_c.framework"
BINARY="$FRAMEWORK_DIR/objective_c"

# ── Check if already correct ───────────────────────────────────────────────────
if [[ "$FORCE" == false && -f "$BINARY" ]]; then
  PLATFORM=$(otool -l "$BINARY" 2>/dev/null \
    | awk '/LC_BUILD_VERSION/{f=1} f && /platform/{print $2; exit}')
  if [[ "$PLATFORM" == "7" ]]; then
    echo "✓ objective_c.framework đã đúng platform (7 = iphonesimulator). Bỏ qua."
    exit 0
  fi
  echo "⚠️  Phát hiện binary sai platform ($PLATFORM, cần 7). Compile lại..."
else
  [[ "$FORCE" == true ]] && echo "🔄 --force: compile lại..." || echo "📦 objective_c.framework chưa có. Compile..."
fi

# ── Setup ─────────────────────────────────────────────────────────────────────
SIM_SDK=$(xcrun --show-sdk-path --sdk iphonesimulator 2>/dev/null)
CLANG=$(xcrun --sdk iphonesimulator --find clang 2>/dev/null)
TMPDIR_OBJ=$(mktemp -d)
trap 'rm -rf "$TMPDIR_OBJ"' EXIT

mkdir -p "$FRAMEWORK_DIR"

CFLAGS=(
  -isysroot "$SIM_SDK"
  -target arm64-apple-ios13.0-simulator
  -mios-simulator-version-min=13.0
  -fpic
  -gline-tables-only
  -I"$SRC_DIR"
  -I"$SRC_DIR/include"
)

echo "   objective_c version : $PKG_VERSION"
echo "   sysroot              : $SIM_SDK"

# ── Compile all .c files (recursive: src/ + src/include/) ──────────────────────
OBJECTS=()
while IFS= read -r -d '' src; do
  rel="${src#"$SRC_DIR/"}"
  out="$TMPDIR_OBJ/$(echo "$rel" | tr '/' '_').o"
  echo "   compile: $rel"
  "$CLANG" "${CFLAGS[@]}" -c "$src" -o "$out"
  OBJECTS+=("$out")
done < <(find "$SRC_DIR" -name "*.c" -print0)

# ── Compile all .m files ────────────────────────────────────────────────────────
while IFS= read -r -d '' src; do
  rel="${src#"$SRC_DIR/"}"
  out="$TMPDIR_OBJ/$(echo "$rel" | tr '/' '_').o"
  echo "   compile: $rel"
  "$CLANG" "${CFLAGS[@]}" -x objective-c -fobjc-arc -c "$src" -o "$out"
  OBJECTS+=("$out")
done < <(find "$SRC_DIR" -name "*.m" -print0)

# ── Link ────────────────────────────────────────────────────────────────────────
echo "   linking..."
"$CLANG" \
  -isysroot "$SIM_SDK" \
  -target arm64-apple-ios13.0-simulator \
  -mios-simulator-version-min=13.0 \
  -dynamiclib \
  -install_name "@rpath/objective_c.framework/objective_c" \
  -undefined dynamic_lookup \
  -framework Foundation \
  "${OBJECTS[@]}" \
  -o "$BINARY" 2>&1 | grep -v "deprecated on iOS-simulator" || true

# ── Write Info.plist ────────────────────────────────────────────────────────────
cat > "$FRAMEWORK_DIR/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>objective_c</string>
    <key>CFBundleIdentifier</key>
    <string>dev.dart.objective-c</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>objective_c</string>
    <key>CFBundlePackageType</key>
    <string>FMWK</string>
    <key>CFBundleShortVersionString</key>
    <string>${PKG_VERSION}</string>
    <key>CFBundleVersion</key>
    <string>${PKG_VERSION}</string>
    <key>MinimumOSVersion</key>
    <string>13.0</string>
</dict>
</plist>
EOF

# ── Verify ──────────────────────────────────────────────────────────────────────
PLATFORM=$(otool -l "$BINARY" 2>/dev/null \
  | awk '/LC_BUILD_VERSION/{f=1} f && /platform/{print $2; exit}')
DL_SYM=$(nm "$BINARY" 2>/dev/null | grep -c "Dart_CurrentIsolate_DL" || true)

if [[ "$PLATFORM" == "7" && "$DL_SYM" -gt 0 ]]; then
  echo "✅ objective_c.framework compiled for iphonesimulator (platform 7)"
  echo "   path: $BINARY"
else
  echo "❌ Verify failed (platform=$PLATFORM, DL_SYM=$DL_SYM)" >&2
  exit 1
fi
