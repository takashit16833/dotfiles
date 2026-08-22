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

## Yazi

- `yazi` 本体と preview / search に使う補助 CLI は `Brewfile` で管理する。
- portable な設定は `.config/yazi/yazi.toml` と `.config/yazi/keymap.toml` を正本とし、`install.sh` が個別に symlink する。
- Yazi の directory 全体は symlink しない。`package.toml`、`plugins/`、`vfs.toml` など、Yazi 自身やマシンごとに変わる状態を repository から分離するため。
- SFTP 接続先は `vfs.toml` に host / user / key / password などのマシン固有・非公開情報を含み得るため、この repository では管理しない。
- 2 pane 表示には `terrakok/split-tabs.yazi` を使い、`install.sh` が未導入時だけ `ya pkg add terrakok/split-tabs` を実行する。plugin 本体と lock 情報は Yazi 側で管理する。
- `dawsers/dual-pane.yazi` は archived repository のため採用しない。
- ユーザーは Vim 操作を前提にしない。標準の矢印キー / Enter / Space に加え、Tab、F2、F4〜F8、Delete、Ctrl-L で主要操作を完結できる設定を優先する。
- F5 / F6 は、Yazi 標準の yank / paste と split-tabs の pane 切替を組み合わせて、反対 pane への copy / move として提供する。

## Packages and machine-local settings

- Homebrew package の一覧は `Brewfile` を正本とし、`install.sh` に package 名を重複して列挙しない。
- マシン固有または公開すべきでない設定は repository に含めない。
- Git identity は `~/.gitconfig.local` に分離する。
