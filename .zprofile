# Login zsh の環境設定。
#
# Homebrew の bin / sbin を PATH の先頭へ置き、Homebrew が利用する
# 環境変数・MANPATH・INFOPATH も公式の shellenv でまとめて設定する。
# Apple Silicon の標準 prefix (/opt/homebrew) を利用する。
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv zsh)"
fi
