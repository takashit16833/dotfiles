# Repository maintenance guidelines

このファイルは、この repository の設定を変更する AI / automation / maintainer 向けの指針をまとめる。

## README

`README.md` は新しい Mac のセットアップに必要な最小限の手順だけを書く。

設計方針、設定の背景、実装上の判断理由、AI が変更時に知るべきルールは README に追加せず、このファイルへ記録する。

## Configuration layout

- `XDG_CONFIG_HOME` は `$HOME/.config` に固定する。
- `XDG_CONFIG_HOME` が存在する前提で構成し、未設定時の分岐は作らない。
- 対応するアプリケーションの設定は、可能な限り XDG Base Directory 配下へ集約する。
- zsh の startup file は `.config/zsh` に集約する。
- zsh が `ZDOTDIR` を知る前に `.zshenv` を読めるよう、`~/.zshenv` だけは `.config/zsh/.zshenv` への bootstrap symlink として配置する。
- macOS の login shell 起動時に出る `Last login:` は repository の `.hushlogin` を `~/.hushlogin` へ symlink して非表示にする。
- 設定ファイルには、設定の目的や採用理由が後から分かるよう簡潔なコメントを基本的に付ける。設定名をそのまま言い換えるだけの自明なコメントは増やさない。

## Source of truth

設定ファイルの正本はこの repository に置き、`install.sh` が各アプリケーションの参照先へ symlink を作る。

`install.sh` / `uninstall.sh` は次の性質を維持する。

- 冪等に実行できること。
- 既存の実ファイルや別の symlink を勝手に上書き・削除しないこと。
- この repository が作成した symlink だけを安全に解除すること。

## VS Code

- VS Code Settings Sync は使用しない。
- Default Profile の user settings は `.config/vscode/settings.json` を正本とし、VS Code 側から symlink で参照する。
- Default Profile の keybindings は `.config/vscode/keybindings.json` を正本とし、VS Code 側から symlink で参照する。
- VS Code の `User` directory 全体は symlink せず、管理対象ファイルだけを個別に symlink する。
- extension は VS Code 側で自由に install / uninstall し、`.config/vscode/extensions.txt` は新しい環境へ復元するための snapshot として扱う。
- `sync.sh` は `code --list-extensions` から現在の extension 状態を `.config/vscode/extensions.txt` へ保存する。
- `install.sh` は `.config/vscode/extensions.txt` に記録された extension を復元する。
- extension 本体や VS Code が管理する内部データは repository に含めない。
- Markdown Outline Preview の本体（`takashit16833.markdown-outline-preview`）は独立した [`vscode-markdown-outline-preview`](https://github.com/takashit16833/vscode-markdown-outline-preview) を正本とする。初期セットアップ時は `~/vscode-markdown-outline-preview` に取得し、専用の `install.sh` を呼び出す。`sync.sh` の Marketplace extension 一覧からは除外する。
- `uninstall.sh` は VS Code の設定 symlink だけを解除し、導入済み extension は削除しない。
- snippets や Profiles は必要になった時点で追加し、先回りして空の管理対象を増やさない。

- VS Code Wallpaper の本体（`takashit16833.vscode-wallpaper`）は独立した [`vscode-wallpaper`](https://github.com/takashit16833/vscode-wallpaper) で管理する。dotfiles は `.config/vscode/settings.json` の設定値を管理し、初期セットアップ時は `~/vscode-wallpaper` に取得して専用の `install.sh` を呼び出す。拡張の導入と VS Code 本体への壁紙の自動適用は別であり、本体への変更は利用者の明示操作のみとする。
- Markdown Live Preview Editor の階層インデントは `vscode/markdown-live-preview/` の小さなパッチだけを管理する。公開済み拡張の内部ファイルを直接編集せず、上流の特定コミットを取得し、変更箇所を確認してから VSIX を生成する。
- Markdown のコードブロックは通常プレビュー（`vscode-markdown-outline-preview` の `preview.css` にある `pre`）と Live Preview（`vscode/markdown-live-preview/retro-hacker-blue.css` の `.cm-line.mlp-line-code`）の両方で背景色 `#0A1A36` を `color-mix(... 70%, transparent)` にして半透明にする。両方のインラインコードも元色 `#052A59` の70%半透明色とし、文字色・余白・字下げは変更しない。Live Preview の Webview は上流が `html, body { background: var(--vscode-editor-background) }` を指定しているため、自作 CSS で html/実際の body/CodeMirror の背景を透明化する。両 Markdown プレビューとも内部要素・Webview 外側の透明化と壁紙の連続表示を 2026-11-03 に実機確認済み。
- ローカルビルドは Marketplace 版と同じ拡張 ID を使うため、更新で上書きされ得る。既定のエディタを変更する前に、実機で字下げ・編集操作・コードブロック・表を確認する。

- 非公開の2リポジトリの取得には GitHub SSH 認証が必要である。取得先はホーム直下に固定し、既存パスが Git clone でない場合や origin が一致しない場合は中止する。既存 clone は自動 pull せず、専用の `install.sh` を再実行する。既存ディレクトリを削除・上書きしない。

## Terminal

ターミナルは WezTerm を使用する。

## git-delta

- Lazygit の diff renderer は `.config/lazygit/config.yml` から `delta --dark` を呼び、縦並び / side-by-side の切替方法は変更しない。
- Lazygit の `gui.theme` と Delta の独自テーマ指定は管理せず、配色はそれぞれの標準設定に任せる。`delta --dark` は暗い背景向けの動作指定として維持する。

## Local CLI tools

- Homebrew 外で dotfiles が管理する CLI は `$HOME/.local/bin` に置き、`.config/zsh/.zshenv` で同 directory を `PATH` の先頭へ追加する。
- 自作の個人用 CLI / 運用スクリプトは `scripts/bin/` を正本とし、用途と使い方は `scripts/README.md` にまとめる。新しい CLI を追加する前に `scripts/README.md` と `scripts/bin/` を確認し、同じ責務のスクリプトを重複して作らない。
- `install.sh` は `scripts/bin/` の executable を `$HOME/.local/bin` へ symlink し、`uninstall.sh` はこの repository を指している symlink だけを解除する。script の実体を `$HOME/.local/bin` へコピーしない。
- 自作 CLI の runtime state、秘密情報、SSH private/public key は repository に含めない。
- `tdf` は Homebrew core の formula として `Brewfile` で管理する。`cargo install` を直接使わず、Rust toolchain も top-level dependency として追加しない。

## Packages and machine-local settings

- Homebrew package の一覧は `Brewfile` を正本とし、`install.sh` に package 名を重複して列挙しない。Homebrew 外で配布される CLI は上記 `Local CLI tools` の方針で個別管理する。
- マシン固有または公開すべきでない設定は repository に含めない。
- Git identity は `~/.gitconfig.local` に分離する。
