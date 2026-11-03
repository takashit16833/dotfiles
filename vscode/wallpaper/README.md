# VS Code Wallpaper（試作）

VS Code 本体を変更せず、画面全体に表示する壁紙の **CSS 生成とプレビュー** を行う独立した拡張機能。

現段階で **VS Code の編集画面全体への適用は行わない**。公式拡張機能 API にその操作がなく、未検証の本体書き換えによる破損警告を再発させないためである。プレビューは専用タブに擬似的な画面構成を表示するものであり、実際の VS Code の画面で動作することを保証しない。

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

**この時点では VS Code 本体のファイルは変更せず、破損警告の抑制処理も含まない。** 次の段階では実際の VS Code の DOM/CSS への適用方法、既存のテーマとの干渉、ローカル画像の読み込みを別環境で実測する必要がある。
