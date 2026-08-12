# dotfiles

macOS 用の dotfiles。

## Configuration policy

設定ファイルは可能な限り XDG Base Directory に寄せる。

zsh の `.zshenv` で `XDG_CONFIG_HOME=$HOME/.config` を設定し、以降は `XDG_CONFIG_HOME` が存在する前提で構成する。zsh の startup file は `~/.config/zsh` に集約し、zsh が `ZDOTDIR` を知る前に読み込めるよう `~/.zshenv` だけは `~/.config/zsh/.zshenv` への symlink として配置する。

```text
~/.zshenv -> ~/dotfiles/.config/zsh/.zshenv
~/.config/zsh -> ~/dotfiles/.config/zsh
~/.config/wezterm -> ~/dotfiles/.config/wezterm
~/.config/lazygit/config.yml -> ~/dotfiles/.config/lazygit/config.yml
~/.config/starship.toml -> ~/dotfiles/.config/starship.toml
```

## Install

Homebrew をインストールした状態で実行する。

```bash
git clone git@github.com:takashit16833/dotfiles.git ~/dotfiles
cd ~/dotfiles
bash ./install.sh
```

既存の設定ファイルや symlink がある場合、`install.sh` は上書きせず停止する。必要なものを退避してから再実行する。

Hammerspoon は初回起動時にアクセシビリティ権限を許可する。

Colima は RAGScope の Dev Container build に必要なリソースを設定して起動する。

```bash
colima start --cpu 4 --memory 8
```

## Git identity

各 Mac で `~/.gitconfig.local` を作成する。

```bash
cat > ~/.gitconfig.local <<'EOF'
[user]
    name = YOUR_NAME
    email = YOUR_EMAIL
EOF
```

`~/.gitconfig.local` は dotfiles では管理しない。

## Uninstall

```bash
cd ~/dotfiles
bash ./uninstall.sh
```
