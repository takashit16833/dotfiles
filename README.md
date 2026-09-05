# dotfiles

macOS 用の dotfiles。

## Install

Homebrew をインストールした状態で実行する。

```bash
git clone https://github.com/takashit16833/dotfiles.git ~/dotfiles
cd ~/dotfiles
bash ./install.sh
```

公開リポジトリを HTTPS で clone するため、初回セットアップ時点では GitHub の SSH 鍵や `gh` の認証は不要。

`install.sh` は `Brewfile` に宣言した CLI / アプリのインストール、設定ファイルの symlink、VS Code extension、Yazi plugin、Raycast Local Extension などのセットアップを行う。

Raycast Local Extension の初回登録では、公式の `ray develop` を短時間だけ利用するため Raycast app が自動で開くことがある。登録後は development process を停止するので、普段の利用時に `npm run dev` を起動しておく必要はない。

既存の Homebrew Node.js が shared library の更新などで実行不能になっている場合は、Raycast Extension のセットアップ前に検出して Node.js を入れ直す。

既存の設定ファイルや symlink がある場合、`install.sh` は上書きせず停止する。必要なものを退避してから再実行する。

## After install

`install.sh` 完了後、必要に応じて以下を手動で設定する。

- GitHub CLI を利用する場合は `gh auth login` で認証する。
- Hammerspoon を初回起動し、アクセシビリティ権限を許可する。以後は設定からログイン時に自動起動する。
- Docker を利用する場合は `colima start` で container runtime を起動する。
- Chrome / Brave の unpacked extension や Web アプリはブラウザ側で初回登録する。
- Tampermonkey userscript を使う場合は `chrome/userscripts/README.md` の手順で初回登録する。

## Browser extensions

自作の Chromium 系ブラウザ拡張と userscript は `chrome/` 配下で管理する。

- `chrome/youtube-keyboard`: YouTube の動画一覧をキーボードで移動・選択する。
- `chrome/userscripts/chatgpt-notify.user.js`: ChatGPT の回答生成完了を Hammerspoon 経由で通知する。

Chrome / Brave の unpacked extension はブラウザ側への初回登録が必要なため、各 extension の README に再構築手順を記載する。Tampermonkey userscript もブラウザ側で初回登録する。

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
