# VS Code Wallpaper（試作）

画面全体の壁紙の **CSS 生成・プレビュー・一時適用・任意の自動適用** を行う拡張機能。共通のユーザー設定を基本とし、プロジェクトの `.vscode/settings.json` で項目ごとに上書きできる。

自動適用は既定で無効である。手動で有効化する場合に限り、VS Code 本体の起動用 HTML に壁紙用読み込みスクリプトを追加する。元の HTML を保管し、復元できるようにする。自動適用の実機検証は未完了である。

## 現在の状態

- 全画面壁紙、乗算、領域別不透明度、画像の縦横切り替えを実機で確認済み。
- スクロールバーの黒い帯、パンくず、Sticky Scroll のぼかしも実機で確認済み。
- Markdown Preview / Markdown Live Preview では、背景とインライン・ブロックコードの半透明化を実機で確認済み（各 Markdown 拡張の CSS で設定）。
- VS Code 内蔵の Markdown Editor は独自 CSS の適用対象外。
- 開発者ツールでの一時適用に加え、作業フォルダー別の起動時自動適用に対応（実機検証待ち）。

## 導入・テスト

```bash
cd ~/dotfiles
node --test vscode/wallpaper/test/*.test.js
bash ./vscode/wallpaper/install.sh
```

`install.sh` は明示的に実行する。ルートの `install.sh` から自動実行しない。初回実行時には VSIX 作成用の `@vscode/vsce` を `npx` が取得する。拡張機能の実行時に npm 依存はない。

## 共通設定とプロジェクト設定

VS Code の **Preferences: Open User Settings (JSON)** から開くユーザー設定は、すべてのプロジェクトに共通する値である。例えば壁紙の画像を共通設定では指定しない場合、次のように設定する。

```jsonc
{
  "vscodeWallpaper.enabled": true,
  "vscodeWallpaper.image": null,
  "vscodeWallpaper.opacity": {
    "editor": 0.70,
    "sidebar": 0.85,
    "panel": 0.85,
    "auxiliaryBar": 0.85,
    "chrome": 0.92,
    "gap": 0.70
  }
}
```

壁紙を使いたいプロジェクトだけ、そのプロジェクトの `.vscode/settings.json` に画像を指定する。

```jsonc
{
  "vscodeWallpaper.image": "https://example.org/project-wallpaper.jpg"
}
```

**ユーザー設定 → プロジェクト設定 → 既定値** の優先順位で、VS Code が合成した設定値を利用する。`image: null` または `""` のまま画像が指定されていないウィンドウでは、エラーにせず壁紙を表示しない。色や不透明度など、プロジェクト側で上書きしない項目は共通設定を使う。

## 起動時の自動適用（任意）

自動適用には初回だけ導入操作が必要である。VS Code 本体の起動用 HTML に読み込みスクリプトへの参照を追加するため、**VS Code のインストール整合性警告が発生する可能性がある**。本体の元ファイルはバックアップし、整合性警告を隠す変更はしない。従来の開発者ツールでの一時適用も利用できる。

1. `bash ./vscode/wallpaper/install.sh` で拡張機能を更新し、VS Code を再読み込みする。
2. ユーザー設定の `vscodeWallpaper.enabled` を `true` にする。共通画像を使わない場合は `vscodeWallpaper.image: null` とし、プロジェクトの `.vscode/settings.json` に画像を指定する。
3. コマンド **VS Code Wallpaper: Enable Automatic Wallpaper** を実行する。確認画面で許可した場合だけ導入する。
4. 表示される **Reload Window** で再読み込みする。以後はウィンドウごとに適切な CSS が読み込まれる。

自動適用は VS Code のウィンドウごとの作業領域 ID に対応した別々の CSS ファイルを生成する。画像を指定しないウィンドウでは空の CSS を使用する。現時点ではユーザープロファイルごとの分離には対応せず、同じ作業領域を別プロファイルで開く場合は CSS が共有される。ワークスペース相対パス `./` は最初の作業フォルダーを基準に解決するが、複数ルートの場合は混乱を避けるため絶対パスを推奨する。リモート開発環境のローカル画像パスには別途制約がある。

ユーザー設定やプロジェクト設定を保存すると、拡張機能がそのウィンドウの CSS を更新する。画面側の読み込み処理は約2秒ごとに内容を確認し、**変更された場合だけ CSS を差し替える**。通常は **Developer: Reload Window は不要**。まだ CSS がない新しいプロジェクトでも、拡張機能が生成した後に表示される。読み込みはローカルファイルから行い、デバッグ用ポートは使わない。

**v0.5.0 からの更新時のみ**、古い読み込み処理から切り替えるために追加の **Reload Window** が一度必要である。拡張機能が旧ファイルを確認して安全に更新し、再読み込みの案内を表示する。自動適用の有効化をやり直す必要はない。

**解除：** コマンド **VS Code Wallpaper: Disable Automatic Wallpaper** はバックアップから HTML を復元し、管理中の CSS を削除する。別の方法で HTML や読み込みスクリプトが変更されていた場合は復元を中止する。旧バージョンの共通 CSS 方式からも、元ファイルのバックアップを維持したまま移行する。

