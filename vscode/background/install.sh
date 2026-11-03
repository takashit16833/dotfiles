#!/usr/bin/env bash
set -euo pipefail

# 共通 CSS は dotfiles から参照し、画像の場所は端末ごとの設定に分ける。
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config/vscode"
SOURCE="$SCRIPT_DIR/wallpaper.css"
TARGET="$CONFIG_DIR/wallpaper.css"
LOCAL="$CONFIG_DIR/wallpaper-local.css"
TEMPLATE="$SCRIPT_DIR/wallpaper-local.example.css"

[[ -f "$SOURCE" && -f "$TEMPLATE" ]] || {
  printf '[vscode-background] ERROR: stylesheet or template was not found\n' >&2
  exit 1
}

mkdir -p "$CONFIG_DIR"
if [[ -L "$TARGET" ]]; then
  if [[ "$(readlink "$TARGET")" != "$SOURCE" ]]; then
    printf '[vscode-background] ERROR: not overwriting another symlink: %s\n' "$TARGET" >&2
    exit 1
  fi
elif [[ -e "$TARGET" ]]; then
  printf '[vscode-background] ERROR: not overwriting existing file: %s\n' "$TARGET" >&2
  exit 1
else
  ln -s "$SOURCE" "$TARGET"
fi

if [[ ! -e "$LOCAL" && ! -L "$LOCAL" ]]; then
  cp "$TEMPLATE" "$LOCAL"
  printf '[vscode-background] Created local settings: %s\n' "$LOCAL"
fi
printf '[vscode-background] Configured stylesheet: %s\n' "$TARGET"
