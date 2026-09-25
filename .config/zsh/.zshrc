# Interactive zsh の設定。
#
# 過去の大きな設定は持ち込まず、普段使う機能だけを明示的に初期化する。

# よく使う ls の詳細表示。
alias ll='ls -lahG'

# Zellij は zoxide の `z` と衝突しない短い名前で起動する。
alias zj='zellij'

# emacs を `e` で起動する。
alias e='emacs -nw'

# gita fetch してから gita ll する
alias gll='gita fetch && gita ll'

# コマンド履歴をセッションをまたいで保存し、複数の zsh で共有する。
HISTFILE="$ZDOTDIR/.zsh_history"
HISTSIZE=100000
SAVEHIST=100000
setopt SHARE_HISTORY
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS

# 対話中でも `#` 以降をコメントとして扱えるようにする。
setopt INTERACTIVE_COMMENTS

# 行編集の意味は zsh 側に集約する。
# Terminal 側は OS 固有のショートカットを標準的な Emacs キーへ変換するだけにし、
# Terminal を乗り換えても編集操作そのものはここで維持できるようにする。
bindkey -e

# Cmd + Backspace 用。
# Kitty から送る Meta + Ctrl-U は Emacs keymap では未使用なので、
# カーソル位置から行頭までを削除する操作だけを明示的に割り当てる。
bindkey '\e^U' backward-kill-line

# WezTermのCmd+Backspaceでカーソルから行頭まで削除する。
bindkey $'\e[127;9u' backward-kill-line

# zsh 標準の補完を有効にし、候補一覧を矢印キーで選択できるようにする。
# Git の branch / ref なども command の文脈に応じて補完される。
zmodload zsh/complist
autoload -Uz compinit
compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# Zellij 内では Kitty の自動 shell integration が注入されないため、明示的に読み込む。
# OSC 133 により command / output の境界を Zellij が認識できるようになり、
# Scroll mode で command 単位の移動や直前の出力コピーを利用できる。
if [[ -n "${ZELLIJ:-}" && -n "${KITTY_INSTALLATION_DIR:-}" ]]; then
  export KITTY_SHELL_INTEGRATION="enabled"
  autoload -Uz -- "$KITTY_INSTALLATION_DIR"/shell-integration/zsh/kitty-integration
  kitty-integration
  unfunction kitty-integration
fi

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
