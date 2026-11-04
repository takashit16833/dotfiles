# dotfiles

macOS 用の dotfiles。

## Install

Homebrew をインストールした状態で実行する。新しい Mac で Git や C コンパイラが利用できない場合は、`xcode-select -p` で Xcode Command Line Tools の状態を確認し、未導入なら `xcode-select --install` で導入する。C コンパイラは Emacs の Tree-sitter 文法のビルドに使用する。

```bash
git clone https://github.com/takashit16833/dotfiles.git ~/dotfiles
cd ~/dotfiles
bash ./install.sh
```

dotfiles 自体は公開リポジトリなので HTTPS で認証なしに clone できる。初期インストールでは自作 VS Code 拡張を GitHub SSH で取得するため、`bash ./install.sh` の実行前に SSH 認証を設定する。

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

自作拡張機能 [`vscode-markdown-outline-preview`](https://github.com/takashit16833/vscode-markdown-outline-preview) は、`install.sh` から `~/vscode-markdown-outline-preview` に取得し、専用の `install.sh` で導入する。見出し階層に沿った字下げと配色を適用する。

取得済みのディレクトリがある場合、`install.sh` は未コミット変更がなく `main` にいることを確認し、`origin/main` へ fast-forward してから導入する。開発中の変更や別ブランチは勝手に切り替えない。手動更新する場合は次のとおり。

```bash
cd ~/vscode-markdown-outline-preview
git pull --ff-only
bash ./install.sh
```

導入後は VS Code の `Developer: Reload Window` で再読み込みし、Markdown プレビューを開き直す。詳細は [専用 README](https://github.com/takashit16833/vscode-markdown-outline-preview/blob/main/README.md) を参照する。

### VS Code のテーマと背景画像

初期セットアップでは、次の2つをソースから導入する。

- [`vscode-noctis-blue`](https://github.com/takashit16833/vscode-noctis-blue): 配色・領域別透過・ぼかし。
- [`vscode-wallpaper`](https://github.com/takashit16833/vscode-wallpaper): 背景画像・乗算・画像切り替え・共通 CSS ローダー。

設定値は `.config/vscode/settings.json` で管理する。標準構成は `Noctis Blue Transparent` と背景画像2枚の `orientation` 切り替えである。

自作拡張は固定コミットではなく最新 `main` の組み合わせを使う。取得済みのディレクトリは、未コミット変更がなく `main` にいる場合だけ `origin/main` へ fast-forward する。別ブランチや未コミット変更がある場合は中止する。手動更新する場合は次を実行する。

```bash
cd ~/vscode-wallpaper
git switch main
git pull --ff-only
bash ./install.sh

cd ~/vscode-noctis-blue
git switch main
git pull --ff-only
bash ./install.sh
```

初めて自動適用を有効にする場合は、VS Code で `Noctis Blue Transparent` を選び、**Noctis Blue: Enable Automatic Appearance** を実行する。VS Code Wallpaper が表示する本体変更の説明を確認して許可した後、**Developer: Reload Window** を実行する。

設定変更やテーマ切り替えでは CSS ファイルだけを更新するため、画面へ反映したいタイミングで **Developer: Reload Window** を実行する。拡張側から勝手な再読み込みや再読み込み通知は行わない。

背景画像の変更は `vscodeWallpaper.image` / `vscodeWallpaper.alternateImage` を編集する。領域別透過率は Noctis Blue の既定値を使用し、個別に変えたい場合だけ `noctisBlue.opacity` を追加する。詳細は各専用 README を参照する。

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
