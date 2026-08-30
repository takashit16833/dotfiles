# YouTube Keyboard Navigator

自分用の Chromium 系ブラウザ拡張。YouTube の動画一覧をキーボードだけで選択して開く。

## 操作

| Key | Action |
|---|---|
| `Ctrl+Shift+Y` | 選択モード ON/OFF |
| `←` `↑` `↓` `→` | 近い動画カードへ移動 |
| `Enter` | 選択中の動画を開く |
| `Esc` | 選択モードを終了 |

選択モード外では YouTube 標準のキーボード操作を横取りしない。

## Install

Chrome / Brave の unpacked extension として読み込む。

### Brave

1. `brave://extensions` を開く。
2. Developer mode を有効にする。
3. `Load unpacked` を押す。
4. `~/dotfiles/chrome/youtube-keyboard` を選ぶ。

### Chrome

1. `chrome://extensions` を開く。
2. Developer mode を有効にする。
3. `Load unpacked` を押す。
4. `~/dotfiles/chrome/youtube-keyboard` を選ぶ。

一度読み込めば、ソースを変更したときは Extensions 画面の Reload で反映できる。

## Security

- Manifest V3 を使用する。
- content script は `https://www.youtube.com/*` でだけ実行する。
- `tabs`、`storage` などの追加 permission は要求しない。
- 外部 API や外部サーバーへの通信は行わない。
- background / service worker は持たない。

## 管理方針

この拡張は「自分の PC 操作環境を再構築するための設定」の一部として dotfiles で管理する。
独立したプロダクトとして育てたくなった場合のみ専用 repository へ切り出す。
