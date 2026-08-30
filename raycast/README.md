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

## Local Extensions

### GitHub Repositories

`raycast/extensions/github-repositories` は、GitHub CLI (`gh`) で認証しているアカウントからアクセス可能な repository を取得し、Raycast 上で曖昧検索してブラウザで開くための Extension。

認証情報は Raycast 側へ保存せず、既存の `gh` 認証をそのまま利用する。

初回セットアップ:

```sh
cd ~/dotfiles/raycast/extensions/github-repositories
npm install
npm run dev
```

または Raycast の `Import Extension` から `raycast/extensions/github-repositories` を選択する。

Raycast の Extensions 設定で `GitHub Repositories` コマンドの Alias を `gh` に設定する。
以後は Root Search で `gh` を入力し、repository 名を曖昧検索して Enter で GitHub の repository page を開く。

前提として GitHub CLI がインストール済みで、`gh auth login` による認証が完了していること。
Extension はログインシェルから `gh` の実体を解決するため、Homebrew のインストール先を固定値では持たない。

## 管理方針

- Raycast 本体: `Brewfile` で管理する。
- Script Commands / 自作 Extension: ソースコードを Git で管理する。
- Hotkey / Alias など Raycast 内部の設定: Raycast 側で設定し、この README に再構築手順を記録する。
- Clipboard History / AI 履歴 / Notes などの個人データ: Git では管理しない。
- `.rayconfig`: Raycast 自身のバックアップ用途として扱い、dotfiles には含めない。
