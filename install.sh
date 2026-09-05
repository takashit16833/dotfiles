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

  # brew bundle --no-upgrade は既存 package を意図せず一括更新しないため維持する。
  # ただし Kitty の keybindings は比較的新しい action を使うため、metadata を更新して
  # Kitty だけは現行版へ揃える。これにより既存の古い Kitty が残る再構築を防ぐ。
  info 'updating Homebrew metadata'
  brew update

  info 'installing Homebrew packages from Brewfile'
  brew bundle --file="$DOTFILES_DIR/Brewfile" --no-upgrade

  info 'ensuring Kitty is current for managed keybindings'
  brew upgrade --cask kitty

  # brew bundle --no-upgrade では、既存 Node と更新済み shared library の組み合わせが
  # 壊れたまま残ることがある。Raycast Extension の npm install 前に実行可能性を確認し、
  # 壊れている場合だけ Homebrew の Node を入れ直して依存関係を揃える。
  info 'checking Node.js runtime'
  if ! node --version >/dev/null 2>&1 || ! npm --version >/dev/null 2>&1; then
    info 'Node.js runtime is broken; reinstalling Homebrew node'
    HOMEBREW_NO_INSTALLED_DEPENDENTS_CHECK=1 brew reinstall node
  fi

  node --version >/dev/null 2>&1 || fail 'node is still unavailable after Homebrew setup'
  npm --version >/dev/null 2>&1 || fail 'npm is still unavailable after Homebrew setup'
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
  local develop_log
  local ray_pid
  local status=0
  local ready=false
  local i

  if [[ ! -f "$RAYCAST_EXTENSION_DIR/package.json" ]]; then
    fail "$RAYCAST_EXTENSION_DIR/package.json does not exist"
  fi

  if ! command -v npm >/dev/null 2>&1; then
    fail 'npm was not found after installing Homebrew packages'
  fi

  info 'installing Raycast Local Extension dependencies'
  (
    cd "$RAYCAST_EXTENSION_DIR"
    npm install --package-lock=false --no-audit --no-fund
  )

  if [[ ! -x "$ray_cli" ]]; then
    fail 'Raycast extension CLI was not installed by npm'
  fi

  # Raycast の production build を ~/.config/raycast/extensions へ置くだけでは、
  # Raycast 本体には Local Extension として登録されない。
  # 公式の ray develop を短時間だけ起動して import を完了させ、build 成功後に停止する。
  # development process を常駐させる必要はなく、停止後も Extension は Raycast に残る。
  develop_log="$(mktemp)"
  info 'registering Raycast Local Extension'

  cd "$RAYCAST_EXTENSION_DIR"
  "$ray_cli" develop >"$develop_log" 2>&1 &
  ray_pid=$!
  cd "$DOTFILES_DIR"

  for ((i = 0; i < 30; i++)); do
    if grep -q 'built extension successfully' "$develop_log"; then
      ready=true
      break
    fi

    if ! kill -0 "$ray_pid" 2>/dev/null; then
      wait "$ray_pid" || status=$?
      cat "$develop_log" >&2
      rm -f "$develop_log"
      fail "Raycast development process exited before registration completed (status $status)"
    fi

    sleep 1
  done

  if [[ "$ready" != true ]]; then
    kill -INT "$ray_pid" 2>/dev/null || true
    wait "$ray_pid" 2>/dev/null || true
    cat "$develop_log" >&2
    rm -f "$develop_log"
    fail 'timed out while registering Raycast Local Extension'
  fi

  # build 完了直後に Raycast 側の import 処理が反映される余裕を少しだけ持たせる。
  # ここから先は installer 自身が develop process を停止するため、その終了 status は
  # Raycast CLI の実装依存として成功判定には使わない。
  sleep 1
  kill -INT "$ray_pid" 2>/dev/null || true
  wait "$ray_pid" 2>/dev/null || true

  cat "$develop_log"
  rm -f "$develop_log"

  info 'Raycast Local Extension registered'
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
