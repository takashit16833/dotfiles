# Markdown Outline Preview

VS Code 標準の Markdown プレビューを Retro Hacker Blue に揃えるローカル拡張機能。
見出しのレベルを判定して、その配下の本文・リスト・コードブロックも同じ階層に字下げする。
フォントは VS Code の既存設定を使用する。

## インストールと更新

新しい Mac では dotfiles ルートの `bash ./install.sh` が、この拡張機能専用の `install.sh` を自動実行する。別途導入する必要はない。

拡張機能を単独で導入・更新する場合は、dotfiles ルートで次を実行する。

```sh
git pull
bash ./vscode/markdown-preview/install.sh
```

CSS や JavaScript の変更後は、この専用スクリプトで VSIX を作り直して VS Code に再導入する。`git pull` だけでは導入済み拡張機能は更新されない。導入後は VS Code の `Developer: Reload Window` を実行し、Markdown プレビューを開き直す。
初回だけ Node.js と npm が必要（dotfiles の通常セットアップでは Homebrew で導入される）。

```sh
node --test vscode/markdown-preview/test/preview.test.js
```

拡張機能の ID は `takashit16833.markdown-outline-preview`。
Marketplace では公開しない。既存の `markdown.styles` と二重読み込みしない。
