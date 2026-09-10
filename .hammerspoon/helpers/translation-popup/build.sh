#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_ROOT="${1:-$HOME/.local/share/dotfiles/translation-popup}"
INSTALLED_APP="$INSTALL_ROOT/TranslationPopup.app"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-translation-popup.XXXXXX")"
APP_DIR="$TMP_ROOT/TranslationPopup.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
EXECUTABLE="$MACOS_DIR/TranslationPopup"

cleanup() {
  rm -rf "$TMP_ROOT"
}
trap cleanup EXIT

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

# ローカル利用専用なので ad-hoc 署名を付ける。
codesign --force --sign - "$APP_DIR" >/dev/null

# ビルド成功後だけ既存 helper を置き換え、失敗時は動作中の版を残す。
mkdir -p "$INSTALL_ROOT"
rm -rf "$INSTALLED_APP"
mv "$APP_DIR" "$INSTALLED_APP"

printf '%s\n' "$INSTALLED_APP"
