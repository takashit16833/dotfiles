# VS Code Wallpaper（試作）

VS Code 本体を変更せず、画面全体に表示する壁紙の **CSS 生成・プレビュー・実画面での一時適用テスト** を行う独立した拡張機能。

現段階で **VS Code の編集画面全体への自動適用は行わない**。公式拡張機能 API にその操作がなく、未検証の本体書き換えによる破損警告を再発させないためである。プレビューは専用タブに擬似的な画面構成を表示するものであり、実際の VS Code の画面で動作することを保証しない。

## 導入・テスト

```bash
cd ~/dotfiles
node --test vscode/wallpaper/test/*.test.js
bash ./vscode/wallpaper/install.sh
```

`install.sh` は明示的に実行する。ルートの `install.sh` から自動実行しない。初回実行時には VSIX 作成用の `@vscode/vsce` を `npx` が取得する。拡張機能の実行時に npm 依存はない。

## 設定

ユーザー設定（`~/.config/vscode/settings.json`）またはプロジェクトの `.vscode/settings.json` に以下を追加する。画像の保存場所は端末・プロジェクト側で管理し、リポジトリへは含めない。

```jsonc
{
  "vscodeWallpaper.enabled": true,
  "vscodeWallpaper.image": "~/Pictures/wallpaper-wide.jpg",
  "vscodeWallpaper.alternateImage": "~/Pictures/wallpaper-tall.jpg",
  "vscodeWallpaper.switchMode": "orientation",
  "vscodeWallpaper.maxAspectRatio": "16/10",
  "vscodeWallpaper.maxWidth": 1400,
  "vscodeWallpaper.tint": "#FFFFFF",
  "vscodeWallpaper.stickyScrollBlur": 12,
  "vscodeWallpaper.backgroundColors": {
    "editor": "theme",
    "sidebar": "theme",
    "panel": "theme",
    "auxiliaryBar": "theme",
    "chrome": "theme"
  },
  "vscodeWallpaper.opacity": {
    "editor": 0.70,
    "sidebar": 0.85,
    "panel": 0.85,
    "auxiliaryBar": 0.85,
    "chrome": 0.92
  }
}
```

- `image`：全画面共通の画像。`https://`、`file:///`、絶対パス、`~/`、`./` で指定できる。`./` は最初の作業フォルダーを基準にする。
- `alternateImage`：縦長・狭いウィンドウで使う画像。空文字なら切り替えない。
- `switchMode`：縦長・横長で切り替える `orientation`（既定）、任意の縦横比で切り替える `aspect-ratio`、横幅で切り替える `width`。
- `maxAspectRatio`：`16/10` なら縦横比が 1.6 以下で代替画像を表示する。
- `maxWidth`：`width` モードの切り替え幅（CSS ピクセル）。
- `tint`：画像に乗算する色。既定の白（`#FFFFFF`）は画像の色を変えない。`background-blend-mode: multiply` を使う。
- `backgroundColors`：領域別の背景色。`theme` で現在の VS Code テーマ色を使い、`#RRGGBB` で任意の色に変更できる。
- `opacity`：画像の上に重ねる各領域の背景色の不透明度。文字の不透明度は変更しない。`0` が透明、`1` が不透明。
- `stickyScrollBlur`：Sticky Scroll の固定コードの*背後*をぼかす強さ（CSS px）。既定 `12`、有効範囲 `0`～`30`、`0` ならぼかさない。固定表示の文字自体にはぼかしを適用しない。

※ 乗算するのは画像と `tint` の色である。各領域の `opacity` はその上に重ねる背景色の不透明度であり、乗算そのものとは別の設定である。

旧試作版 `takashit16833.rhb-wallpaper` を導入済みなら、`code --uninstall-extension takashit16833.rhb-wallpaper` で手動削除する。拡張機能 ID が変わるため、旧 `rhbWallpaper.*` 設定は `vscodeWallpaper.*` に移行する。

## 操作と検証

1. VS Code を再読み込みする。
2. `VS Code Wallpaper: Preview` を実行する。専用タブで背景画像と領域別の透過、ウィンドウ幅または縦横比に応じた切り替えを確認する。
3. ウィンドウサイズを変え、設定値も変更する。プレビューは変更時に再生成する。
4. `VS Code Wallpaper: Show Generated CSS` を実行する。表示された CSS は編集・保存できる。

