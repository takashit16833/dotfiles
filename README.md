# dotfiles

Personal dotfiles for macOS.

The repository is the source of truth. Files under `$HOME` are linked back to this repository by the installer.

## Install

```bash
git clone git@github.com:takashit16833/dotfiles.git ~/dotfiles
cd ~/dotfiles
bash ./install.sh
```

The installer is idempotent:

- If the expected symlink already exists, nothing is changed.
- Existing real files/directories are never overwritten.
- Symlinks pointing somewhere else are never replaced automatically.

If an old configuration file already exists, move or remove it explicitly after reviewing it, then run the installer again. The installer never overwrites it automatically.

## Uninstall

```bash
cd ~/dotfiles
bash ./uninstall.sh
```

The uninstaller is also idempotent and removes only symlinks that point to this repository. It does not delete the dotfiles repository or unrelated files.

## Managed configuration

Currently managed:

- `~/.config/wezterm` -> `~/dotfiles/.config/wezterm`
- `~/.config/starship.toml` -> `~/dotfiles/.config/starship.toml`
- `~/.zshrc` -> `~/dotfiles/.zshrc`

The zsh configuration intentionally starts small. New shell settings are added only when they are actually needed during the environment refresh.

More configuration will be added only when it is actually needed.
