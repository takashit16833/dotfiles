#!/usr/bin/env bash

# エラー、未定義変数、パイプ途中の失敗を見逃さず、安全側で停止する。
set -euo pipefail

# このスクリプト自身の配置場所を dotfiles のルートとして扱う。
# ~/dotfiles 以外へ clone しても動作するよう、HOME にパスを固定しない。
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# install.sh / .zshenv と同じく、設定ファイルは ~/.config 配下に統一する。
XDG_CONFIG_HOME="$HOME/.config"

# VS Code の macOS 標準 User directory。
VSCODE_USER_DIR="$HOME/Library/Application Support/Code/User"

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

  # WezTerm の設定本体は dotfiles 側に残し、XDG_CONFIG_HOME 側のリンクだけ解除する。
  remove_symlink \
    "$DOTFILES_DIR/.config/wezterm" \
    "$XDG_CONFIG_HOME/wezterm"

  # Starship の設定本体も repository 側に残し、リンクだけ解除する。
  remove_symlink \
    "$DOTFILES_DIR/.config/starship.toml" \
    "$XDG_CONFIG_HOME/starship.toml"

  # Lazygit の設定本体も repository 側に残し、XDG_CONFIG_HOME 側のリンクだけ解除する。
  remove_symlink \
    "$DOTFILES_DIR/.config/lazygit/config.yml" \
    "$XDG_CONFIG_HOME/lazygit/config.yml"

  # Yazi の portable な設定だけ解除する。
  # plugin、package.toml、vfs.toml などのローカル状態は削除しない。
  remove_symlink \
    "$DOTFILES_DIR/.config/yazi/yazi.toml" \
    "$XDG_CONFIG_HOME/yazi/yazi.toml"

  remove_symlink \
    "$DOTFILES_DIR/.config/yazi/keymap.toml" \
    "$XDG_CONFIG_HOME/yazi/keymap.toml"

  # Git の portable な global 設定本体は repository 側に残し、~/.gitconfig のリンクだけ解除する。
  remove_symlink \
    "$DOTFILES_DIR/.gitconfig" \
    "$HOME/.gitconfig"

  # zsh の bootstrap link と XDG_CONFIG_HOME 配下の設定ディレクトリを解除する。
  remove_symlink \
    "$DOTFILES_DIR/.config/zsh/.zshenv" \
    "$HOME/.zshenv"

  remove_symlink \
    "$DOTFILES_DIR/.config/zsh" \
    "$XDG_CONFIG_HOME/zsh"

  # VS Code の user settings / keybindings は repository 側に残し、symlink だけ解除する。
  # extensions.txt から導入した extension 自体は uninstall.sh では削除しない。
  remove_symlink \
    "$DOTFILES_DIR/.config/vscode/settings.json" \
    "$VSCODE_USER_DIR/settings.json"

  remove_symlink \
    "$DOTFILES_DIR/.config/vscode/keybindings.json" \
    "$VSCODE_USER_DIR/keybindings.json"

  # Hammerspoon の設定本体も repository 側に残し、~/.hammerspoon のリンクだけ解除する。
  remove_symlink \
    "$DOTFILES_DIR/.hammerspoon" \
    "$HOME/.hammerspoon"

  info 'uninstall complete'
}

main "$@"
