# 手動設定

`install.sh` だけでは設定されない項目。

## Brave を ChatGPT ビューアにする

Brave の起動時、新しいウィンドウ、新しいタブで `https://chatgpt.com/` を開く。設定は Brave 上で手動で行う。

1. `brave://settings/appearance` を開く。
   - **Show home button** を有効にする。
   - URL を `https://chatgpt.com/` にする。
2. `brave://settings/getStarted` を開く。
   - **New Tab Page** → **New tab page shows** → **Homepage**
   - **On startup** → **Open the New Tab page**

設定後は、Brave の起動、`Cmd+N`、`Cmd+T` で ChatGPT が開く。

## スクロールバー

macOS の **システム設定** → **外観** → **スクロールバーを表示** で **スクロール時に表示** を選ぶ。

## 各ツールの初回設定

- VS Code のテーマ・背景画像・透過：[Noctis Blue の README](https://github.com/takashit16833/vscode-noctis-blue#readme)
- Obsidian の背景画像：[Obsidian CSS の README](../obsidian/css/README.md)
- YouTube のブラウザ拡張：[YouTube Keyboard Navigator の README](../chrome/youtube-keyboard/README.md)
- ChatGPT 通知用の Tampermonkey スクリプト：[Userscripts の README](../chrome/userscripts/README.md)

ブラウザ拡張や Web アプリの初回登録は、ブラウザ側で行う。
