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
- `uninstall.sh` は VS Code の設定 symlink だけを解除し、導入済み extension は削除しない。
- snippets や Profiles は必要になった時点で追加し、先回りして空の管理対象を増やさない。

- Noctis Blue（`takashit16833.noctis-blue`）は [`vscode-noctis-blue`](https://github.com/takashit16833/vscode-noctis-blue) を唯一の拡張の正本とする。配色・壁紙・乗算・画像切替・領域別透過・ぼかしを一つの VSIX に含む。初期セットアップは `~/vscode-noctis-blue/install.sh` のみを実行する。
- Noctis Blue の `install.sh` は Noctis Blue のインストールだけを担当し、ほかの拡張は変更しない。本体への初回 CSS 適用には明示同意が必要であり、管理済みファイルがあるだけで自動有効化しない。
- 背景画像設定の正本は `.config/vscode/settings.json` の `noctisBlue.wallpaper.*`。同じ背景設定を別の拡張設定へ重複定義しない。領域背景や配色を `workbench.colorCustomizations` に重複定義しない。
- `noctisBlue.markdownActiveBlockOpacity` は共有 CSS に対応するアプリ全体の設定であり、ワークスペース別に重複指定しない。Dev Container のファイル所有者は自動変更しない。
- テーマ固有の UI 色・トークン色は Noctis Blue 本体で管理し、`workbench.colorCustomizations` / `editor.tokenColorCustomizations` / `editor.semanticTokenColorCustomizations` に Noctis Blue の配色を重複定義しない。QuickJump や Text Marker など拡張固有の設定は dotfiles に置いてよい。
- `sync.sh` の Marketplace 拡張一覧には、自作拡張（ID が `takashit16833.` で始まるもの）を含めない。自作拡張はそれぞれの正本リポジトリから導入する。
- 内蔵 Markdown Editor の Rich Links は無効化し、GitHub 等の URL も通常リンクとして Noctis Blue のリンク配色を使う。

- ソースから導入する Noctis Blue（`vscode-noctis-blue`）はホーム直下に取得し、固定コミットではなく最新 `main` を使う。取得には GitHub CLI（`gh auth login`）の認証を使い、HTTPS 経由で clone / pull する。Git の credential helper はコマンド単位で `gh auth git-credential` を指定し、Git のグローバル設定は変更しない。既存 clone は origin が一致し、未コミット変更がなく、現在ブランチが `main` の場合だけ `git pull --ff-only` 相当で更新する。SSH 形式の origin は更新成功後に HTTPS 形式へ切り替える。それ以外は中止し、branch 切り替え・stash・reset を自動実行しない。既存ディレクトリを削除・上書きしない。

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

