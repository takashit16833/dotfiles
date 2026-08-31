# Scripts

`dotfiles` で管理する個人用 CLI の置き場です。

実体は `scripts/bin/` に置き、ルートの `install.sh` が `$HOME/.local/bin/` へ symlink します。`$HOME/.local/bin` 自体は `.config/zsh/.zshenv` ですでに `PATH` に含まれています。

新しい運用スクリプトを作る前に、この README と `scripts/bin/` を確認し、既存 CLI に同じ責務がないか確認します。

## Commands

### `repo-main-bypass`

ローカル Mac だけが GitHub の default branch へ直接 push できるようにし、通常の GitHub ユーザー認証（ChatGPT など）は引き続き PR 必須にします。

```sh
repo-main-bypass setup
repo-main-bypass status
repo-main-bypass audit
repo-main-bypass remove
```

`setup` / `status` / `remove` は対象 repository の中で実行します。SSH key は repository には保存せず、`~/.ssh/github-main-bypass/<owner>/<repo>` に生成します。

`setup` は次を行います。

1. repository 専用の ed25519 key pair をローカルへ生成する
2. public key を write-enabled Deploy Key として GitHub へ登録する
3. force push / branch deletion は bypass できない Ruleset として維持する
4. PR 必須 Ruleset だけに DeployKey bypass を付ける
5. repository-local の `core.sshCommand` で、その repository だけ専用 key を使う

GitHub の Ruleset では `DeployKey` bypass は特定 key ID ではなく Deploy Key 種別全体に適用されます。そのため `setup` は、別の write-enabled Deploy Key がすでに存在する repository では安全側に倒して停止します。

`remove` は専用 Deploy Key、DeployKey bypass、repository-local Git 設定、ローカル key pair を解除します。PR 必須、force push 禁止、branch deletion 禁止の Ruleset 自体は残します。

`audit` は `~/.ssh/github-main-bypass/` を基準に、削除済み repository のローカル key や GitHub 側との食い違いを確認します。

## Installation

`install.sh` は `scripts/bin/` の executable を `$HOME/.local/bin/` へ symlink します。`uninstall.sh` は、この repository を指している symlink だけを解除します。

`uninstall.sh` は Deploy Key や SSH key を自動削除しません。GitHub の権限状態まで暗黙に変更しないためです。不要な bypass は対象 repository で先に `repo-main-bypass remove` を実行します。
