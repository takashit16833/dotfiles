# dotfiles

macOS の共通設定。

## インストール

Homebrew を事前にインストールする。Git が使えない場合は Xcode Command Line Tools を導入する（`xcode-select --install`）。

```bash
mkdir -p ~/workspace
git clone https://github.com/takashit16833/dotfiles.git ~/workspace/dotfiles
cd ~/workspace/dotfiles
bash ./install.sh
```

GitHub への認証を求められた場合は、ブラウザでログインする。既存の設定ファイルは上書きしないため、競合する場合は退避して再実行する。

## 初回設定

Mac ごとの Git ユーザー情報を `~/.gitconfig.local` に保存する。このファイルは Git 管理しない。

```bash
cat > ~/.gitconfig.local <<'EOF'
[user]
    name = YOUR_NAME
    email = YOUR_EMAIL
EOF
```

Hammerspoon を起動し、アクセシビリティ権限とログイン時の自動起動を設定する。Docker を使う場合は `colima start` で起動する。

Brave を ChatGPT 専用のビューアとして使う場合は、[Brave の設定手順](docs/manual-settings.md#brave-を-chatgpt-ビューアにする) を参照する。Brave の起動時や新しいウィンドウ・タブで ChatGPT を開くための設定をまとめている。

VS Code・Obsidian の外観、ブラウザ拡張、macOS の表示設定は [手動設定](docs/manual-settings.md) を参照する。

## VS Code 拡張機能の一覧を更新

```bash
bash ./sync.sh
```

## 関連リポジトリ

- [Noctis Blue](https://github.com/takashit16833/vscode-noctis-blue) — VS Code のテーマ・背景画像
- [QuickJump](https://github.com/takashit16833/QuickJump) — VS Code のカーソル移動
- [.emacs.d](https://github.com/takashit16833/.emacs.d) — Emacs の設定

## アンインストール

```bash
bash ./uninstall.sh
```
