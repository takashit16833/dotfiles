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

## Kitty

- Kitty は `.config/kitty/kitty.conf` を薄い entry point とし、`appearance.conf` と `keybindings.conf` を明示的に `include` する。
- default config 全体を複製せず、意図的に変更する項目だけを repository で管理する。
- Kitty の directory 全体は symlink せず、上記 3 ファイルだけを個別に symlink する。theme kitten などが生成する local file を repository へ混在させないため。
- `appearance.conf` は WezTerm の Retro Hacker Blue ベースの配色、下部 tab bar、Menlo + BIZ UDGothic の日本語表示を引き継ぐ。
- `keybindings.conf` は macOS の Cmd / Option 操作を zsh 側の Emacs 系編集へ橋渡しする。行編集の意味は Terminal ではなく zsh 側に持たせる。
- Option は `macos_option_as_alt both` で Alt modifier として Terminal application へ渡す。個別の Kitty key mapping はこれより優先される。
- Option-Z / Option-G は zsh 側の zi / lazygit widget 用 ESC sequence を送る挙動を維持する。

## Yazi

- `yazi` 本体と preview / search に使う補助 CLI は `Brewfile` で管理する。
- portable な設定は `.config/yazi/yazi.toml` と `.config/yazi/keymap.toml` を正本とし、`install.sh` が個別に symlink する。
- Yazi の directory 全体は symlink しない。`package.toml`、`plugins/`、`vfs.toml` など、Yazi 自身やマシンごとに変わる状態を repository から分離するため。
- SFTP 接続先は `vfs.toml` に host / user / key / password などのマシン固有・非公開情報を含み得るため、この repository では管理しない。
- 2 pane 表示には `terrakok/split-tabs.yazi` を使い、`install.sh` が未導入時だけ `ya pkg add terrakok/split-tabs` を実行する。plugin 本体と lock 情報は Yazi 側で管理する。
- `dawsers/dual-pane.yazi` は archived repository のため採用しない。
- ユーザーは Vim 操作を前提にしない。標準の矢印キー / Enter / Space に加え、Tab、F2、F4〜F8、Delete、Ctrl-L で主要操作を完結できる設定を優先する。
- F5 / F6 は、Yazi 標準の yank / paste と split-tabs の pane 切替を組み合わせて、反対 pane への copy / move として提供する。

## Local CLI tools

- Homebrew 外で dotfiles が管理する CLI は `$HOME/.local/bin` に置き、`.config/zsh/.zshenv` で同 directory を `PATH` の先頭へ追加する。
- `tdf` は Homebrew core の formula として `Brewfile` で管理する。`cargo install` を直接使わず、Rust toolchain も top-level dependency として追加しない。
- Zellij は Kitty Graphics Protocol 対応が必要なため、Homebrew の更新タイミングには依存せず、`install.sh` が指定 version の公式 macOS release binary を `$HOME/.local/bin/zellij` へ導入する。
- Zellij を `install.sh` が導入したときだけ `$HOME/.local/share/dotfiles/zellij/version` を ownership marker として作る。marker の無い既存 binary は、同じ version であっても dotfiles 管理として採用せず、勝手に上書きしない。
- Zellij の通常 UI は `.config/zellij/layouts/minimal.kdl` を使い、session 名・mode 表示・Powerline 風装飾を出さず tab だけを 1 行表示する。
- tab bar には `zjstatus` v0.24.0 を version 固定で利用し、各 tab は `focused_pane_title` を表示する。配色は Kitty に合わせ、active を `#FF4DE1`、inactive を `#4C9EEB`、背景色なしとする。
- Zellij 内の zsh は OSC 2 で pane title を更新し、prompt 待機中は `zsh`、通常の command 実行中は先頭の command 名を表示する。zsh の widget から直接起動する TUI は必要に応じて明示的に title を設定する。
- Zellij は `uninstall.sh` で完全削除する対象とする。managed binary を消す前に session 停止を試み、`~/.config/zellij`、platform cache/data、XDG fallback、runtime socket directory まで削除する。

## Packages and machine-local settings

- Homebrew package の一覧は `Brewfile` を正本とし、`install.sh` に package 名を重複して列挙しない。Homebrew 外で配布される CLI は上記 `Local CLI tools` の方針で個別管理する。
- マシン固有または公開すべきでない設定は repository に含めない。
- Git identity は `~/.gitconfig.local` に分離する。
