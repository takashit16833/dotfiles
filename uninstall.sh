#!/usr/bin/env bash

# エラー、未定義変数、パイプ途中の失敗を見逃さず、安全側で停止する。
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
XDG_CONFIG_HOME="$HOME/.config"
LOCAL_BIN_DIR="$HOME/.local/bin"
TRANSLATION_POPUP_DIR="$HOME/.local/share/dotfiles/translation-popup"
VSCODE_USER_DIR="$HOME/Library/Application Support/Code/User"
RAYCAST_EXTENSION_DIR="$DOTFILES_DIR/raycast/extension"
RAYCAST_EXTENSION_NAME="dotfiles-commands"
RAYCAST_INSTALLED_EXTENSIONS_DIR="$HOME/.config/raycast/extensions"

info() {
  printf '[dotfiles] %s\n' "$*"
}

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

remove_path() {
  local target="$1"

  if [[ ! -e "$target" && ! -L "$target" ]]; then
    return
  fi

  rm -rf "$target"
  info "removed: $target"
}

uninstall_managed_scripts() {
  local scripts_dir="$DOTFILES_DIR/scripts/bin"
  local script

  if [[ ! -d "$scripts_dir" ]]; then
    info "managed scripts directory already absent: $scripts_dir"
    return
  fi

  for script in "$scripts_dir"/*; do
    [[ -f "$script" ]] || continue
    remove_symlink "$script" "$LOCAL_BIN_DIR/$(basename "$script")"
  done
}

# install.shが作ったPC固有の設定だけを削除する。
uninstall_wezterm_local_config() {
  local directory="$XDG_CONFIG_HOME/wezterm-local"
  local target="$directory/local.lua"
  local marker="$directory/.dotfiles-created"

  if [[ -L "$directory" ]]; then
    info "skip: $directory is a symlink"
    return
  fi
  if [[ -L "$marker" || ! -f "$marker" ]] ||
    [[ "$(cat "$marker")" != 'created by dotfiles install.sh' ]]; then
    if [[ -e "$target" || -L "$target" ]]; then
      info "skip: $target has no dotfiles ownership marker"
    fi
    return
  fi
  if [[ -L "$target" || ( -e "$target" && ! -f "$target" ) ]]; then
    info "skip: $target is not a regular file"
    return
  fi
  if [[ -f "$target" ]]; then
    rm "$target"
    info "removed: $target"
  fi
  rm "$marker"
  rmdir "$directory" 2>/dev/null || true
}

uninstall_raycast_extension() {
  local install_dir="$RAYCAST_INSTALLED_EXTENSIONS_DIR/$RAYCAST_EXTENSION_NAME"
  local staging_dir

  # repository の source は残し、npm / local build が生成したものだけを片付ける。
  remove_path "$RAYCAST_EXTENSION_DIR/node_modules"
  remove_path "$RAYCAST_EXTENSION_DIR/dist"

  # 旧 installer が管理していた固定 destination と、中断時に残り得る staging directory を削除する。
  if [[ -f "$install_dir/package.json" ]] && command -v jq >/dev/null 2>&1; then
    if [[ "$(jq -r '.name // empty' "$install_dir/package.json" 2>/dev/null || true)" == "$RAYCAST_EXTENSION_NAME" ]]; then
      remove_path "$install_dir"
    else
      info "skip: $install_dir does not identify as $RAYCAST_EXTENSION_NAME"
    fi
  elif [[ -e "$install_dir" || -L "$install_dir" ]]; then
    info "skip: $install_dir exists but could not be verified as $RAYCAST_EXTENSION_NAME"
  fi

  for staging_dir in "$RAYCAST_INSTALLED_EXTENSIONS_DIR"/."$RAYCAST_EXTENSION_NAME".staging.*; do
    [[ -e "$staging_dir" || -L "$staging_dir" ]] || continue
    remove_path "$staging_dir"
  done

  # ray develop で Raycast 本体へ import された development extension の登録は
  # Raycast の内部 state なので直接変更しない。必要なら Manage Extensions から削除する。
  info 'Raycast Local Extension build artifacts removed; remove its Raycast registration manually if desired'
}

main() {
  info "uninstalling links and local tools created from $DOTFILES_DIR"

  uninstall_managed_scripts

  remove_symlink \
    "$DOTFILES_DIR/.config/kitty/kitty.conf" \
    "$XDG_CONFIG_HOME/kitty/kitty.conf"

  remove_symlink \
    "$DOTFILES_DIR/.config/kitty/appearance.conf" \
    "$XDG_CONFIG_HOME/kitty/appearance.conf"

  remove_symlink \
    "$DOTFILES_DIR/.config/kitty/keybindings.conf" \
    "$XDG_CONFIG_HOME/kitty/keybindings.conf"

  # WezTerm は dotfiles が作ったリンクだけを解除し、アプリ本体は削除しない。
  remove_symlink \
    "$DOTFILES_DIR/.config/wezterm" \
    "$XDG_CONFIG_HOME/wezterm"
  uninstall_wezterm_local_config

  remove_symlink \
    "$DOTFILES_DIR/.config/starship.toml" \
    "$XDG_CONFIG_HOME/starship.toml"

  remove_symlink \
    "$DOTFILES_DIR/.config/lazygit/config.yml" \
    "$XDG_CONFIG_HOME/lazygit/config.yml"

  remove_symlink \
    "$DOTFILES_DIR/.config/yazi/yazi.toml" \
    "$XDG_CONFIG_HOME/yazi/yazi.toml"

  remove_symlink \
    "$DOTFILES_DIR/.gitconfig" \
    "$HOME/.gitconfig"

  remove_symlink \
    "$DOTFILES_DIR/.hushlogin" \
    "$HOME/.hushlogin"

  remove_symlink \
    "$DOTFILES_DIR/.config/zsh/.zshenv" \
    "$HOME/.zshenv"

  remove_symlink \
    "$DOTFILES_DIR/.config/zsh" \
    "$XDG_CONFIG_HOME/zsh"

  remove_symlink \
    "$DOTFILES_DIR/.config/vscode/settings.json" \
    "$VSCODE_USER_DIR/settings.json"

  remove_symlink \
    "$DOTFILES_DIR/.config/vscode/keybindings.json" \
    "$VSCODE_USER_DIR/keybindings.json"

  remove_symlink \
    "$DOTFILES_DIR/.hammerspoon" \
    "$HOME/.hammerspoon"

  remove_path "$TRANSLATION_POPUP_DIR"
  rmdir "$HOME/.local/share/dotfiles" 2>/dev/null || true

  uninstall_raycast_extension

  # ~/.local/bin 自体は他の local CLI と共有するため、空のときだけ削除する。
  rmdir "$LOCAL_BIN_DIR" 2>/dev/null || true

  info 'uninstall complete'
}

main "$@"
