#!/usr/bin/env bash

# エラー、未定義変数、パイプ途中の失敗を見逃さず、安全側で停止する。
set -euo pipefail

# このスクリプト自身の配置場所を dotfiles のルートとして扱う。
# ~/dotfiles 以外へ clone しても動作するよう、HOME にパスを固定しない。
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# この dotfiles では XDG_CONFIG_HOME を ~/.config に固定する。
XDG_CONFIG_HOME="$HOME/.config"

# Homebrew 外で管理する CLI の配置先。zsh 側でも PATH に追加する。
LOCAL_BIN_DIR="$HOME/.local/bin"

# Kitty Graphics Protocol 対応を含む Zellij を公式 release binary から導入する。
ZELLIJ_VERSION="0.45.0"
ZELLIJ_BIN="$LOCAL_BIN_DIR/zellij"
ZELLIJ_MANAGED_STATE_DIR="$HOME/.local/share/dotfiles/zellij"
ZELLIJ_MANAGED_VERSION_FILE="$ZELLIJ_MANAGED_STATE_DIR/version"

# VS Code の macOS 標準 User directory。
VSCODE_USER_DIR="$HOME/Library/Application Support/Code/User"

# dotfiles で管理する唯一の Raycast Local Extension。
RAYCAST_EXTENSION_DIR="$DOTFILES_DIR/raycast/extension"
RAYCAST_EXTENSION_NAME="dotfiles-commands"
RAYCAST_INSTALLED_EXTENSIONS_DIR="$HOME/.config/raycast/extensions"

info() {
  printf '[dotfiles] %s\n' "$*"
}

fail() {
  printf '[dotfiles] ERROR: %s\n' "$*" >&2
  exit 1
}

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