## 実際の VS Code で一時的に試す（実機検証）

**この操作は自動では実行されない。** 公式 API から VS Code 本体の画面へ CSS を適用できないため、開発者ツールから現在の画面に一時的な CSS を適用する。VS Code 本体のファイル・整合性検査・設定ファイルには触れない。

1. `vscodeWallpaper.enabled` と `vscodeWallpaper.image` を設定する。まずは `https://` 画像 URL で確認する。
2. コマンドパレットで **VS Code Wallpaper: Show Temporary Workbench Script** を実行する。
3. 開いた JavaScript を読んでから全体をコピーする。
4. コマンドパレットで **Developer: Toggle Developer Tools** を開き、**Console** で実行する。対象は VS Code 本体の画面であり、Webview の開発者ツールではない。
5. 開発者ツールを閉じ、VS Code 全体に背景が見えるか、窓幅・縦横比による切り替えが動くか確認する。

前回の一時 CSS や診断用の変更が残っている場合は、最初に **Developer: Reload Window** で再読み込みする。更新した拡張機能の CSS は実画面に自動反映されないため、新しく生成したコードを改めて実行する。

浮動パネル（`floating-panels`）では、VS Code 側に通常の `.part.panel` より優先される `!important` の背景色があることを実機で確認済み。生成 CSS は浮動パネル専用の半透明背景規則も出力する。

同様に、浮動表示の左右サイドバーにも VS Code 標準の優先度の高い `!important` 背景色がある。実機で左サイドバーの不透明な色を確認し、`floatingPanels.css` の規則と同じ選択条件で半透明色を指定する。補助サイドバーについては CSS を用意したが、実機表示は未確認。

また、`paneHeaders.css` がサイドバー内部の `.monaco-pane-view .pane` と見出しを不透明にする。実機診断で `.pane.expanded` の背景が `rgb(1, 1, 20)` だったため、各ペインの背景と通常時の見出し背景を透明にする規則を追加した。ホバー時の強調色は保持する。実機での再検証は必要。

2026-11-03 の Extensions サイドバーの追加診断では、一覧コンテナ `.monaco-list-rows` の背景色 `rgb(1, 1, 20)` が残っていた（サイドバー高さ25%）。一覧コンテナだけを透明化する。個別の `.monaco-list-row` にある選択・ホバー表示には触れない。実機での反映は未確認。

### ターミナルを文字ごと透過せず、背景だけ透過する

VS Code のターミナルは Canvas に不透明な背景を描画するため、背景色の CSS だけでは透けないことを実機で確認した。次の **VS Code 標準設定** を追加した状態で、文字を残しながら背景画像が表示されることを確認済み。

```jsonc
{
  "terminal.integrated.enableImages": true,
  "workbench.colorCustomizations": {
    "terminal.background": "#00000000"
  }
}
```

既存の `workbench.colorCustomizations` がある場合は、その中へ `terminal.background` を追加する。ターミナルは設定変更後に作り直す。 `terminal.integrated.enableImages` は画像表示機能も有効にするため、背景を透過するだけの専用設定ではない。拡張機能から自動変更せず、利用するユーザーが設定する。領域としての背景色・不透明度は `vscodeWallpaper.backgroundColors.panel` と `vscodeWallpaper.opacity.panel` で調整する。

### 縦横比・幅による画像切り替えの実機検証

2枚目の画像を準備せずに切り替えを確認できる `VS Code Wallpaper: Show Responsive Test Script` を追加した。

1. コマンドパレットで実行し、「縦長・横長」または「横幅：800px」を選ぶ。
2. 表示された JavaScript を確認し、VS Code 本体の開発者ツール Console で実行する。
3. テスト画像は赤系（横長または800pxより広い）・青系（縦長または800px以下）。「縦長・横長」はウィンドウの幅と高さの大小関係が逆転したときに切り替わる。

