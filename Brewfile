# macOS で利用する Homebrew package の宣言。
#
# このファイルは「現在インストールされているもの全部」の snapshot ではなく、
# この dotfiles 環境を成立させるために意図して残す道具だけを管理する。
# Homebrew は rolling release なので、ここでは厳密なバージョン固定は行わない。

# --- Terminal / shell -------------------------------------------------------

# WezTerm は macOS タイトルバーの背景色を Terminal と完全に揃えるため、
# Nightly 限定機能を利用する。Stable 版ではなく Nightly を明示的に採用する。
cask "wezterm@nightly"

# zsh のプロンプト。表示内容は starship.toml 側で最小構成に絞る。
brew "starship"

# fuzzy finder。zsh や各 CLI から必要になった場面で利用する。
brew "fzf"

# 使用履歴を学習してディレクトリ移動を補助する。
brew "zoxide"

# --- Git / data handling ----------------------------------------------------

# Git 操作のメイン UI として利用する。
brew "lazygit"

# GitHub の認証や repository 操作に利用する。
brew "gh"

# JSON の確認・加工用。host と Dev Container の双方で利用する方針。
brew "jq"

# codebase 内の高速な全文検索に利用する。
brew "ripgrep"

# --- Containers -------------------------------------------------------------

# Docker Desktop には依存せず、Docker CLI + Colima を利用する。
# docker は client CLI、Colima は macOS 上で container runtime を動かす役割を持つ。
brew "docker"
brew "colima"

# Compose file を Docker CLI から扱うための plugin。
# Homebrew 版は Docker 側から plugin directory を認識させる設定が別途必要になる。
brew "docker-compose"

# --- Editor -----------------------------------------------------------------

# 開発のメイン editor。
cask "visual-studio-code"
