# Interactive zsh の設定。
#
# 過去の大きな設定は持ち込まず、普段使う機能だけを明示的に初期化する。

# fzf の zsh integration。
# Ctrl-R の履歴検索、Ctrl-T のファイル選択、**<Tab> の fuzzy completion を有効にする。
if command -v fzf >/dev/null 2>&1; then
  source <(fzf --zsh)
fi

# zoxide の zsh integration。
# 移動履歴を学習し、z / zi で頻繁に使うディレクトリへ素早く移動できるようにする。
# zi は fzf を利用するため、fzf の初期化後に配置する。
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"

  # Option + Z で zi を呼び出し、fzf から移動先ディレクトリを選択する。
  # macOS の Terminal / WezTerm では Option を Meta (ESC prefix) として扱うため、
  # bindkey では ESC + z を表す ^[z に割り当てる。
  zoxide-zi-widget() {
    zi
    zle reset-prompt
  }
  zle -N zoxide-zi-widget
  bindkey '^[z' zoxide-zi-widget
fi

# Starship をプロンプトとして初期化する。
# プロンプト系は他の shell integration の後に置き、最後に見た目を確定させる。
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi
