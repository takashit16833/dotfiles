#!/usr/bin/env bash

# エラー、未定義変数、パイプ途中の失敗を見逃さず、安全側で停止する。
set -euo pipefail

# このスクリプト自身の配置場所を dotfiles のルートとして扱う。
# ~/dotfiles 以外へ clone しても動作するよう、HOME にパスを固定しない。
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# この dotfiles では XDG_CONFIG_HOME を ~/.config に固定する。
# zsh の .zshenv でも同じ値を export し、設定ファイルの配置規則を統一する。
XDG_CONFIG_HOME="$HOME/.config"

# 通常の進捗メッセージを統一した形式で表示する。
info() {
  printf '[dotfiles] %s\n' "$*"
}

# 安全に続行できない場合は理由を表示して終了する。
fail() {
  printf '[dotfiles] ERROR: %s\n' "$*" >&2
  exit 1
}

# Brewfile に宣言した macOS 用ツールを Homebrew で揃える。
#
# 方針:
# - Homebrew 自体は事前に導入済みであることを前提にする。
# - package の一覧は install.sh に直書きせず、Brewfile を正本にする。
# - --no-upgrade により、install.sh 実行のたびに既存 package を
#   むやみに upgrade しない。不足している package だけを導入する。
install_homebrew_packages() {
  if [[ "$(uname -s)" != "Darwin" ]]; then
    fail 'this installer currently supports macOS only'
  fi

  if ! command -v brew >/dev/null 2>&1; then
    fail 'Homebrew is not installed; install Homebrew before running this script'
  fi

  if [[ ! -f "$DOTFILES_DIR/Brewfile" ]]; then
    fail "$DOTFILES_DIR/Brewfile does not exist"
  fi

  info 'installing Homebrew packages from Brewfile'
  brew bundle --file="$DOTFILES_DIR/Brewfile" --no-upgrade
}

# source を target から参照するシンボリックリンクを冪等に作成する。
#
# 方針:
# - すでに正しいリンクなら何もしない。
# - 別のリンクや実ファイルが存在する場合は、勝手に上書きしない。
# - target の親ディレクトリだけは必要に応じて作成する。
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

  # まず実行に必要な CLI / application を揃え、その後に設定ファイルをリンクする。
  # これにより、新しい Mac でも install.sh ひとつで同じ順序で環境を構築できる。
  install_homebrew_packages

  # WezTerm は XDG_CONFIG_HOME/wezterm/wezterm.lua を読むため、
  # ディレクトリ単位で dotfiles 側の設定へリンクする。
  ensure_symlink \
    "$DOTFILES_DIR/.config/wezterm" \
    "$XDG_CONFIG_HOME/wezterm"

  # Starship は XDG_CONFIG_HOME/starship.toml を標準の設定ファイルとして読む。
  # 設定本体は repository 側を正本にし、HOME 側にはファイルのリンクだけ置く。
  ensure_symlink \
    "$DOTFILES_DIR/.config/starship.toml" \
    "$XDG_CONFIG_HOME/starship.toml"

  # Lazygit も XDG_CONFIG_HOME 配下へ統一する。
  ensure_symlink \
    "$DOTFILES_DIR/.config/lazygit/config.yml" \
    "$XDG_CONFIG_HOME/lazygit/config.yml"

  # Git の portable な global 設定を repository 側で管理する。
  # user.name / user.email / 認証は ~/.gitconfig.local など Mac 側へ分離する。
  ensure_symlink \
    "$DOTFILES_DIR/.gitconfig" \
    "$HOME/.gitconfig"

  # zsh が ZDOTDIR を知る前にも .zshenv を読めるよう、HOME 直下には
  # .config/zsh/.zshenv への bootstrap link だけを置く。
  ensure_symlink \
    "$DOTFILES_DIR/.config/zsh/.zshenv" \
    "$HOME/.zshenv"

  # .zprofile / .zshrc を含む zsh の startup file は XDG_CONFIG_HOME 配下へ集約する。
  ensure_symlink \
    "$DOTFILES_DIR/.config/zsh" \
    "$XDG_CONFIG_HOME/zsh"

  # Hammerspoon は ~/.hammerspoon/init.lua を設定として読むため、
  # 設定ディレクトリ全体を dotfiles 側へリンクする。
  ensure_symlink \
    "$DOTFILES_DIR/.hammerspoon" \
    "$HOME/.hammerspoon"

  info 'install complete'
}

main "$@"
