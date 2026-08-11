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

## Uninstall

```bash
cd ~/dotfiles
bash ./uninstall.sh
```

The uninstaller is also idempotent and removes only symlinks that point to this repository. It does not delete the dotfiles repository or unrelated files.

## Managed configuration

Currently managed:

- `~/.config/wezterm` -> `~/dotfiles/.config/wezterm`

More configuration will be added only when it is actually needed.
