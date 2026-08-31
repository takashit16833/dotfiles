# Scripts

`dotfiles` で管理する個人用 CLI / 運用スクリプトの置き場です。

実体は `scripts/bin/` に置き、ルートの `install.sh` が `$HOME/.local/bin/` へ symlink します。`$HOME/.local/bin` 自体は `.config/zsh/.zshenv` ですでに `PATH` に含まれています。

新しいスクリプトを作る前に、この README と `scripts/bin/` を確認し、既存 CLI に同じ責務がないか確認します。

## Commands

現在、管理中の自作 CLI はありません。

CLI を追加したら、コマンド名・目的・主な使い方をこのセクションへ記録します。

## Installation

`install.sh` は `scripts/bin/` の executable を `$HOME/.local/bin/` へ symlink します。`uninstall.sh` は、この repository を指している symlink だけを解除します。

runtime state、秘密情報、SSH key などは `scripts/` に置かず、各ツールに適したローカル領域で管理します。
