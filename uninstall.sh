#!/usr/bin/env bash

# エラー、未定義変数、パイプ途中の失敗を見逃さず、安全側で停止する。
set -euo pipefail

# このスクリプト自身の配置場所を dotfiles のルートとして扱う。
# ~/dotfiles 以外へ clone しても動作するよう、HOME にパスを固定しない。
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# XDG_CONFIG_HOME が設定されていれば尊重し、未設定なら ~/.config を利用する。
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

# Lazygit は macOS では ~/Library/Application Support/lazygit を標準で利用する。
# XDG_CONFIG_HOME が明示されている場合だけ、その配下の lazygit を利用する。
if [[ -n "${XDG_CONFIG_HOME:-}" ]]; then
  LAZYGIT_CONFIG_HOME="$XDG_CONFIG_HOME/lazygit"
else
  LAZYGIT_CONFIG_HOME="$HOME/Library/Application Support/lazygit"
fi

# 通常の進捗メッセージを統一した形式で表示する。
info() {
  printf '[dotfiles] %s\n' "$*"
}

# この dotfiles repository が作成したシンボリックリンクだけを冪等に削除する。
#
# 方針:
# - target が存在しなければ何もしない。
# - target が実ファイル/実ディレクトリなら触らない。
# - 別の場所を指すシンボリックリンクも触らない。
# - source を指している場合だけリンクそのものを削除する。
remove_symlink() {
  local source="$1"
  local target="$2"

  if [[ ! -e "$target" && ! -L "$target" ]]; then
    info "already absent: $target"
    return
  fi

  if [[ ! -L "$target" ]]; then
    info "skip: $target exists but is not a symlink"
    return
  fi

  local current
  current="$(readlink "$target")"

  if [[ "$current" != "$source" ]]; then
    info "skip: $target points to $current, not this dotfiles repository"
    return
  fi

  rm "$target"
  info "removed: $target"
}

main() {
  info "uninstalling links created from $DOTFILES_DIR"

  # WezTerm の設定本体は dotfiles 側に残し、HOME 側のリンクだけ解除する。
  remove_symlink \
    "$DOTFILES_DIR/.config/wezterm" \
    "$CONFIG_HOME/wezterm"

  # Starship の設定本体も repository 側に残し、HOME 側のリンクだけ解除する。
  remove_symlink \
    "$DOTFILES_DIR/.config/starship.toml" \
    "$CONFIG_HOME/starship.toml"

  # Lazygit の設定本体も repository 側に残し、macOS 側の config.yml のリンクだけ解除する。
  remove_symlink \
    "$DOTFILES_DIR/.config/lazygit/config.yml" \
    "$LAZYGIT_CONFIG_HOME/config.yml"

  # Homebrew の login shell 設定は repository 側に残し、~/.zprofile のリンクだけ解除する。
  remove_symlink \
    "$DOTFILES_DIR/.zprofile" \
    "$HOME/.zprofile"

  # zsh の設定本体は repository 側に残し、~/.zshrc のリンクだけ解除する。
  remove_symlink \
    "$DOTFILES_DIR/.zshrc" \
    "$HOME/.zshrc"

  # Hammerspoon の設定本体も repository 側に残し、~/.hammerspoon のリンクだけ解除する。
  remove_symlink \
    "$DOTFILES_DIR/.hammerspoon" \
    "$HOME/.hammerspoon"

  info 'uninstall complete'
}

main "$@"
