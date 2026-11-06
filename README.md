# dotfiles

macOS 用の dotfiles。

## Install

Homebrew をインストールした状態で実行する。新しい Mac で Git や C コンパイラが利用できない場合は、`xcode-select -p` で Xcode Command Line Tools の状態を確認し、未導入なら `xcode-select --install` で導入する。

```bash
mkdir -p ~/workspace
git clone https://github.com/takashit16833/dotfiles.git ~/workspace/dotfiles
cd ~/workspace/dotfiles
bash ./install.sh
```

dotfiles 自体は公開リポジトリなので HTTPS で認証なしに clone できる。GitHub CLI（`gh`）は `install.sh` がインストールし、未ログインの場合は途中でブラウザ認証を案内する。SSH 鍵や事前の `gh auth login` は不要。

`install.sh` は `Brewfile` に宣言した CLI / アプリのインストール、設定ファイルの symlink、VS Code extension、Raycast Local Extension などのセットアップを行う。

Raycast Local Extension の初回登録では、公式の `ray develop` を短時間だけ利用するため Raycast app が自動で開くことがある。登録後は development process を停止するので、普段の利用時に `npm run dev` を起動しておく必要はない。

Noctis Blue のビルドに必要な Node.js 22 以上を確認する。古い場合は Homebrew 版を更新し、別の Node.js が PATH にあってもインストール処理では Homebrew 版を優先する。

既存の設定ファイルや symlink がある場合、`install.sh` は上書きせず停止する。必要なものを退避してから再実行する。

## After install

`install.sh` 完了後、必要に応じて以下を手動で設定する。

- Hammerspoon を初回起動し、アクセシビリティ権限を許可する。以後は設定からログイン時に自動起動する。
- Docker を利用する場合は `colima start` で container runtime を起動する。
- Chrome / Brave の unpacked extension や Web アプリはブラウザ側で初回登録する。
- Tampermonkey userscript を使う場合は `chrome/userscripts/README.md` の手順で初回登録する。

### VS Code のテーマと背景画像

テーマ、壁紙、画像切り替え、透過、ぼかしは
[Noctis Blue](https://github.com/takashit16833/vscode-noctis-blue)
1つで管理する。初期セットアップでは `~/workspace/vscode-noctis-blue` の最新 `main` を取得して導入する。

設定の正本は `.config/vscode/settings.json` であり、画像は
`noctisBlue.wallpaper.image` / `noctisBlue.wallpaper.alternateImage`、
領域別の透過率は `noctisBlue.opacity` で設定する。

手動更新：ワークベンチの読み込み方式が変わる版では、更新前に VS Code で **Noctis Blue: Disable Automatic Appearance** を実行し、**Developer: Reload Window** で解除を確認する。更新後は明示的に再有効化する。

```bash
cd ~/workspace/vscode-noctis-blue
git pull --ff-only
bash ./install.sh
```

初回は VS Code で `Noctis Blue Transparent` を選択し、
**Noctis Blue: Enable Automatic Appearance** の説明を確認して許可する。
同意がない場合、管理ファイルが存在しても自動適用を有効化しない。
有効化後は **Developer: Reload Window** を実行する。

内蔵 Markdown Editor の表示を変更する場合は、別途
**Noctis Blue: Enable Markdown Editor Appearance** から有効化する。
アンインストール前には Markdown Editor Appearance と Automatic Appearance の両方を解除する。
詳細は [Noctis Blue の README](https://github.com/takashit16833/vscode-noctis-blue#readme) に従う。

### Obsidian の背景画像

背景画像を使う場合は、Git 管理外の `obsidian/css/retro-hacker-blue-wallpaper-local.css` を作成する。

```css
:root {
  --rhb-wallpaper-image: url("画像のURL");
}
```

エディタやサイドバーなどの背景の透過率も、同じローカル CSS で指定できる。

```css
html body.theme-dark {
  --rhb-wallpaper-panel-opacity: 50%;
  --rhb-wallpaper-sidebar-opacity: 70%;
  --rhb-wallpaper-block-opacity: 45%;
}
```

- `panel-opacity`：エディタなどの主要領域（既定値 83%）。
- `sidebar-opacity`：左右のサイドバー（既定値 90%）。
- `block-opacity`：コードブロックやダイアログなど（既定値 45%）。

値を小さくすると背景が透けて壁紙がよく見える。必要な項目だけ指定すればよい。

Obsidian ウィンドウの縦横比で2枚の画像を切り替える場合は、同じローカル CSS に次のように記述する。

```css
:root {
  --rhb-wallpaper-image: url("横長画面用の画像URL");
}

@media (max-aspect-ratio: 16/10) {
  :root {
    --rhb-wallpaper-image: url("縦長画面用の画像URL");
  }
}
```

縦横比は Obsidian ウィンドウの幅 ÷ 高さで判定する。ここでは `16:10` 以下で2枚目に切り替わり、それより横長なら1枚目を使う。切替条件は `16/10` を変更して調整できる。背景画像は引き続き画面全体に1枚だけ描画し、既存の乗算と透過の設定は変わらない。

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
cd ~/workspace/dotfiles
bash ./uninstall.sh
```
