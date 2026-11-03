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
- 独立した試作拡張 `vscode/wallpaper/`（`takashit16833.vscode-wallpaper`）は `vscodeWallpaper.*` の設定から CSS を生成し、Webview でプレビューする。特定のテーマに依存せず、乗算色は白、領域別の背景色は VS Code テーマの色を既定値として参照し、設定で上書きできる。`node --test` で生成処理を検証する。本体への直接適用は一時 CSS またはユーザーの明示的な自動適用コマンドのどちらかで行う。
- `vscode/wallpaper/install.sh` は明示実行のみ。ルートの `install.sh` から導入せず、このスクリプト自体は VS Code 本体を改変しない。整合性警告は隠さない。
- 実画面の検証用に `vscode/wallpaper/workbench-script.js` は DevTools Console で実行する一時 CSS 適用・解除コードを生成する。この一時適用は自動適用と独立しており、本体ファイル改変やデバッグ用ポートは使わない。
- `vscode/wallpaper/responsive-test.js` は実際の CSS 生成関数に2枚の埋め込み PNG を与え、縦長・横長（`orientation: portrait`）・横幅800pxでの切り替えを一時検証する。設定は書き換えず、通常の適用スクリプトで元の壁紙へ戻せる。
- VS Code 公開 API から本体 DOM/CSS は直接操作できない。明示的な同意後に `auto-apply.js` が `workbench.html` に `renderer-loader.js` の読み込みを追加する。起動時の画面側スクリプトは VS Code が渡す作業領域 ID に対応する CSS を読み込む。元 HTML をバックアップし、解除時に復元する。他の本体改変や整合性警告の隠蔽は行わない。
- サイドバー内部のペインと見出しは `paneHeaders.css` の不透明な背景色を持つため、共通壁紙表示時に通常背景を透明化する。見出しのホバー表示は維持し、コードは `vscode/wallpaper/wallpaper.js` にまとめる。
- Extensions の一覧コンテナ `.monaco-list-rows` も不透明だったため（実機で確認）、サイドバーと補助サイドバー内のコンテナ背景だけを透明化する。各行の選択・ホバー表示は維持する。
- 編集タブの帯 `.part.editor .tabs-and-actions-container` と下部 Explorer の一覧背景 `.part.panel .monaco-list-rows` は実測で不透明だった。コンテナ背景だけを透明化し、個別タブ、行の選択色、スクロールバーのつまみは維持する。
- サイドバーの Search 見出し `.part.sidebar > .composite.title` は不透明と実測されている。見出し背景だけ透明化し、個々のラベル・アイコンの見た目は維持する。編集タブ・パンくず・スクロールバー自体は透明と実測されたので、未確認の別要素を推測で変更しない。
- VS Code 本体 `modernUI/browser/media/tabs.css`、`breadcrumbscontrol.css`、`terminal.css`、`scrollbars.css` で、タブ・パンくず・ターミナル切り替え欄・スクロールバーの下地を描く要素を確認。該当コンテナ背景のみ透明化し、タブ枠線・ターミナル選択行・スクロールバーのつまみは維持する。新しい背景規則は実機で再確認する。
- パンくずの `.breadcrumbs-below-tabs` とその内部に限って背景色・背景画像を透明化する。ミニマップは Canvas が縮小コードと背景を一緒に描くため、既定の表示を変えず、明示的な `vscodeWallpaper.minimapOpacity`（null または 0～1）で Canvas 全体の透過を調整する。縮小コードも薄くなると説明し、実機で確認する。
- ターミナルの Canvas による不透明な描画は、実機で `terminal.integrated.enableImages: true` と `terminal.background: '#00000000'` により解消した。これは VS Code 標準設定であり、拡張から勝手に変更しない。`diagnostics-script.js` は左側の表示領域と画像切り替えを読み取り専用で検査する。
- 壁紙は縦長・横長（既定）、任意の縦横比、画面幅による画像切り替えを実装済み。`vscode/background/` は旧方式の参考コードとしてのみ保持し、拡張機能や `install.sh` から読み込まない。
- Apc / Custom CSS and JS Loader は実機で本体改変や整合性警告が問題になったため再導入しない。自作拡張の自動適用は明示コマンドでのみ許可し、`workbench.html` 以外の既存ファイルを変更しない。チェックサムの書き換えや警告隠蔽はしない。権限不足・別の変更・バックアップ欠損時には安全に失敗させる。

