#!/usr/bin/env bash
# Build and install the locally managed Markdown preview extension.
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
  printf '[dotfiles] ERROR: npm is needed to package the Markdown preview extension\n' >&2
  exit 1
fi

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
VSIX="$TMP_DIR/markdown-outline-preview.vsix"

(
  cd "$EXTENSION_DIR"
  # Version-pinned packaging tool; no runtime npm dependencies in the extension.
  npx --yes @vscode/vsce@4.0.0 package --no-dependencies --skip-license --out "$VSIX"
)

"$VSCODE_CLI" --install-extension "$VSIX" --force
printf '[dotfiles] Markdown Outline Preview installed; reload VS Code to apply changes\n'
