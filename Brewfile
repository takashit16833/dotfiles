# macOS で利用する Homebrew package の宣言。
#
# このファイルは「現在インストールされているもの全部」の snapshot ではなく、
# この dotfiles 環境を成立させるために意図して残す道具だけを管理する。
# Homebrew は rolling release なので、ここでは厳密なバージョン固定は行わない。

# WezTerm は macOS タイトルバーの背景色を Terminal と完全に揃えるため、
# Nightly 限定機能を利用する。Stable 版ではなく Nightly を明示的に採用する。
cask "wezterm@nightly"

# zsh のプロンプト。表示内容は starship.toml 側で最小構成に絞る。
brew "starship"

# fuzzy finder。zsh や各 CLI から必要になった場面で利用する。
brew "fzf"

# 使用履歴を学習してディレクトリ移動を補助する。
brew "zoxide"

# Git 操作のメイン UI として利用する。
brew "lazygit"
