#!/usr/bin/env bash

# エラー、未定義変数、パイプ途中の失敗を見逃さず、安全側で停止する。
set -euo pipefail

# このスクリプト自身の配置場所を dotfiles のルートとして扱う。
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

info() {
  printf '[dotfiles] %s\n' "$*"
}

fail() {
  printf '[dotfiles] ERROR: %s\n' "$*" >&2
  exit 1
}

# VS Code の現在の extension 状態を復元用 manifest として保存する。
# settings / keybindings は symlink で直接 repository を参照しているため、
# sync の対象にしない。
sync_vscode_extensions() {
  local extensions_file="$DOTFILES_DIR/.config/vscode/extensions.txt"
  local vscode_cli=''
  local tmp_file

  if command -v code >/dev/null 2>&1; then
    vscode_cli="$(command -v code)"
  elif [[ -x '/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code' ]]; then
    vscode_cli='/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code'
  else
    fail 'VS Code CLI was not found'
  fi

  mkdir -p "$(dirname "$extensions_file")"
  tmp_file="$(mktemp)"
  trap 'rm -f "$tmp_file"' EXIT

  {
    printf '# VS Code extension IDs, one per line.\n'
    "$vscode_cli" --list-extensions | LC_ALL=C sort -u
  } > "$tmp_file"

  mv "$tmp_file" "$extensions_file"
  trap - EXIT

  info "synced VS Code extensions to $extensions_file"
}

main() {
  sync_vscode_extensions
  info 'sync complete'
}

main "$@"
