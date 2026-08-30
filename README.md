# dotfiles

macOS 用の dotfiles。

## Install

Homebrew をインストールした状態で実行する。

```bash
git clone git@github.com:takashit16833/dotfiles.git ~/dotfiles
cd ~/dotfiles
bash ./install.sh
```

既存の設定ファイルや symlink がある場合、`install.sh` は上書きせず停止する。必要なものを退避してから再実行する。

Hammerspoon は初回起動時にアクセシビリティ権限を許可する。

## Browser extensions

自作の Chromium 系ブラウザ拡張は `chrome/` 配下で管理する。

- `chrome/youtube-keyboard`: YouTube の動画一覧をキーボードで移動・選択する。

Chrome / Brave の unpacked extension はブラウザ側への初回登録が必要なため、各 extension の README に再構築手順を記載する。

## Git identity

各 Mac で `~/.gitconfig.local` を作成する。

```bash
cat > ~/.gitconfig.local <<'EOF'
[user]
    name = YOUR_NAME
    email = YOUR_EMAIL
EOF
```

GitHub の HTTPS 認証も `~/.gitconfig.local` で `gh` を使う。

`~/.gitconfig.local` は dotfiles では管理しない。

## Uninstall

```bash
cd ~/dotfiles
bash ./uninstall.sh
```
