#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

info() {
  printf '[dotfiles] %s\n' "$*"
}

fail() {
  printf '[dotfiles] ERROR: %s\n' "$*" >&2
  exit 1
}

ensure_symlink() {
  local source="$1"
  local target="$2"

  mkdir -p "$(dirname "$target")"

  if [[ -L "$target" ]]; then
    local current
    current="$(readlink "$target")"

    if [[ "$current" == "$source" ]]; then
      info "already linked: $target -> $source"
      return
    fi

    fail "$target is already a symlink to $current; leaving it untouched"
  fi

  if [[ -e "$target" ]]; then
    fail "$target already exists and is not a symlink; leaving it untouched"
  fi

  ln -s "$source" "$target"
  info "linked: $target -> $source"
}

main() {
  info "installing from $DOTFILES_DIR"

  ensure_symlink \
    "$DOTFILES_DIR/.config/wezterm" \
    "$CONFIG_HOME/wezterm"

  info 'install complete'
}

main "$@"
