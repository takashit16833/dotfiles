#!/usr/bin/env bash
# Build the official 0.5.0 source with dotfiles' minimal outline-indent patch.
set -euo pipefail

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UPSTREAM_COMMIT="b0ce2e0c005ff69e322a840f236e03efc698abf2"
UPSTREAM_URL="https://github.com/t-shoot/md-live-preview-editor.git"
VSCODE_CLI="${VSCODE_CLI:-}"

for cmd in git npm python3; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    printf '[dotfiles] Required command not found: %s\n' "$cmd" >&2
    exit 1
  fi
done
if [[ -z "$VSCODE_CLI" ]]; then
  if command -v code >/dev/null 2>&1; then
    VSCODE_CLI="$(command -v code)"
  elif [[ -x '/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code' ]]; then
    VSCODE_CLI='/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code'
  else
    echo '[dotfiles] VS Code CLI not found' >&2
    exit 1
  fi
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
git clone --quiet "$UPSTREAM_URL" "$TMP/editor"
git -C "$TMP/editor" checkout --quiet --detach "$UPSTREAM_COMMIT"

python3 "$SOURCE_DIR/patch-upstream.py" "$TMP/editor/src/webview-editor/livePreviewPlugin.ts"
cp "$SOURCE_DIR/overlay/outlineIndent.ts" "$TMP/editor/src/webview-editor/outlineIndent.ts"
cp "$SOURCE_DIR/overlay/outlineIndent.test.ts" "$TMP/editor/src/webview-editor/outlineIndent.test.ts"

(
  cd "$TMP/editor"
  npm ci --no-audit --no-fund
  npm run compile
  npm test
  ./node_modules/.bin/vsce package --no-dependencies --skip-license --out "$TMP/markdown-live-preview-rhb.vsix"
)

# The local build deliberately uses the same extension ID as the Marketplace
# version. Run only after compilation and tests have passed.
"$VSCODE_CLI" --install-extension "$TMP/markdown-live-preview-rhb.vsix" --force
bash "$SOURCE_DIR/install.sh"
printf '[dotfiles] Installed Markdown Live Preview with Retro Hacker Blue section indentation.\n'
printf '[dotfiles] Reload the VS Code window, then compare an .md file in both views.\n'
