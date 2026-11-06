# Obsidian の CSS

## 有効化

Obsidian の Config Layer で `retro-hacker-blue-base.css` を有効にする。背景画像も使う場合は `retro-hacker-blue-wallpaper.css` と `retro-hacker-blue-wallpaper-local.css` も有効にする。

背景画像を使わない場合、ローカル CSS を無効にする。

## 背景画像

Git 管理外の `obsidian/css/retro-hacker-blue-wallpaper-local.css` を作成する。

```css
:root {
  --rhb-wallpaper-image: url("画像のURL");
}
```

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
