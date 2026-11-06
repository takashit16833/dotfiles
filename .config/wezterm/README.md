# WezTerm のワークスペース

ワークスペースの切り替えと背景の表示処理は dotfiles で管理し、登録する
ワークスペースは `~/.config/wezterm-local/workspaces.lua` で管理する。

## 初回設定

`install.sh` は初回だけ `workspaces.example.lua` をコピーする。
既存の `workspaces.lua` は上書きせず、アンインストールでも削除しない。

既存の Mac で dotfiles を更新した場合、`install.sh` 全体を再実行する必要はない。
次のコマンドでローカル設定を用意できる。

```bash
mkdir -p ~/.config/wezterm-local
cp -n ~/workspace/dotfiles/.config/wezterm/workspaces.example.lua \
  ~/.config/wezterm-local/workspaces.lua
```

## 使い方

- `Cmd+Shift+P`：登録したワークスペースを選択する。
- `shortcut` に登録したキー：直接切り替える。
- 未作成のワークスペースは選択時に指定した `cwd` で作成する。
- 起動時は WezTerm 標準の `default` のみを使う。

`workspaces.lua` の一覧に、必要なものを追加する。背景画像の設定例も
`workspaces.example.lua` に記載している。画像を設定しなければ通常の背景を使う。

## 旧設定からの移行

以前の `~/.config/wezterm-local/local.lua` は新しい構成では読み込まない。
必要な定義を `workspaces.lua` へ移し、`Default` は `default` に揃えると
WezTerm 標準のワークスペースが重複しない。

旧 `modules/workspaces.lua` にあった `RAGScope` と個別の画像パスは、
自動では移行しない。必要なものだけ新しいローカル設定へ記述する。

旧 `local.lua` と `.dotfiles-created` は自動削除しない。
移行を確認してから、不要なら手動で片付ける。
