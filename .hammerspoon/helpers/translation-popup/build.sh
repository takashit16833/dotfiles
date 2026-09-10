#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_ROOT="${TMPDIR:-/tmp}/dotfiles-translation-popup"
APP_DIR="$BUILD_ROOT/TranslationPopup.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
EXECUTABLE="$MACOS_DIR/TranslationPopup"

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR"

cat > "$CONTENTS_DIR/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>TranslationPopup</string>
  <key>CFBundleIdentifier</key>
  <string>local.dotfiles.translation-popup</string>
  <key>CFBundleName</key>
  <string>TranslationPopup</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSHighResolutionCapable</key>
  <true/>
</dict>
</plist>
PLIST

xcrun swiftc \
  -parse-as-library \
  -framework AppKit \
  -framework SwiftUI \
  -framework Translation \
  "$SCRIPT_DIR/TranslationPopup.swift" \
  -o "$EXECUTABLE"

# The app is built locally and has no distribution identity; an ad-hoc signature
# is enough for this experiment and avoids treating the bundle as malformed.
codesign --force --sign - "$APP_DIR" >/dev/null

printf '%s\n' "$APP_DIR"
