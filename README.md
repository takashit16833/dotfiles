# dotfiles

Personal dotfiles for macOS.

The repository is the source of truth. Homebrew packages are declared in `Brewfile`, and files under `$HOME` are linked back to this repository by the installer.

## Prerequisite

Homebrew must already be installed on macOS.

The installer intentionally does not install Homebrew itself. Once Homebrew is available, the rest of the currently managed environment is installed from this repository.

## Install

```bash
git clone git@github.com:takashit16833/dotfiles.git ~/dotfiles
cd ~/dotfiles
bash ./install.sh
```

The installer performs these steps in order:

1. Runs `brew bundle --file=Brewfile --no-upgrade`.
2. Installs packages that are missing from the Brewfile-managed environment.
3. Links the managed configuration files into `$HOME`.

The installer is idempotent:

- Existing Brewfile dependencies are reused instead of being installed again.
- Existing packages are not intentionally upgraded on every installer run.
- If the expected symlink already exists, nothing is changed.
- Existing real files/directories are never overwritten.
- Symlinks pointing somewhere else are never replaced automatically.

If an old configuration file already exists, move or remove it explicitly after reviewing it, then run the installer again. The installer never overwrites it automatically.

## Homebrew packages

`Brewfile` is intentionally curated rather than generated from every package currently installed on the Mac.

Currently managed:

- WezTerm Nightly
- Starship
- fzf
- zoxide
- lazygit

Homebrew is a rolling-release package manager, so the Brewfile describes which tools should exist rather than pinning exact versions.

## Uninstall

```bash
cd ~/dotfiles
bash ./uninstall.sh
```

The uninstaller is also idempotent and removes only symlinks that point to this repository. It does not uninstall Homebrew packages, delete the dotfiles repository, or touch unrelated files.

Homebrew packages are deliberately left installed during uninstall because they may be used independently of this dotfiles repository.

## Managed configuration

Currently managed:

- `~/.config/wezterm` -> `~/dotfiles/.config/wezterm`
- `~/.config/starship.toml` -> `~/dotfiles/.config/starship.toml`
- `~/.zshrc` -> `~/dotfiles/.zshrc`

The zsh configuration intentionally starts small. New shell settings are added only when they are actually needed during the environment refresh.

More configuration will be added only when it is actually needed.
