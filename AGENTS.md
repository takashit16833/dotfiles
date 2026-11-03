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
- 自作 Markdown Outline Preview 拡張は `vscode/markdown-preview/` を正本とし、VSIX を `install.sh` から生成・導入する。`sync.sh` の Marketplace extension 一覧からは除外する。
- Markdown preview の CSS と JavaScript は自作拡張の contributions で読み込む。`markdown.styles` から公開 URL を二重に読み込まない。
- `uninstall.sh` は VS Code の設定 symlink だけを解除し、導入済み extension は削除しない。
- snippets や Profiles は必要になった時点で追加し、先回りして空の管理対象を増やさない。
- 独立した試作拡張 `vscode/wallpaper/`（`takashit16833.vscode-wallpaper`）は `vscodeWallpaper.*` の設定から CSS を生成し、Webview でプレビューする。特定のテーマに依存せず、乗算色は白、領域別の背景色は VS Code テーマの色を既定値として参照し、設定で上書きできる。`node --test` で生成処理を検証する。現在は VS Code 編集画面への CSS 適用処理を含めない。
- `vscode/wallpaper/install.sh` は明示実行のみ。ルートの `install.sh` から導入せず、VS Code 本体を改変せず、整合性警告の隠蔽も行わない。
- 実画面の検証用に `vscode/wallpaper/workbench-script.js` は DevTools Console で実行する一時 CSS 適用・解除コードを生成する。ユーザーの明示操作が必要であり、本体ファイル改変、デバッグ用ポートの開放、警告の隠蔽、自動適用はしない。
- `vscode/wallpaper/responsive-test.js` は実際の CSS 生成関数に2枚の埋め込み PNG を与え、縦長・横長（`orientation: portrait`）・横幅800pxでの切り替えを一時検証する。設定は書き換えず、通常の適用スクリプトで元の壁紙へ戻せる。
- VS Code 公式 API から本体 DOM/CSS を直接操作できないため、非公開 API や本体ファイル改変による自動適用は行わない。
- サイドバー内部のペインと見出しは `paneHeaders.css` の不透明な背景色を持つため、共通壁紙表示時に通常背景を透明化する。見出しのホバー表示は維持し、コードは `vscode/wallpaper/wallpaper.js` にまとめる。
- Extensions の一覧コンテナ `.monaco-list-rows` も不透明だったため（実機で確認）、サイドバーと補助サイドバー内のコンテナ背景だけを透明化する。各行の選択・ホバー表示は維持する。
- 編集タブの帯 `.part.editor .tabs-and-actions-container` と下部 Explorer の一覧背景 `.part.panel .monaco-list-rows` は実測で不透明だった。コンテナ背景だけを透明化し、個別タブ、行の選択色、スクロールバーのつまみは維持する。
- サイドバーの Search 見出し `.part.sidebar > .composite.title` は不透明と実測されている。見出し背景だけ透明化し、個々のラベル・アイコンの見た目は維持する。編集タブ・パンくず・スクロールバー自体は透明と実測されたので、未確認の別要素を推測で変更しない。
- VS Code 本体 `modernUI/browser/media/tabs.css`、`breadcrumbscontrol.css`、`terminal.css`、`scrollbars.css` で、タブ・パンくず・ターミナル切り替え欄・スクロールバーの下地を描く要素を確認。該当コンテナ背景のみ透明化し、タブ枠線・ターミナル選択行・スクロールバーのつまみは維持する。新しい背景規則は実機で再確認する。
- パンくずの `.breadcrumbs-below-tabs` とその内部に限って背景色・背景画像を透明化する。ミニマップは Canvas が縮小コードと背景を一緒に描くため、既定の表示を変えず、明示的な `vscodeWallpaper.minimapOpacity`（null または 0～1）で Canvas 全体の透過を調整する。縮小コードも薄くなると説明し、実機で確認する。
- ターミナルの Canvas による不透明な描画は、実機で `terminal.integrated.enableImages: true` と `terminal.background: '#00000000'` により解消した。これは VS Code 標準設定であり、拡張から勝手に変更しない。`diagnostics-script.js` は左側の表示領域と画像切り替えを読み取り専用で検査する。
- VS Code 全画面壁紙の幅別切り替えは実装検討中。`vscode/background/` の CSS は参考用として保持するが、拡張機能による読み込みや `install.sh` からの配置は行わない。
- Apc / Custom CSS and JS Loader は実機で本体改変や整合性警告が問題になったため、再導入しない。背景画像の再実装では既存の vscode-background の動作を前提として方式を検討し、検証前に本体へパッチを適用しない。

- Markdown Live Preview Editor の階層インデントは `vscode/markdown-live-preview/` の小さなパッチだけを管理する。公開済み拡張の内部ファイルを直接編集せず、上流の特定コミットを取得し、変更箇所を確認してから VSIX を生成する。
- ローカルビルドは Marketplace 版と同じ拡張 ID を使うため、更新で上書きされ得る。既定のエディタを変更する前に、実機で字下げ・編集操作・コードブロック・表を確認する。

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

- 壁紙の既定の切り替えは `orientation`（縦長・横長）。既存の `aspect-ratio` 16/10 は任意の縦横比として引き続き利用できる。診断と CSS 生成は共通の `mediaQueryFor` を使う。

- スクロールバーの黒い背景は `scrollbars.css` の `background: var(--vscode-scrollbar-background)` を根拠に透明化する。つまみの `--vscode-scrollbarSlider-*` と `.slider` には触れない。パンくずは `--vscode-breadcrumb-background` と帯の背景だけ透明化し、表示状態を実機で確認する。