現在の一時壁紙と置き換わるが、ユーザー設定は変更しない。画像は拡張機能内に埋め込んであり、外部へ通信しない。元の壁紙に戻すには `Show Temporary Workbench Script` を再実行する。一時適用自体を解除するには `Show Remove Script` か `Developer: Reload Window` を使う。

切り替えは実際の `generateCss` を使うが、ユーザーが指定する2枚の画像については別途実機確認が必要である。

### 実画面への自動適用について

VS Code の公開拡張 API では本体画面の DOM と CSS に直接アクセスできない。Webview も本体画面から隔離されている。現段階では、本体ファイルの変更や非公開 API に依存しない自動適用の実装方法は確認できていないため、自動適用は行わない。

### 残りの領域と画像の切り替えを診断する

1. **VS Code Wallpaper: Show Read-only Workbench Diagnostics** を実行し、開いた JavaScript を開発者ツールの Console で実行する。
2. 表示される表の `rect` が `0x0` の領域は非表示である。左側に見える領域は別の要素の場合があるため、`左側の重なり` の表を確認する。
3. `vscodeWallpaper.alternateImage` に別の画像を指定し、ウィンドウ幅または縦横比を変更する。`queryMatches` が切り替わることと、`rootBackgroundImage` の URL が変わることを確認する。

診断結果には「編集タブ・スクロールバー・パネル内の背景」と「個別要素の背景色」の表も出力する。Explorer・Source Control を下部パネルで表示している状態で実行すると、それぞれの表示領域の背景色をまとめて調べられる。

2026-11-03 の実機診断で、編集タブの帯 `.part.editor .tabs-and-actions-container` は `rgb(5, 10, 33)`、下部 Explorer の一覧背景 `.part.panel .monaco-list-rows` は `rgb(0, 30, 74)` で不透明と確認できた。この2つのコンテナ背景だけを透明化する。個別タブ、選択行、スクロールバーのつまみには触れない。Source Control を下部に表示したときの計測位置では、パネル本体以外の不透明な要素は検出されなかった。修正後の実機表示は要確認。

Search 見出しの `.part.sidebar > .composite.title` は実機で不透明な `rgb(1, 1, 20)` と確認できたため、背景色だけを透明化した。タブ・パンくず・スクロールバーの調査対象自体は透明なので、追加の背景色変更は描画元が特定できるまで行わない。

編集タブ・パンくずは対象要素自体が透明だったため、子要素と疑似要素の背景も調べる。ターミナル切り替え欄は `.terminal-tabs` が存在しなかったため、下部パネル右側の実際の重なりを調べる。追加の2表「タブとパンくずの背景を描く子要素」「ターミナル切り替え欄の描画要素」を参照する。

VS Code 本体の `modernUI/browser/media/tabs.css` では、タブの下地を `.tab-fill` が、タブ帯の背景画像を `.title.tabs` が描画する。`breadcrumbscontrol.css` では `.breadcrumbs-editor-type` に別の背景色があり、`terminal.css` はターミナル切り替え欄に `.tabs-container` / `.tabs-list-container` / `.tabs-list` を使う。これらの下地を個別に透明化し、タブの枠線や個別のターミナル選択行は維持する。`scrollbars.css` は背景とつまみを別々に描くため、スクロールバー本体の背景だけを透明化する。新規 CSS の実機確認は未完了。

この診断は読み取り専用であり、ファイル・DOM・設定を変更しない。CSS の実画面への適用は先に実施しておく。

**元に戻す場合**：**VS Code Wallpaper: Show Remove Script** で表示したコードを同じ Console で実行するか、**Developer: Reload Window** で再読み込みする。取り消しにアプリの再インストールは不要。

注意：開発者ツールでコードを実行する行為には危険があるため、必ず生成コードを確認すること。今回のコードは `CSSStyleSheet` と `document.adoptedStyleSheets` を使って一時的なスタイルを追加するだけで、ディスクへの書き込みやデバッグ用ポートの開放はしない。VS Code の内部 CSS は非公開なので、実画面への適用が成功するか、どの領域の透過が必要かは実機で確認する。

### Sticky Scroll（固定表示コード）の背景

