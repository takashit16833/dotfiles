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

# VS Code の macOS 標準 User directory。
VSCODE_USER_DIR="$HOME/Library/Application Support/Code/User"

# Marketplace 未公開の QuickJump は、固定 commit から VSIX を作って導入する。
QUICKJUMP_VERSION="1.0.0"
QUICKJUMP_COMMIT="af23a8c11654d9eea5a59dfe5d816490cdcced19"
QUICKJUMP_EXTENSION_ID="takashit16833.quickjump"

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

# PC固有の設定は初回だけ作成し、dotfilesが生成した場合のみ管理印を付ける。
install_wezterm_local_config() {
  local template="$DOTFILES_DIR/.config/wezterm/local.example.lua"
  local directory="$XDG_CONFIG_HOME/wezterm-local"
  local target="$directory/local.lua"
  local marker="$directory/.dotfiles-created"

  if [[ -e "$target" || -L "$target" ]]; then
    info "WezTerm local config already exists: $target"
    return
  fi

  [[ -f "$template" ]] || fail "$template does not exist"
  [[ ! -L "$directory" ]] || fail "$directory is a symlink; leaving it untouched"
  if [[ -e "$marker" || -L "$marker" ]]; then
    fail "$marker exists without local.lua; leaving it untouched"
  fi

  mkdir -p "$directory"
  cp -n "$template" "$target"
  printf '%s\n' 'created by dotfiles install.sh' > "$marker"
  info "created WezTerm local config: $target"
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

install_quickjump_extension() {
  local vscode_cli=''
  local tmp_dir
  local archive
  local source_dir
  local vsix

  if command -v code >/dev/null 2>&1; then
    vscode_cli="$(command -v code)"
  elif [[ -x '/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code' ]]; then
    vscode_cli='/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code'
  else
    fail 'VS Code CLI was not found after installing Visual Studio Code'
  fi

  if "$vscode_cli" --list-extensions --show-versions \
    | grep -Fqx "${QUICKJUMP_EXTENSION_ID}@${QUICKJUMP_VERSION}"; then
    info "QuickJump already installed: $QUICKJUMP_VERSION"
    return
  fi

  if ! command -v npm >/dev/null 2>&1; then
    fail 'npm was not found after installing Homebrew packages'
  fi

  tmp_dir="$(mktemp -d)"
  archive="$tmp_dir/quickjump.tar.gz"

  (
    trap 'rm -rf "$tmp_dir"' EXIT

    info "installing QuickJump $QUICKJUMP_VERSION"
    if ! curl -fL \
      "https://github.com/takashit16833/QuickJump/archive/${QUICKJUMP_COMMIT}.tar.gz" \
      -o "$archive"; then
      fail 'failed to download QuickJump source archive'
    fi

    if ! tar -xzf "$archive" -C "$tmp_dir"; then
      fail 'failed to extract QuickJump source archive'
    fi

    source_dir="$tmp_dir/QuickJump-${QUICKJUMP_COMMIT}"
    if [[ ! -f "$source_dir/package.json" ]]; then
      fail "$source_dir/package.json does not exist"
    fi

    cd "$source_dir"
    npm install --package-lock=false --no-audit --no-fund
    npm run package

    vsix="$source_dir/quickjump-${QUICKJUMP_VERSION}.vsix"
    if [[ ! -f "$vsix" ]]; then
      fail "QuickJump package did not produce $vsix"
    fi

    "$vscode_cli" --install-extension "$vsix" --force
  )

  info "QuickJump installed: $QUICKJUMP_VERSION"
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

  install_wezterm_local_config
  install_homebrew_packages
  install_managed_scripts

  ensure_symlink \
    "$DOTFILES_DIR/.config/kitty/kitty.conf" \
    "$XDG_CONFIG_HOME/kitty/kitty.conf"

  ensure_symlink \
    "$DOTFILES_DIR/.config/kitty/appearance.conf" \
    "$XDG_CONFIG_HOME/kitty/appearance.conf"

  ensure_symlink \
    "$DOTFILES_DIR/.config/kitty/keybindings.conf" \
    "$XDG_CONFIG_HOME/kitty/keybindings.conf"

  # WezTerm の設定ディレクトリをリンクし、別の実ファイルやリンクは上書きしない。
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
    "$DOTFILES_DIR/.config/yazi/theme.toml" \
    "$XDG_CONFIG_HOME/yazi/theme.toml"

  ensure_symlink \
    "$DOTFILES_DIR/.config/yazi/keymap.toml" \
    "$XDG_CONFIG_HOME/yazi/keymap.toml"

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
  install_quickjump_extension

  ensure_symlink \
    "$DOTFILES_DIR/.hammerspoon" \
    "$HOME/.hammerspoon"

  install_raycast_extension

  info 'install complete'
}

main "$@"
