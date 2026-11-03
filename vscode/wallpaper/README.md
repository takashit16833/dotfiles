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
  "vscodeWallpaper.switchMode": "aspect-ratio",
  "vscodeWallpaper.maxAspectRatio": "16/10",
  "vscodeWallpaper.maxWidth": 1400,
  "vscodeWallpaper.tint": "#FFFFFF",
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
- `switchMode`：縦横比で切り替える `aspect-ratio`、横幅で切り替える `width`。
- `maxAspectRatio`：`16/10` なら縦横比が 1.6 以下で代替画像を表示する。
- `maxWidth`：`width` モードの切り替え幅（CSS ピクセル）。
- `tint`：画像に乗算する色。既定の白（`#FFFFFF`）は画像の色を変えない。`background-blend-mode: multiply` を使う。
- `backgroundColors`：領域別の背景色。`theme` で現在の VS Code テーマ色を使い、`#RRGGBB` で任意の色に変更できる。
- `opacity`：画像の上に重ねる各領域の背景色の不透明度。文字の不透明度は変更しない。`0` が透明、`1` が不透明。

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

**元に戻す場合**：**VS Code Wallpaper: Show Remove Script** で表示したコードを同じ Console で実行するか、**Developer: Reload Window** で再読み込みする。取り消しにアプリの再インストールは不要。

注意：開発者ツールでコードを実行する行為には危険があるため、必ず生成コードを確認すること。今回のコードは `CSSStyleSheet` と `document.adoptedStyleSheets` を使って一時的なスタイルを追加するだけで、ディスクへの書き込みやデバッグ用ポートの開放はしない。VS Code の内部 CSS は非公開なので、実画面への適用が成功するか、どの領域の透過が必要かは実機で確認する。

**現段階では自動適用は未実装。** 拡張機能が VS Code の本体ファイルを書き換えたり、破損警告を隠したりすることはない。