編集画面上部に行番号 131、132、133 … のように複数行のコードが固定表示され、その部分だけ不透明な黒い帯になる場合がある。これはエディタの Sticky Scroll である。VS Code 本体の `stickyScroll.css` では `.sticky-widget-line-numbers`（行番号）と `.sticky-widget-lines-scrollable`（コード）に別々の背景色が指定され、子要素にもその色が継承される。

壁紙用 CSS では `.part.editor .monaco-editor .sticky-widget:not(.peek)` の2つの背景だけを透明化する。実機で背景が透けることを確認した一方、固定された文字とその下のコードが重なって読みにくくなったため、固定領域全体に `backdrop-filter: blur(12px)` を適用する。`backdrop-filter` は背後をぼかし、手前に固定表示された文字自体はぼかさない。`vscodeWallpaper.stickyScrollBlur` で `0`～`30` px に調整でき、`0` でぼかしなしに戻す。`peek` の内部エディタには適用しない。背景の透明化・固定表示・文字色・マウスを重ねたときの強調表示は維持する。ぼかし後の実画面での確認は未完了。

### Overview Ruler の黒い帯（Canvas 内部の背景）

2026-11-03 の実機診断で、スクロールバーと同じ位置にある `canvas.decorationsOverviewRuler` の5か所がすべて `rgba(1, 1, 17, 1)`（完全不透明）だった。スクロールバー本体はすでに透明であり、黒い帯の原因はこの Canvas 内で描画される背景色だと確認できた。

VS Code の `decorationsOverviewRuler.ts` は、標準の配色キー `editorOverviewRuler.background` が指定されればその色で Canvas を描画する。完全透明な色では Canvas をクリアしてから描画するため、dotfiles のユーザー設定 `.config/vscode/settings.json` 内の `workbench.colorCustomizations` に次を追加した。

```jsonc
{
  "workbench.colorCustomizations": {
    "editorOverviewRuler.background": "#00000000"
  }
}
```

この指定は拡張機能の CSS ではなく VS Code の**標準配色設定**として適用され、壁紙を一時的に外した場合にも残る。マーカーやスクロールバーのつまみの配色は変更しない。実機では設定を読み込んだ後、同じ Canvas の画素の `alpha` が 0 に変わるか確認する。なお、個々のマーカーが重なる画素では `alpha` が 0 以外になることがある。

### スクロールバーの下地とパンくずの透明化

VS Code の `scrollbars.css` は黒い背景に `background: var(--vscode-scrollbar-background)` を使い、スクロールバーのつまみには別変数 `--vscode-scrollbarSlider-background` を使う。背景変数と背景指定を透明化し、つまみ・ホバー表示の色は変更しない。

パンくずは `--vscode-breadcrumb-background` と帯・表示用コンテナの背景色および背景画像を透明にする。文字や選択表示は変更しない。いずれも実画面での再確認が必要である。

### パンくずとミニマップの透過

パンくずの表示用行 `.breadcrumbs-below-tabs` と内部の `.breadcrumbs-control` / `.monaco-breadcrumbs` の背景を透明化する。文字や区切り線はそのまま保持する。実機で効果を確認する。

画面右端の幅広い部分は **ミニマップ**（コードの縮小表示）であり、スクロールバーとは別である。VS Code はミニマップのコードと背景を Canvas に描くため、背景色だけを透明にする CSS では消せない。代わりに次の任意設定を追加した。

```jsonc
{
  "vscodeWallpaper.minimapOpacity": 0.35
}
```

`0` はミニマップを完全に見えなくし、`1` は完全に不透明とする。**縮小表示したコードも一緒に薄くなる**ことに注意する。設定なし（`null`）では VS Code 標準表示を変えない。スクロールバーのつまみは変更しない。表示自体が不要なら VS Code 標準の `"editor.minimap.enabled": false` で無効化できる。

設定を変えたら `Show Temporary Workbench Script` を再生成し、Console から適用する。適用中の CSS には自動反映されない。

**現段階では自動適用は未実装。** 拡張機能が VS Code の本体ファイルを書き換えたり、破損警告を隠したりすることはない。

縦長・横長の判定は CSS の `(orientation: portrait)` を使う。横幅と高さが同じ場合は縦長扱い。縦長から横長へ切り替えるには、横幅が高さを超えるようにウィンドウの幅と高さを調整する。
