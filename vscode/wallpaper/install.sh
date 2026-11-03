#!/usr/bin/env bash
# Build and install the isolated preview extension. Does not patch VS Code itself.
set -euo pipefail

EXTENSION_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VSCODE_CLI="${VSCODE_CLI:-}"

if [[ -z "$VSCODE_CLI" ]]; then
  if command -v code >/dev/null 2>&1; then
    VSCODE_CLI="$(command -v code)"
  elif [[ -x '/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code' ]]; then
    VSCODE_CLI='/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code'
  else
    printf '[dotfiles] ERROR: VS Code CLI was not found\n' >&2
    exit 1
  fi
fi

if ! command -v npm >/dev/null 2>&1; then
  printf '[dotfiles] ERROR: npm is required\n' >&2
  exit 1
fi

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
VSIX="$TMP_DIR/vscode-wallpaper.vsix"

(
  cd "$EXTENSION_DIR"
  npm test
  npx --yes @vscode/vsce@4.0.0 package --no-dependencies --skip-license --out "$VSIX"
)

"$VSCODE_CLI" --install-extension "$VSIX" --force
printf '[dotfiles] VS Code Wallpaper preview extension installed. Reload VS Code and run VS Code Wallpaper: Preview.\n'
