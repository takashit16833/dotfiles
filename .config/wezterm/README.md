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

背景画像をまとめて無効にするには、`return {` の直下に
`background_enabled = false,` を追加する。`true` または省略時は有効。
全ワークスペース共通の設定なので、個別の背景画像設定を削除する必要はない。

## WezTerm だけ配色を切り替える

通常は Emacs と共有する `~/.config/retro-theme` の選択を使う。
新しい **Noctis Blue One Dark** 配色を WezTerm だけで試すには、次を実行する。

```bash
mkdir -p ~/.config/wezterm-local
printf '%s\\n' 'noctis-blue-one-dark' > ~/.config/wezterm-local/theme
```

背景は One Dark 寄りの `#202733`、基本文字は Noctis Blue の
`pale`（`#A6CAFF`）、カーソルと赤系は `#FF4DE1` を使う。
元の選択へ戻すには、上で作成した `~/.config/wezterm-local/theme` を削除する。

```bash
rm ~/.config/wezterm-local/theme
```

この切り替えは Emacs のテーマ選択を変更しない。WezTerm は設定ファイルの
変更を検知して再読み込みする。背景画像を使用している場合は、画像が配色の
見え方に影響するため、単色背景で比較する場合は `workspaces.lua` の
`background_enabled = false` を指定する。

WezTerm 側で変更するのは端末の基本色と ANSI 16色であり、端末内のアプリが
独自に指定した構文色はアプリ側の設定に従う。

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
