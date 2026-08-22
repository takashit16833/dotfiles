# zsh の起動時に共有する最小限の環境設定。
#
# この dotfiles では XDG_CONFIG_HOME を ~/.config に固定し、
# zsh の startup file もその配下へ集約する。
export XDG_CONFIG_HOME="$HOME/.config"
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"

# Homebrew 外で管理する local CLI (tdf / Zellij など) を全 zsh から利用できるようにする。
case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *) export PATH="$HOME/.local/bin:$PATH" ;;
esac
