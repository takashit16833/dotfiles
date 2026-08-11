# Interactive zsh の設定。
#
# 今回の開発環境刷新では、過去の設定を一度持ち込まず、
# 実際に必要になったものだけをここへ追加していく。
# そのため、現時点ではプロンプトの初期化だけを行う。

# Starship がインストールされている場合だけプロンプトとして初期化する。
# command -v で存在確認しておくことで、Starship が一時的に未導入でも
# zsh 自体は正常に起動できるようにする。
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi
