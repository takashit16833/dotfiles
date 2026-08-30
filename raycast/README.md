# Raycast

Raycast のうち、Git で直接管理しにくい設定について、再構築時に必要な内容を記録する。

Raycast 本体のインストールはルートの `Brewfile` で管理する。
Script Commands や自作 Extension など、通常のテキストファイルとして管理できるものはこのディレクトリ配下に置く。

## Hotkeys

| Command | Hotkey |
|---|---|
| Root Search | `⌥ Space` |
| Clipboard History | `⌃⌘V` |

## Script Commands

将来的に Script Commands を追加する場合は、次のディレクトリで Git 管理する。

```text
~/dotfiles/raycast/scripts
```

Raycast 側では、このディレクトリを Script Commands の検索対象として登録する。

## Local Extension

`raycast/extension` は、dotfiles で管理する自作 Raycast コマンドをまとめる唯一の Local Extension とする。
動的な一覧表示など Raycast Extension API が必要な機能は、機能ごとに npm project を増やさず、この Extension に command を追加する。

`bash install.sh` は Node.js/npm の導入、依存 package の取得、production build、`~/.config/raycast/extensions/dotfiles-commands` への配置まで自動で行う。
build は `ray build -e dist -o <directory>` のように output directory を明示し、Raycast app を起動せずに実行する。

installer では `ray develop` を使用しない。普段の利用時に `npm run dev` を起動しておく必要はなく、Extension のソースを変更して手元で開発するときだけ `npm run dev` を使う。

install 時はいったん staging directory へ build し、生成された `package.json` の `name` が `dotfiles-commands` と一致することを確認してから installed directory と入れ替える。

### GitHub Repositories

GitHub CLI (`gh`) で認証しているアカウントからアクセス可能な repository を取得し、Raycast 上で曖昧検索してブラウザで開く command。

認証情報は Raycast 側へ保存せず、既存の `gh` 認証をそのまま利用する。
command に `gh` / `github` を検索 keyword として持たせるため、Root Search で `gh` と入力して起動できる。必要なら Raycast 側で Alias `gh` を設定して優先順位を固定してもよい。

前提として GitHub CLI がインストール済みで、`gh auth login` による認証が完了していること。
Extension はログインシェルから `gh` の実体を解決するため、Homebrew のインストール先を固定値では持たない。

## Uninstall

`bash uninstall.sh` は `raycast/extension/node_modules` / `dist` に加えて、`~/.config/raycast/extensions/dotfiles-commands` を manifest で識別したうえで削除する。
中断時に残り得る `.dotfiles-commands.staging.*` も削除する。

Raycast の内部 database は直接操作しない。dotfiles が配置した extensions directory 上のファイルだけを管理し、他の Extension には触れない。

## 管理方針

- Raycast 本体: `Brewfile` で管理する。
- Script Commands / 自作 Extension: ソースコードを Git で管理する。
- 自作 Extension は `raycast/extension` の 1 project に集約し、機能ごとに npm project を増やさない。
- `install.sh` は Local Extension の dependency install / headless production build / manifest 検証 / 配置まで自動化する。
- `npm run dev` / `ray develop` は開発時だけ利用し、環境構築には使わない。
- Hotkey / Alias など Raycast 内部の設定: Raycast 側で設定し、この README に再構築手順を記録する。
- Clipboard History / AI 履歴 / Notes などの個人データ: Git では管理しない。
- `.rayconfig`: Raycast 自身のバックアップ用途として扱い、dotfiles には含めない。
