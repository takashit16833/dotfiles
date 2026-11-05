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

テーマ、壁紙、背景画像の切り替え、透過・ぼかしは
[Noctis Blue](https://github.com/takashit16833/vscode-noctis-blue)
**1つの拡張**で管理する。初期セットアップの `install.sh` が
`~/vscode-noctis-blue` の最新 `main` を取得・導入し、旧 Wallpaper 拡張は
新しい拡張の導入を確認した後にアンインストールする。

設定の正本は `.config/vscode/settings.json` である。画像は
`noctisBlue.wallpaper.image` / `noctisBlue.wallpaper.alternateImage`、
領域別の透過率は `noctisBlue.opacity` で設定する。

手動で更新する場合：

```bash
cd ~/vscode-noctis-blue
git pull --ff-only
bash ./install.sh
```

初回は VS Code の `Noctis Blue Transparent` を選び、
**Noctis Blue: Enable Automatic Appearance** の説明を確認して許可する。
旧 Wallpaper の管理ファイルを検証できた場合は自動適用状態を引き継ぐ。
適用後は **Developer: Reload Window** を実行する。

VS Code の組み込み Markdown Editor 用 CSS は別のファイルに適用する。
必要なら **Noctis Blue: Enable Markdown Editor Appearance** から有効にし、
アンインストール前には Markdown Editor と Automatic Appearance の両方を解除する。
安全上の制約と Dev Container での扱いは
[Noctis Blue の README](https://github.com/takashit16833/vscode-noctis-blue#readme) を参照する。

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
