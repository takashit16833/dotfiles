#!/usr/bin/env bash
# Install the dotfiles-managed CSS into Markdown Live Preview Editor's styles.
set -euo pipefail

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# VS Code stable on macOS. Override for a different user-data directory.
USER_DIR="${VSCODE_USER_DATA_DIR:-$HOME/Library/Application Support/Code/User}"
STYLES_DIR="$USER_DIR/globalStorage/t-shoot.markdown-live-preview-editor/styles"
TARGET="$STYLES_DIR/retro-hacker-blue.css"

if [[ ! -d "$USER_DIR" ]]; then
  printf '[dotfiles] VS Code user directory not found: %s\n' "$USER_DIR" >&2
  exit 1
fi

mkdir -p "$STYLES_DIR"
if [[ -L "$TARGET" ]] || { [[ -e "$TARGET" ]] && ! grep -Fq \
  'Managed from dotfiles: vscode/markdown-live-preview/retro-hacker-blue.css' "$TARGET"; }; then
  printf '[dotfiles] Refusing to overwrite an unmanaged CSS file: %s\n' "$TARGET" >&2
  exit 1
fi

cp "$SOURCE_DIR/retro-hacker-blue.css" "$TARGET"
printf '[dotfiles] Markdown Live Preview CSS installed: %s\n' "$TARGET"
printf '[dotfiles] Open a .md file with Markdown Live Preview to compare it with the existing preview.\n'
