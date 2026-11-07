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
- `default_workspace`：起動時に開くワークスペース名。省略時は `default`。
- 起動時にはそのワークスペースだけを開く。作業フォルダは登録した `cwd` を使う。

`workspaces.lua` の `return {` の直下に `default_workspace = "Project",` と
指定できる。指定する名前は、同じファイル内の `name` と一致させる。
すでに作成済みのローカル設定も、先頭にこの1行を追加するだけでよい。

`workspaces.lua` の一覧に、必要なものを追加する。背景画像の設定例も
`workspaces.example.lua` に記載している。画像を設定しなければ通常の背景を使う。

## 賢いコピー

WezTerm 上の zsh では `Cmd+C` を次のように使い分ける。

- 文字列を選択している場合：選択範囲をコピーする。
- 未選択の場合：直前のコマンドと実行結果をまとめてコピーする。
- Emacs や lazygit などの端末アプリ：従来どおりキー入力を渡す。

更新後は新しい zsh を起動する。履歴から消えた古い実行結果や、
画面を専有するアプリの出力は対象外。

## 旧設定からの移行

以前の `~/.config/wezterm-local/local.lua` は新しい構成では読み込まない。
必要な定義を `workspaces.lua` へ移し、`Default` は `default` に揃えると
WezTerm 標準のワークスペースが重複しない。

旧 `modules/workspaces.lua` にあった `RAGScope` と個別の画像パスは、
自動では移行しない。必要なものだけ新しいローカル設定へ記述する。

旧 `local.lua` と `.dotfiles-created` は自動削除しない。
移行を確認してから、不要なら手動で片付ける。