アプリの配置場所への書き込み権限がない場合は導入できない。拡張機能が権限を勝手に変更することはない。

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
    "chrome": "theme",
    "gap": "theme"
  },
  "vscodeWallpaper.opacity": {
    "editor": 0.70,
    "sidebar": 0.85,
    "panel": 0.85,
    "auxiliaryBar": 0.85,
    "chrome": 0.92,
    "gap": 0.70
  }
}
```

- `image`：画像はユーザー設定の共通値をプロジェクト設定で上書きできる。`https://`、`file:///`、絶対パス、`~/`、`./` で指定できる。`null` または空文字の場合は壁紙を表示しない。`./` は最初の作業フォルダーを基準にする。
- `alternateImage`：縦長・狭いウィンドウで使う画像。空文字なら切り替えない。
- `switchMode`：縦長・横長で切り替える `orientation`（既定）、任意の縦横比で切り替える `aspect-ratio`、横幅で切り替える `width`。
- `maxAspectRatio`：`16/10` なら縦横比が 1.6 以下で代替画像を表示する。
- `maxWidth`：`width` モードの切り替え幅（CSS ピクセル）。
- `tint`：画像に乗算する色。既定の白（`#FFFFFF`）は画像の色を変えない。`background-blend-mode: multiply` を使う。
- `backgroundColors`：領域別の背景色。`theme` で現在の VS Code テーマ色を使い、`#RRGGBB` で任意の色に変更できる。
- `opacity`：画像の上に重ねる各領域の背景色の不透明度。文字の不透明度は変更しない。`0` が透明、`1` が不透明。`gap` の既定値は `0`（透明）で、上記の `0.70` は調整例である。
- `stickyScrollBlur`：Sticky Scroll の固定コードの*背後*をぼかす強さ（CSS px）。既定 `12`、有効範囲 `0`～`30`、`0` ならぼかさない。固定表示の文字自体にはぼかしを適用しない。

`gap` は VS Code の浮動パネル間と外周の余白専用である。`floatingPanels.css` の余白に合わせ、`.split-view-view` の擬似要素でカードの内側を塗らずに描く。カードの不透明度・枠線・サイズ・操作領域は変更しない。浮動パネル以外やコンパクト表示では適用しない。**実機での反映は未確認**なので、導入後に隙間とカードの見た目を確認する。

※ 乗算するのは画像と `tint` の色である。各領域の `opacity` はその上に重ねる背景色の不透明度であり、乗算そのものとは別の設定である。

旧試作版 `takashit16833.rhb-wallpaper` を導入済みなら、`code --uninstall-extension takashit16833.rhb-wallpaper` で手動削除する。拡張機能 ID が変わるため、旧 `rhbWallpaper.*` 設定は `vscodeWallpaper.*` に移行する。

## 操作と検証

1. VS Code を再読み込みする。
2. `VS Code Wallpaper: Preview` を実行する。専用タブで背景画像と領域別の透過、ウィンドウ幅または縦横比に応じた切り替えを確認する。
3. ウィンドウサイズを変え、設定値も変更する。プレビューは変更時に再生成する。
4. `VS Code Wallpaper: Show Generated CSS` を実行する。表示された CSS は編集・保存できる。

## 実際の VS Code で一時的に試す（実機検証）

**この一時適用操作は自動では実行されない。** 公式 API から VS Code 本体の画面へ CSS を適用できないため、開発者ツールから現在の画面に一時的な CSS を適用する。VS Code 本体のファイル・整合性検査・設定ファイルには触れない。

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

VS Code の公開拡張 API では本体画面の DOM と CSS に直接アクセスできない。Webview も本体画面から隔離されている。そのため自動適用は、本体 HTML に管理用の CSS リンクを追加する任意の方式として実装した。手動の一時適用方式では本体を変更しない。

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

壁紙用 CSS では `.part.editor .monaco-editor .sticky-widget:not(.peek)` の2つの背景だけを透明化する。実機で背景が透けることを確認した一方、固定された文字とその下のコードが重なって読みにくくなったため、固定領域全体に `backdrop-filter: blur(12px)` を適用する。`backdrop-filter` は背後をぼかし、手前に固定表示された文字自体はぼかさない。`vscodeWallpaper.stickyScrollBlur` で `0`～`30` px に調整でき、`0` でぼかしなしに戻す。`peek` の内部エディタには適用しない。背景の透明化・固定表示・文字色・マウスを重ねたときの強調表示は維持する。2026-11-03 に実機でぼかしと文字の読みやすさを確認済み。

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

### スクロールバー・パンくず・ミニマップ

スクロールバーの下地（`--vscode-scrollbar-background`）とパンくずの帯・内側の背景を透明化する。文字、境界線、スクロールバーのつまみは変更しない。実機で表示を確認済み。

右端のミニマップは縮小コードと背景を同じ Canvas に描くため、背景だけを CSS で透明化できない。任意の設定 `vscodeWallpaper.minimapOpacity` に `0`～`1` を指定すると、縮小コードごと薄くする。既定値 `null` では変更しない。スクロールバーのつまみは対象外である。

スクロールバーと重なる `canvas.decorationsOverviewRuler` の黒い背景は別の Canvas 描画であり、VS Code 標準設定 `"editorOverviewRuler.background": "#00000000"` で透明にする。これは `workbench.colorCustomizations` に指定するもので、壁紙の CSS を解除しても残る。

**自動適用は任意で、既定では無効。** 自動適用を許可した場合だけ起動用 HTML を変更するが、整合性警告を隠したり、既存のチェックサムを書き換えたりする処理は行わない。

縦長・横長の判定は CSS の `(orientation: portrait)` を使う。横幅と高さが同じ場合は縦長扱い。縦長から横長へ切り替えるには、横幅が高さを超えるようにウィンドウの幅と高さを調整する。