install_managed_scripts() {
  local scripts_dir="$DOTFILES_DIR/scripts/bin"
  local script

  if [[ ! -d "$scripts_dir" ]]; then
    fail "$scripts_dir does not exist"
  fi

  mkdir -p "$LOCAL_BIN_DIR"
  for script in "$scripts_dir"/*; do
    [[ -f "$script" ]] || continue
    [[ -x "$script" ]] || fail "$script is not executable"
    ensure_symlink "$script" "$LOCAL_BIN_DIR/$(basename "$script")"
  done
}

zellij_target_triple() {
  case "$(uname -m)" in
    arm64)
      printf '%s\n' 'aarch64-apple-darwin'
      ;;
    x86_64)
      printf '%s\n' 'x86_64-apple-darwin'
      ;;
    *)
      fail "unsupported macOS architecture: $(uname -m)"
      ;;
  esac
}

install_zellij() {
  local target_triple
  local installed_version=''
  local tmp_dir
  local archive

  target_triple="$(zellij_target_triple)"
  mkdir -p "$LOCAL_BIN_DIR"

  if [[ -e "$ZELLIJ_BIN" || -L "$ZELLIJ_BIN" ]]; then
    if [[ ! -x "$ZELLIJ_BIN" ]]; then
      fail "$ZELLIJ_BIN already exists but is not executable; leaving it untouched"
    fi

    installed_version="$("$ZELLIJ_BIN" --version 2>/dev/null || true)"

    if [[ ! -f "$ZELLIJ_MANAGED_VERSION_FILE" ]]; then
      fail "$ZELLIJ_BIN already exists ($installed_version) but is not dotfiles-managed; leaving it untouched"
    fi

    if [[ "$installed_version" == "zellij $ZELLIJ_VERSION" ]]; then
      info "Zellij already installed: $installed_version"
      return
    fi

    info "updating dotfiles-managed Zellij from $installed_version to $ZELLIJ_VERSION"
  fi

  tmp_dir="$(mktemp -d)"
  archive="$tmp_dir/zellij.tar.gz"

  info "installing Zellij $ZELLIJ_VERSION for $target_triple"
  if ! curl -fL \
    "https://github.com/zellij-org/zellij/releases/download/v${ZELLIJ_VERSION}/zellij-${target_triple}.tar.gz" \
    -o "$archive"; then
    rm -rf "$tmp_dir"
    fail 'failed to download the Zellij release archive'
  fi

  if ! tar -xzf "$archive" -C "$tmp_dir"; then
    rm -rf "$tmp_dir"
    fail 'failed to extract the Zellij release archive'
  fi

  if [[ ! -x "$tmp_dir/zellij" ]]; then
    rm -rf "$tmp_dir"
    fail 'the Zellij release archive did not contain an executable zellij binary'
  fi

  install -m 755 "$tmp_dir/zellij" "$ZELLIJ_BIN"
  rm -rf "$tmp_dir"

  mkdir -p "$ZELLIJ_MANAGED_STATE_DIR"
  printf '%s\n' "$ZELLIJ_VERSION" > "$ZELLIJ_MANAGED_VERSION_FILE"
  info "installed: $ZELLIJ_BIN"
}

install_yazi_plugins() {
  local split_tabs_plugin_dir="$XDG_CONFIG_HOME/yazi/plugins/split-tabs.yazi"
  local no_status_plugin_dir="$XDG_CONFIG_HOME/yazi/plugins/no-status.yazi"

  if ! command -v ya >/dev/null 2>&1; then
    fail 'Yazi package manager (ya) was not found after installing Yazi'
  fi

  if [[ -d "$split_tabs_plugin_dir" ]]; then
    info 'Yazi plugin already installed: terrakok/split-tabs'
  else
    info 'installing Yazi plugin: terrakok/split-tabs'
    YAZI_CONFIG_HOME="$XDG_CONFIG_HOME/yazi" ya pkg add terrakok/split-tabs
  fi

  if [[ -d "$no_status_plugin_dir" ]]; then
    info 'Yazi plugin already installed: yazi-rs/plugins:no-status'
  else
    info 'installing Yazi plugin: yazi-rs/plugins:no-status'
    YAZI_CONFIG_HOME="$XDG_CONFIG_HOME/yazi" ya pkg add yazi-rs/plugins:no-status
  fi
}

install_bat_theme() {
  local theme_source="$DOTFILES_DIR/.config/bat/themes/Retro Hacker Blue.tmTheme"
  local theme_target="$XDG_CONFIG_HOME/bat/themes/Retro Hacker Blue.tmTheme"

  if ! command -v bat >/dev/null 2>&1; then
    fail 'bat was not found after installing Homebrew packages'
  fi

  if [[ ! -f "$theme_source" ]]; then
    fail "$theme_source does not exist"
  fi

  ensure_symlink "$theme_source" "$theme_target"

  # Delta は bat の custom asset cache から追加 theme を読み込む。
  # config directory を XDG 配下へ固定したうえで cache を再構築する。
  info 'building bat cache for Retro Hacker Blue'
  BAT_CONFIG_DIR="$XDG_CONFIG_HOME/bat" bat cache --build >/dev/null

  if ! BAT_CONFIG_DIR="$XDG_CONFIG_HOME/bat" bat --list-themes | grep -Fxq 'Retro Hacker Blue'; then
    fail 'Retro Hacker Blue was not found in the bat theme cache'
  fi
}

install_vscode_extensions() {
  local extensions_file="$DOTFILES_DIR/.config/vscode/extensions.txt"
  local vscode_cli=''
  local extension
  local has_extensions=false

  if [[ ! -f "$extensions_file" ]]; then
    fail "$extensions_file does not exist"
  fi

  while IFS= read -r extension || [[ -n "$extension" ]]; do
    if [[ -z "$extension" || "$extension" == \#* ]]; then
      continue
    fi

    has_extensions=true

    if [[ -z "$vscode_cli" ]]; then
      if command -v code >/dev/null 2>&1; then
        vscode_cli="$(command -v code)"
      elif [[ -x '/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code' ]]; then
        vscode_cli='/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code'
      else
        fail 'VS Code CLI was not found after installing Visual Studio Code'
      fi
    fi

    info "installing VS Code extension: $extension"
    "$vscode_cli" --install-extension "$extension"
  done < "$extensions_file"

  if [[ "$has_extensions" == false ]]; then
    info 'no VS Code extensions declared'
  fi
}

install_raycast_extension() {
  local ray_cli="$RAYCAST_EXTENSION_DIR/node_modules/.bin/ray"
  local install_dir="$RAYCAST_INSTALLED_EXTENSIONS_DIR/$RAYCAST_EXTENSION_NAME"
  local staging_dir="$RAYCAST_INSTALLED_EXTENSIONS_DIR/.${RAYCAST_EXTENSION_NAME}.staging.$$"

  if [[ ! -f "$RAYCAST_EXTENSION_DIR/package.json" ]]; then
    fail "$RAYCAST_EXTENSION_DIR/package.json does not exist"
  fi

  if ! command -v npm >/dev/null 2>&1; then
    fail 'npm was not found after installing Homebrew packages'
  fi

  if ! command -v jq >/dev/null 2>&1; then
    fail 'jq was not found after installing Homebrew packages'
  fi

  info 'installing Raycast Local Extension dependencies'
  (
    cd "$RAYCAST_EXTENSION_DIR"
    npm install --package-lock=false --no-audit --no-fund
  )

  if [[ ! -x "$ray_cli" ]]; then
    fail 'Raycast extension CLI was not installed by npm'
  fi

  mkdir -p "$RAYCAST_INSTALLED_EXTENSIONS_DIR"
  rm -rf "$staging_dir"

  # -o を明示すると Raycast app を起動せず、指定 directory へ production build を出力できる。
  # いったん staging directory へ build し、manifest を検証してから atomically に入れ替える。
  info 'building Raycast Local Extension without launching Raycast'
  if ! (
    cd "$RAYCAST_EXTENSION_DIR"
    "$ray_cli" build -e dist -o "$staging_dir"
  ); then
    rm -rf "$staging_dir"
    fail 'failed to build Raycast Local Extension'
  fi

  if [[ ! -f "$staging_dir/package.json" ]]; then
    rm -rf "$staging_dir"
    fail "Raycast build completed but package.json was not found in $staging_dir"
  fi

  if [[ "$(jq -r '.name // empty' "$staging_dir/package.json" 2>/dev/null || true)" != "$RAYCAST_EXTENSION_NAME" ]]; then
    rm -rf "$staging_dir"
    fail "Raycast build output does not identify as $RAYCAST_EXTENSION_NAME"
  fi

  rm -rf "$install_dir"
  mv "$staging_dir" "$install_dir"

  info "Raycast Local Extension installed: $install_dir"
}

main() {
  info "installing from $DOTFILES_DIR"

  install_homebrew_packages
  install_zellij
  install_managed_scripts

  ensure_symlink \
    "$DOTFILES_DIR/.config/zellij/config.kdl" \
    "$XDG_CONFIG_HOME/zellij/config.kdl"

  ensure_symlink \
    "$DOTFILES_DIR/.config/zellij/layouts/minimal.kdl" \
    "$XDG_CONFIG_HOME/zellij/layouts/minimal.kdl"

  ensure_symlink \
    "$DOTFILES_DIR/.config/zellij/layouts/lazygit.kdl" \
    "$XDG_CONFIG_HOME/zellij/layouts/lazygit.kdl"

  ensure_symlink \
    "$DOTFILES_DIR/.config/kitty/kitty.conf" \
    "$XDG_CONFIG_HOME/kitty/kitty.conf"

  ensure_symlink \
    "$DOTFILES_DIR/.config/kitty/appearance.conf" \
    "$XDG_CONFIG_HOME/kitty/appearance.conf"

  ensure_symlink \
    "$DOTFILES_DIR/.config/kitty/keybindings.conf" \
    "$XDG_CONFIG_HOME/kitty/keybindings.conf"

  ensure_symlink \
    "$DOTFILES_DIR/.config/wezterm" \
    "$XDG_CONFIG_HOME/wezterm"

  ensure_symlink \
    "$DOTFILES_DIR/.config/starship.toml" \
    "$XDG_CONFIG_HOME/starship.toml"

  ensure_symlink \
    "$DOTFILES_DIR/.config/lazygit/config.yml" \
    "$XDG_CONFIG_HOME/lazygit/config.yml"

  ensure_symlink \
    "$DOTFILES_DIR/.config/yazi/yazi.toml" \
    "$XDG_CONFIG_HOME/yazi/yazi.toml"

  ensure_symlink \
    "$DOTFILES_DIR/.config/yazi/keymap.toml" \
    "$XDG_CONFIG_HOME/yazi/keymap.toml"

  ensure_symlink \
    "$DOTFILES_DIR/.config/yazi/theme.toml" \
    "$XDG_CONFIG_HOME/yazi/theme.toml"

  ensure_symlink \
    "$DOTFILES_DIR/.config/yazi/init.lua" \
    "$XDG_CONFIG_HOME/yazi/init.lua"

  install_yazi_plugins
  install_bat_theme

  ensure_symlink \
    "$DOTFILES_DIR/.gitconfig" \
    "$HOME/.gitconfig"

  ensure_symlink \
    "$DOTFILES_DIR/.hushlogin" \
    "$HOME/.hushlogin"

  ensure_symlink \
    "$DOTFILES_DIR/.config/zsh/.zshenv" \
    "$HOME/.zshenv"

  ensure_symlink \
    "$DOTFILES_DIR/.config/zsh" \
    "$XDG_CONFIG_HOME/zsh"

  ensure_symlink \
    "$DOTFILES_DIR/.config/vscode/settings.json" \
    "$VSCODE_USER_DIR/settings.json"

  ensure_symlink \
    "$DOTFILES_DIR/.config/vscode/keybindings.json" \
    "$VSCODE_USER_DIR/keybindings.json"

  install_vscode_extensions

  ensure_symlink \
    "$DOTFILES_DIR/.hammerspoon" \
    "$HOME/.hammerspoon"

  install_raycast_extension

  info 'install complete'
}

main "$@"