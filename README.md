# dotfiles

macOS 用の dotfiles。

設定ファイル本体はこの repository を source of truth とし、Mac 側から symlink して利用する。

## Install

Homebrew をインストールした状態で実行する。

```bash
git clone git@github.com:takashit16833/dotfiles.git ~/dotfiles
cd ~/dotfiles
bash ./install.sh
```

`install.sh` は既存の実ファイルや別 symlink を勝手に上書きしない。既存設定がある場合は、内容を確認してから退避・統合する。

Hammerspoon は初回起動時にアクセシビリティ権限を許可する。

## Git の初回設定

`.gitconfig` は Mac 間で共有できる portable な設定だけを dotfiles で管理する。

以下は machine-local として repository には入れない。

- `user.name`
- `user.email`
- GitHub / GitLab などの認証情報
- credential helper の machine 固有設定
- SSH key / token

### 1. Git identity を作成する

各 Mac で `~/.gitconfig.local` を作成する。

```bash
cat > ~/.gitconfig.local <<'EOF'
[user]
    name = YOUR_NAME
    email = YOUR_EMAIL
EOF
```

個人 Mac と現場支給 Mac で異なる identity を使う場合は、それぞれの Mac に適切な値を設定する。

共通 `.gitconfig` では `user.useConfigOnly = true` を有効にしているため、identity が未設定のまま Git が自動推測して commit することを防ぐ。

### 2. 既存の ~/.gitconfig がある場合

`install.sh` は既存ファイルを上書きしないため、古い `~/.gitconfig` が実ファイルとして存在する場合は、必要な設定を確認したうえで退避する。

```bash
mv ~/.gitconfig ~/.gitconfig.before-dotfiles
```

その後に `bash ./install.sh` を実行すると、repository の `.gitconfig` への symlink が作成される。

### 3. GitHub CLI / Git 認証

認証は Mac ごとに設定し、dotfiles では管理しない。

`gh` の認証状態は以下で確認する。

```bash
gh auth status
```

`gh auth setup-git` は GitHub CLI を Git の credential helper として global Git config に設定するため、この dotfiles では原則として使用しない。実行する場合は `.gitconfig` に machine 固有設定が追加されないか確認する。

Git の HTTPS / SSH 認証方式は、利用する Mac や現場のポリシーに合わせて設定する。

### 4. Git 設定の確認

```bash
git config --show-origin --show-scope --list
git ls-remote origin HEAD
```

設定の出所と remote への接続を確認できる。

## Uninstall

```bash
cd ~/dotfiles
bash ./uninstall.sh
```

設定ファイルのシンボリックリンクのみ削除する。Homebrew パッケージと `~/.gitconfig.local` は削除しない。

## パッケージ一覧

### CLI

- Colima
- Docker CLI
- Docker Compose
- fzf
- gh
- git-delta
- jq
- lazygit
- ripgrep
- Starship
- zoxide

### Applications

- Hammerspoon
- Obsidian
- Visual Studio Code
- WezTerm Nightly
