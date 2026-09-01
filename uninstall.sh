#!/usr/bin/env bash

# エラー、未定義変数、パイプ途中の失敗を見逃さず、安全側で停止する。
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
XDG_CONFIG_HOME="$HOME/.config"
LOCAL_BIN_DIR="$HOME/.local/bin"
ZELLIJ_VERSION="0.45.0"
ZELLIJ_BIN="$LOCAL_BIN_DIR/zellij"
ZELLIJ_MANAGED_STATE_DIR="$HOME/.local/share/dotfiles/zellij"
ZELLIJ_MANAGED_VERSION_FILE="$ZELLIJ_MANAGED_STATE_DIR/version"
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

uninstall_zellij() {
  local tmp_root="${TMPDIR:-/tmp}"

  # session process が残ったまま binary / runtime state を消さないよう、先に停止を試みる。
  if [[ -x "$ZELLIJ_BIN" ]]; then
    "$ZELLIJ_BIN" kill-all-sessions --yes >/dev/null 2>&1 || true
  fi

  if [[ -f "$ZELLIJ_MANAGED_VERSION_FILE" ]]; then
    remove_path "$ZELLIJ_BIN"
    remove_path "$ZELLIJ_MANAGED_STATE_DIR"
  elif [[ -e "$ZELLIJ_BIN" || -L "$ZELLIJ_BIN" ]]; then
    info "skip: $ZELLIJ_BIN exists but is not marked as dotfiles-managed"
  else
    info 'Zellij binary already absent'
  fi

  # Zellij は binary だけでなく config / cache / data / socket も削除し、
  # uninstall.sh 後に local state を残さない。
  remove_path "$XDG_CONFIG_HOME/zellij"
  remove_path "$HOME/.cache/zellij"
  remove_path "$HOME/.local/share/zellij"
  remove_path "$HOME/Library/Caches/org.Zellij-Contributors.Zellij"
  remove_path "$HOME/Library/Application Support/org.Zellij-Contributors.Zellij"
  remove_path "${tmp_root%/}/zellij-$(id -u)"
  remove_path "/tmp/zellij-$(id -u)"

  # dotfiles 用 marker の親 directory は、他の managed tool が無い場合だけ片付ける。
  rmdir "$HOME/.local/share/dotfiles" 2>/dev/null || true
}

uninstall_raycast_extension() {
  local install_dir="$RAYCAST_INSTALLED_EXTENSIONS_DIR/$RAYCAST_EXTENSION_NAME"
  local staging_dir

  # repository の source は残し、npm / local build が生成したものだけを片付ける。
  remove_path "$RAYCAST_EXTENSION_DIR/node_modules"
  remove_path "$RAYCAST_EXTENSION_DIR/dist"

  # install.sh が管理する固定 destination と、中断時に残り得る staging directory を削除する。
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

  info 'Raycast Local Extension removed'
}

main() {
  info "uninstalling links and local tools created from $DOTFILES_DIR"

  uninstall_managed_scripts
  uninstall_zellij

  remove_symlink \
    "$DOTFILES_DIR/.config/kitty/kitty.conf" \
    "$XDG_CONFIG_HOME/kitty/kitty.conf"

  remove_symlink \
    "$DOTFILES_DIR/.config/kitty/appearance.conf" \
    "$XDG_CONFIG_HOME/kitty/appearance.conf"

  remove_symlink \
    "$DOTFILES_DIR/.config/kitty/keybindings.conf" \
    "$XDG_CONFIG_HOME/kitty/keybindings.conf"

  remove_symlink \
    "$DOTFILES_DIR/.config/wezterm" \
    "$XDG_CONFIG_HOME/wezterm"

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
    "$DOTFILES_DIR/.config/yazi/keymap.toml" \
    "$XDG_CONFIG_HOME/yazi/keymap.toml"

  remove_symlink \
    "$DOTFILES_DIR/.config/yazi/theme.toml" \
    "$XDG_CONFIG_HOME/yazi/theme.toml"

  remove_symlink \
    "$DOTFILES_DIR/.config/yazi/init.lua" \
    "$XDG_CONFIG_HOME/yazi/init.lua"

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

  uninstall_raycast_extension

  # ~/.local/bin 自体は他の local CLI と共有するため、空のときだけ削除する。
  rmdir "$LOCAL_BIN_DIR" 2>/dev/null || true

  info 'uninstall complete'
}

main "$@"
