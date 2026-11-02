# Markdown Outline Preview

VS Code 標準の Markdown プレビューを Retro Hacker Blue に揃えるローカル拡張機能。
見出しのレベルを判定して、その配下の本文・リスト・コードブロックも同じ階層に字下げする。
フォントは VS Code の既存設定を使用する。

## インストールと更新

```sh
bash vscode/markdown-preview/install.sh
```

編集後にこのコマンドで VSIX を再作成・再導入する。
VS Code の「Developer: Reload Window」で再読み込みする。
初回だけ Node.js と npm が必要（dotfiles の通常セットアップでは Homebrew で導入される）。

```sh
node --test vscode/markdown-preview/test/preview.test.js
```

拡張機能の ID は `takashit16833.markdown-outline-preview`。
Marketplace では公開しない。既存の `markdown.styles` と二重読み込みしない。
