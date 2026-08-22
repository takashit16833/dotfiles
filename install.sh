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
CARGO_INSTALL_ROOT="$HOME/.local"

# tdf は upstream の Git repository から reproducible に導入するため revision を固定する。
TDF_REV="de0050499e96f2f9d69b3e380fa3dd8de7119b90"

# Kitty Graphics Protocol 対応を含む Zellij を公式 release binary から導入する。
ZELLIJ_VERSION="0.45.0"
ZELLIJ_BIN="$LOCAL_BIN_DIR/zellij"
ZELLIJ_MANAGED_STATE_DIR="$HOME/.local/share/dotfiles/zellij"
ZELLIJ_MANAGED_VERSION_FILE="$ZELLIJ_MANAGED_STATE_DIR/version"

# VS Code の macOS 標準 User directory。
VSCODE_USER_DIR="$HOME/Library/Application Support/Code/User"

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

install_tdf() {
  if ! command -v cargo >/dev/null 2>&1; then
    fail 'cargo was not found after installing the Rust toolchain from Brewfile'
  fi

  mkdir -p "$LOCAL_BIN_DIR"
  info "installing tdf from pinned revision ${TDF_REV:0:12}"
  cargo install \
    --git https://github.com/itsjunetime/tdf.git \
    --rev "$TDF_REV" \
    --locked \
    --root "$CARGO_INSTALL_ROOT"
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
    if [[ "$installed_version" == "zellij $ZELLIJ_VERSION" ]]; then
      # 事前に同じ公式 binary を手動導入していた場合も、ここから dotfiles 管理として採用する。
      mkdir -p "$ZELLIJ_MANAGED_STATE_DIR"
      printf '%s\n' "$ZELLIJ_VERSION" > "$ZELLIJ_MANAGED_VERSION_FILE"
      info "Zellij already installed: $installed_version"
      return
    fi

    if [[ ! -f "$ZELLIJ_MANAGED_VERSION_FILE" ]]; then
      fail "$ZELLIJ_BIN already exists ($installed_version); leaving unmanaged binary untouched"
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
  local plugin_dir="$XDG_CONFIG_HOME/yazi/plugins/split-tabs.yazi"

  if ! command -v ya >/dev/null 2>&1; then
    fail 'Yazi package manager (ya) was not found after installing Yazi'
  fi

  if [[ -d "$plugin_dir" ]]; then
    info 'Yazi plugin already installed: terrakok/split-tabs'
    return
  fi

  info 'installing Yazi plugin: terrakok/split-tabs'
  YAZI_CONFIG_HOME="$XDG_CONFIG_HOME/yazi" ya pkg add terrakok/split-tabs
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

main() {
  info "installing from $DOTFILES_DIR"

  install_homebrew_packages
  install_tdf
  install_zellij

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

  install_yazi_plugins

  ensure_symlink \
    "$DOTFILES_DIR/.gitconfig" \
    "$HOME/.gitconfig"

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

  info 'install complete'
}

main "$@"
