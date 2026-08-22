# Interactive zsh の設定。
#
# 過去の大きな設定は持ち込まず、普段使う機能だけを明示的に初期化する。

# よく使う ls の詳細表示。
alias ll='ls -lahG'

# Zellij は zoxide の `z` と衝突しない短い名前で起動する。
alias zj='zellij'

# 行編集の意味は zsh 側に集約する。
# Terminal 側は OS 固有のショートカットを標準的な Emacs キーへ変換するだけにし、
# Terminal を乗り換えても編集操作そのものはここで維持できるようにする。
bindkey -e

# Cmd + Backspace 用。
# WezTerm から送る Meta + Ctrl-U は Emacs keymap では未使用なので、
# カーソル位置から行頭までを削除する操作だけを明示的に割り当てる。
bindkey '\e^U' backward-kill-line

# Zellij 内では pane title を shell / 実行中 command に合わせる。
# zjstatus はこの title を tab 名として表示するため、Pane #N のような既定名を避けられる。
set_zellij_pane_title() {
  [[ -n "${ZELLIJ:-}" ]] || return
  printf '\e]2;%s\a' "$1"
}

autoload -Uz add-zsh-hook

zellij_pane_title_preexec() {
  local -a command_words
  command_words=(${(z)1})
  set_zellij_pane_title "${command_words[1]:t}"
}

zellij_pane_title_precmd() {
  set_zellij_pane_title 'zsh'
}

add-zsh-hook preexec zellij_pane_title_preexec
add-zsh-hook precmd zellij_pane_title_precmd

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

  # Kitty 側で Option + Z を ESC + z に変換し、ここで zi widget に割り当てる。
  # bindkey の ^[z は ESC + z を表す。
  zoxide-zi-widget() {
    zi
    zle reset-prompt
  }
  zle -N zoxide-zi-widget
  bindkey '^[z' zoxide-zi-widget
fi

# Kitty 側で Option + G を ESC + g に変換し、現在のディレクトリで lazygit を起動する。
if command -v lazygit >/dev/null 2>&1; then
  lazygit-widget() {
    zle -I
    set_zellij_pane_title 'lazygit'
    lazygit
    set_zellij_pane_title 'zsh'
    zle reset-prompt
  }
  zle -N lazygit-widget
  bindkey '^[g' lazygit-widget
fi

# Yazi を終了した場所へ、そのまま shell の current directory も移動できる wrapper。
# `yazi` は通常起動、`y` は終了後の cd まで含めたいときに使う。
if command -v yazi >/dev/null 2>&1; then
  y() {
    local tmp cwd
    tmp="$(mktemp -t 'yazi-cwd.XXXXXX')"

    command yazi "$@" --cwd-file="$tmp"
    IFS= read -r -d '' cwd < "$tmp"

    if [[ -n "$cwd" && "$cwd" != "$PWD" && -d "$cwd" ]]; then
      builtin cd -- "$cwd"
    fi

    command rm -f -- "$tmp"
  }
fi

# Starship をプロンプトとして初期化する。
# プロンプト系は他の shell integration の後に置き、最後に見た目を確定させる。
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi
