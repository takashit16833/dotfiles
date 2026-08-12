# zsh の起動時に共有する最小限の環境設定。
#
# この dotfiles では XDG_CONFIG_HOME を ~/.config に固定し、
# zsh の startup file もその配下へ集約する。
export XDG_CONFIG_HOME="$HOME/.config"
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"
