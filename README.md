# dotfiles

macOS 用の dotfiles。

## Install

Homebrew をインストールした状態で実行する。新しい Mac で Git や C コンパイラが利用できない場合は、`xcode-select -p` で Xcode Command Line Tools の状態を確認し、未導入なら `xcode-select --install` で導入する。C コンパイラは Emacs の Tree-sitter 文法のビルドに使用する。

```bash
git clone https://github.com/takashit16833/dotfiles.git ~/dotfiles
cd ~/dotfiles
bash ./install.sh
```

公開リポジトリを HTTPS で clone するため、初回セットアップ時点では GitHub の SSH 鍵や `gh` の認証は不要。

`install.sh` は `Brewfile` に宣言した CLI / アプリのインストール、設定ファイルの symlink、VS Code extension、Raycast Local Extension などのセットアップを行う。

Emacs 本体、Tree-sitter CLI、Lua Language Server、StyLua は `Brewfile` で導入する。Emacs の設定と Haskell・Lua の Tree-sitter 文法は別リポジトリの [`.emacs.d-cli` の README.org](https://github.com/takashit16833/.emacs.d-cli/blob/main/README.org) に従ってセットアップする。dotfiles の `install.sh` は Emacs 設定リポジトリの取得や、その `install.sh` の実行は行わない。

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

### VS Code の Markdown プレビュー

見出しと本文を階層に沿って字下げする自作拡張機能 [`vscode-markdown-outline-preview`](https://github.com/takashit16833/vscode-markdown-outline-preview) は、独立した非公開リポジトリで管理する。dotfiles の `install.sh` からは自動導入しない。

新しい Mac では、GitHub の SSH 認証を設定した後、次のコマンドで導入する。

```bash
git clone git@github.com:takashit16833/vscode-markdown-outline-preview.git ~/work/vscode-markdown-outline-preview
cd ~/work/vscode-markdown-outline-preview
bash ./install.sh
```

取得済みなら、そのディレクトリで `git pull` と `bash ./install.sh` を実行する。インストール後は `Developer: Reload Window` で VS Code を再読み込みし、Markdown プレビューを開き直す。詳細は [専用 README](https://github.com/takashit16833/vscode-markdown-outline-preview/blob/main/README.md) を参照する。

### VS Code の背景画像

壁紙の設定値は `.config/vscode/settings.json` で管理する。拡張機能の本体は独立した非公開リポジトリ [`vscode-wallpaper`](https://github.com/takashit16833/vscode-wallpaper) で管理し、dotfiles の `install.sh` からは導入しない。

新しい Mac への導入や拡張機能の更新は、GitHub の SSH 認証を設定した後、次のコマンドを実行する。

```bash
git clone git@github.com:takashit16833/vscode-wallpaper.git ~/work/vscode-wallpaper
cd ~/work/vscode-wallpaper
bash ./install.sh
```

既に clone 済みなら `git pull` して `bash ./install.sh` を実行する。拡張機能の設定・本体への自動適用と解除方法は [専用の README](https://github.com/takashit16833/vscode-wallpaper/blob/main/README.md) を参照する。

`vscode/background/` は旧方式の参考コードとして保持するが、現在の拡張機能には使わない。

### Obsidian の背景画像

背景画像を使う場合は、Git 管理外の `obsidian/css/retro-hacker-blue-wallpaper-local.css` を作成する。

```css
:root {
  --rhb-wallpaper-image: url("画像のURL");
}
```

Obsidian の Config Layer で `retro-hacker-blue-base.css`、`retro-hacker-blue-wallpaper.css`、`retro-hacker-blue-wallpaper-local.css` を有効にする。画像を使わない場合はローカル CSS を無効にする。

### Brave を ChatGPT ビューアにする

Brave の起動、新しいウィンドウ、新しいタブで `https://chatgpt.com/` を開くようにする。

1. `brave://settings/appearance` を開く。
   - **Show home button** を ON にする。
   - URL に `https://chatgpt.com/` を指定する。
2. `brave://settings/getStarted` を開く。
   - **New Tab Page** の **New tab page shows** を **Homepage** にする。
   - **On startup** を **Open the New Tab page** にする。

設定後は次の動作になる。

- Brave 起動 → ChatGPT
- `Cmd+N` → ChatGPT
- `Cmd+T` → ChatGPT

### スクロールバーをスクロール時だけ表示する

Chrome / Brave などでスクロールバーを常時表示しないようにする。

1. macOS の **システム設定** → **外観** を開く。
2. **スクロールバーを表示** を **スクロール時に表示** にする。

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
