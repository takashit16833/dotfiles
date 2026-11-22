# Obsidian の CSS

## 有効化

Obsidian の **Config Layer** で CSS を有効にする。Obsidian の外観は「デフォルト」テーマ、配色はダークモードを使用する。

- **Retro Hacker Blue**：`retro-hacker-blue-base.css` を有効にし、`noctis-blue-one-dark.css` は無効にする。
- **Noctis Blue One Dark**：`retro-hacker-blue-base.css` と `noctis-blue-one-dark.css` を両方有効にする。One Dark 側は共通の装飾を残したまま配色を上書きする。

背景画像も使う場合は、どちらの配色でも `retro-hacker-blue-wallpaper.css` と `retro-hacker-blue-wallpaper-local.css` を追加で有効にする。従来の壁紙設定は共通で使用でき、Noctis Blue One Dark の背景色は `#161C28`、カーソルと操作の青は `#5EAFFF`、赤系は `#FF4DE1` になる。

背景画像を使わない場合は、ローカル壁紙 CSS を無効にする。配色だけを戻すには `noctis-blue-one-dark.css` を無効にすればよい。

dotfiles を更新した後は、Obsidian のコマンドパレットから **Config Layer: Refresh shared configuration** を実行して CSS を更新する。

## 背景画像

Git 管理外の `obsidian/css/retro-hacker-blue-wallpaper-local.css` を作成する。

```css
:root {
  --rhb-wallpaper-image: url("~/Pictures/wallpaper.jpg");
}
```

`~/` はホームディレクトリを表す。HTTP(S) の画像 URL も指定できる。画像ファイル自体を変更した場合は、Obsidian のコマンドパレットから `Config Layer: Refresh shared configuration` を実行する。

## 背景の不透明度

同じローカル CSS で指定する。

```css
html body.theme-dark {
  --rhb-wallpaper-panel-opacity: 50%;
  --rhb-wallpaper-sidebar-opacity: 70%;
  --rhb-wallpaper-block-opacity: 45%;
}
```

- `panel-opacity`：エディタなどの主要領域（既定値 83%）
- `sidebar-opacity`：左右のサイドバー（既定値 90%）
- `block-opacity`：コードブロックやダイアログなど（既定値 45%）

値を小さくすると背景が透け、壁紙がよく見える。必要な項目だけ指定すればよい。

## ウィンドウの縦横比で画像を切り替える

ローカル CSS の画像指定を次のようにする。

```css
:root {
  --rhb-wallpaper-image: url("横長画面用の画像URL");
}

@media (max-aspect-ratio: 16/10) {
  :root {
    --rhb-wallpaper-image: url("縦長画面用の画像URL");
  }
}
```

ウィンドウの幅 ÷ 高さが `16/10` 以下になると2枚目に切り替わる。切り替え条件は変更できる。壁紙は画面全体に1枚だけ表示し、色の乗算と透過の設定はそのまま維持する。
