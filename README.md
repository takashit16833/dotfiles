# dotfiles

macOS 用の dotfiles。

## Install

Homebrew をインストールした状態で実行する。

```bash
git clone git@github.com:takashit16833/dotfiles.git ~/dotfiles
cd ~/dotfiles
bash ./install.sh
```

Hammerspoon は初回起動時にアクセシビリティ権限を許可する。

## Uninstall

```bash
cd ~/dotfiles
bash ./uninstall.sh
```

設定ファイルのシンボリックリンクのみ削除する。Homebrew パッケージは削除しない。

## パッケージ一覧

### CLI

- Colima
- Docker CLI
- Docker Compose
- fzf
- gh
- jq
- lazygit
- ripgrep
- Starship
- zoxide

### Applications

- Hammerspoon
- Visual Studio Code
- WezTerm Nightly
