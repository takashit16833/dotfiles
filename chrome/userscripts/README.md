# Userscripts

Tampermonkey で使うユーザースクリプトを管理する。

## ChatGPT completion notification

`chatgpt-notify.user.js` は ChatGPT の回答生成完了を検知し、localhost の Hammerspoon HTTP server へ通知する。

Hammerspoon 側では通知元の ChatGPT タブがフォーカスされている場合は何もせず、別タブや別アプリを操作している場合だけ、スレッド名と直前の質問冒頭を `hs.alert` で 3 秒表示する。

### Setup

1. Brave に Tampermonkey をインストールする。
2. Tampermonkey の「ユーザー スクリプトを許可する」を有効にする。
3. `chatgpt-notify.user.js` の内容を Tampermonkey の新規スクリプトへ登録する。
4. ChatGPT のタブを再読み込みする。

Brave のデベロッパーモードは不要。

スクリプトが実行されない場合は、Tampermonkey の拡張機能をいったん無効化してから有効化するか Brave を完全終了して再起動し、ChatGPT を再読み込みする。

Hammerspoon 側は `.hammerspoon/modules/chatgpt_notify.lua` を `init.lua` から読み込むため、dotfiles の通常セットアップ以外の追加作業は不要。