- Markdown Live Preview Editor の階層インデントは `vscode/markdown-live-preview/` の小さなパッチだけを管理する。公開済み拡張の内部ファイルを直接編集せず、上流の特定コミットを取得し、変更箇所を確認してから VSIX を生成する。
- Markdown のコードブロックは通常プレビュー（`vscode/markdown-preview/preview.css` の `pre`）と Live Preview（`vscode/markdown-live-preview/retro-hacker-blue.css` の `.cm-line.mlp-line-code`）の両方で背景色 `#0A1A36` を `color-mix(... 70%, transparent)` にして半透明にする。両方のインラインコードも元色 `#052A59` の70%半透明色とし、文字色・余白・字下げは変更しない。Live Preview の Webview は上流が `html, body { background: var(--vscode-editor-background) }` を指定しているため、自作 CSS で html/実際の body/CodeMirror の背景を透明化する。両 Markdown プレビューとも内部要素・Webview 外側の透明化と壁紙の連続表示を 2026-11-03 に実機確認済み。
- ローカルビルドは Marketplace 版と同じ拡張 ID を使うため、更新で上書きされ得る。既定のエディタを変更する前に、実機で字下げ・編集操作・コードブロック・表を確認する。

- 浮動パネルの隙間は `floatingPanels.css` の余白に由来し、実測では左サイドバーと編集領域の間が4pxだった。`backgroundColors.gap`（既定 `theme`）と `opacity.gap`（既定 `0`）で設定する。`.split-view-view:has(> .part...)::before` の余白部分にだけ色を描き、カード本体・枠線・操作領域の変更を避ける。浮動パネルと通常密度のみ対象とし、実機確認待ち。
- 固定表示コード（Sticky Scroll）は VS Code の `stickyScroll.css` により行番号とコードの二層が不透明となる。壁紙の一時 CSS で `.sticky-widget:not(.peek)` 内の `.sticky-widget-line-numbers` / `.sticky-widget-lines-scrollable` を透明化する。実機で透明化すると背後のコードと文字が重なったため、固定領域に `backdrop-filter: blur(...)` を使って背後だけをぼかす。強さは `vscodeWallpaper.stickyScrollBlur`（既定12px、0～30整数、0で無効）で指定する。固定表示、文字色、hover、peek は変更しない。2026-11-03 にぼかしの実機動作を確認済み。

- 壁紙の既定の切り替えは `orientation`（縦長・横長）。既存の `aspect-ratio` 16/10 は任意の縦横比として引き続き利用できる。診断と CSS 生成は共通の `mediaQueryFor` を使う。

- スクロールバーの下地は `scrollbars.css` の `background: var(--vscode-scrollbar-background)` を根拠に透明化する。つまみの `--vscode-scrollbarSlider-*` と `.slider` には触れない。パンくずは `--vscode-breadcrumb-background` と下地を透明化し、いずれも実機確認済み。
- その後の Canvas 画素診断で `canvas.decorationsOverviewRuler` は5地点すべて `rgba(1, 1, 17, 1)` と確定した。VS Code `decorationsOverviewRuler.ts` は `editorOverviewRuler.background` を Canvas に塗るため、CSS ではなく VS Code の正式な配色設定を利用する。`.config/vscode/settings.json` の `workbench.colorCustomizations` にテーマ非依存で `"editorOverviewRuler.background": "#00000000"` を追加し、目印や `.slider` の色は変更しない。壁紙の一時 CSS を解除しても設定は残る点に注意。


- `renderer-loader.js` は起動時に一度だけ、作業領域 ID に対応する CSS を読み込む。定期的な `fetch` / `setInterval` や、非公式な変更通知経路は作らない。設定変更は拡張機能の `onDidChangeConfiguration` で CSS ファイルを更新するだけとし、通知や再読み込みの要求は行わない。画面への反映はユーザーが `Developer: Reload Window` を実行したときに行う。初めて開く作業領域は CSS 生成が画面読み込みより後になる場合があり、初回のみ再読み込みが必要。既知でない loader は書き換えず、整合性警告も隠さない。
- 自動適用の設定は `vscode.workspace.getConfiguration` の有効値を使い、ユーザー設定をプロジェクト設定で上書きできる。`workspace-id.js` は VS Code `workspaces/node/workspaces.ts` と同じ作業領域 ID（ローカルフォルダーなら MD5(path+birthtime)、複数ルートの設定ファイルなら MD5(lowercased path)、リモートなら MD5(uri)）を計算する。Renderer は `window.vscode.context.resolveConfiguration().workspace.id` を使って対応する CSS を選ぶ。未生成の場合は画面で再試行せず、次にユーザーが `Developer: Reload Window` を実行したときに読み込む。ユーザープロファイル別の CSS 分離は未対応。`image: null` と空文字は壁紙なしとして扱う。アプリ更新後の再導入は手動とし、既知の HTML 以外を検出したら拒否する。実機検証は未完了。

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
