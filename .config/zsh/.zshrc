# Interactive zsh の設定。
#
# 過去の大きな設定は持ち込まず、普段使う機能だけを明示的に初期化する。

# よく使う ls の詳細表示。
alias ll='ls -lahG'

# emacs を `e` で起動する。
alias e='emacs -nw'

# gita fetch してから gita ll する
alias gll='gita fetch && gita ll'

# WezTerm との相性問題回避のため、lazygit は legacy キーボード入力を使う。
alias lg='TCELL_KEYBOARD_PROTOCOL=legacy lazygit'

# コマンド履歴をセッションをまたいで保存し、複数の zsh で共有する。
HISTFILE="$ZDOTDIR/.zsh_history"
HISTSIZE=100000
SAVEHIST=100000
setopt SHARE_HISTORY
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS

# 対話中でも `#` 以降をコメントとして扱えるようにする。
setopt INTERACTIVE_COMMENTS

# 行編集の意味はzsh側に集約する。
bindkey -e

# Cmd+左右のWezTerm互換シーケンス。
# zsh/ZLEはKKPを解釈しないためzshではKKPを有効化せず、
# WezTerm側でCmd修飾を保持できるシーケンスへ変換してここで割り当てる。
# WezTerm側の対応設定とセットなので、片側だけ削除しないこと。
bindkey $'\e[1;9D' beginning-of-line
bindkey $'\e[1;9C' end-of-line

# Cmd+Backspaceも同じ理由でWezTerm側の互換シーケンスを受け取る。
# WezTerm側の対応設定とセットなので、片側だけ削除しないこと。
bindkey $'\e[127;9u' backward-kill-line

# Cmd+VのCSI-u入力を受け取り、macOSのクリップボードを貼り付ける。
paste-from-clipboard-widget() {
  local text
  text="$(pbpaste)" || return
  LBUFFER+="$text"
}

zle -N paste-from-clipboard-widget
bindkey $'\e[118;9u' paste-from-clipboard-widget

# 単語移動・削除
bindkey $'\e[1;3D' backward-word
bindkey $'\e[1;3C' forward-word
bindkey $'\e[3;3~' kill-word

# zsh 標準の補完を有効にし、候補一覧を矢印キーで選択できるようにする。
# Git の branch / ref なども command の文脈に応じて補完される。
zmodload zsh/complist
autoload -Uz compinit
compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

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

# Yazi を y で起動し、終了時は Yazi 内の現在のディレクトリへ移動する。
if command -v yazi >/dev/null 2>&1; then
  y() {
    local tmp cwd
    tmp="$(mktemp -t "yazi-cwd.XXXXXX")"

    command yazi "$@" --cwd-file="$tmp"

    IFS= read -r -d '' cwd < "$tmp"
    [ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd" || builtin true

    command rm -f -- "$tmp"
  }
fi

# gita に登録した Git repository を fzf で選択して移動する。
if command -v gita >/dev/null 2>&1 && command -v fzf >/dev/null 2>&1; then
  gita-repo-widget() {
    local repo repo_path

    repo="$(gita ls | tr ' ' '\n' | fzf)" || {
      zle reset-prompt
      return
    }

    repo_path="$(gita ls "$repo")" || return
    cd "$repo_path"
    zle reset-prompt
  }

  zle -N gita-repo-widget
  bindkey '^[r' gita-repo-widget
fi

# WezTerm 側で Option + G を ESC + g に変換し、
# legacy キーボード入力で lazygit を起動する。
if command -v lazygit >/dev/null 2>&1; then
  lazygit-widget() {
    zle -I
    TCELL_KEYBOARD_PROTOCOL=legacy lazygit
    zle reset-prompt
  }

  zle -N lazygit-widget
  bindkey '^[g' lazygit-widget
fi

# Starship をプロンプトとして初期化する。
# プロンプト系は他の shell integration の後に置き、最後に見た目を確定させる。
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

# vtermにプロンプトの終端を通知する。
if [[ "$INSIDE_EMACS" == "vterm" ]]; then
  my_vterm_prompt_end() {
    printf '\e]51;A%s@%s:%s\e\\' "$USER" "$(hostname)" "$PWD"
  }

  PROMPT=$PROMPT'%{$(my_vterm_prompt_end)%}'
fi

# Haskell
export PATH="$HOME/.ghcup/bin:$PATH"
export PATH="$HOME/.cabal/bin:$PATH"

# lem
export PATH="$HOME/common-lisp/lem:$PATH"

# macOS 26ではSDK 27のリンクエラーを回避する。
if [[ "$OSTYPE" == darwin* ]]; then
  export SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX26.5.sdk
fi
