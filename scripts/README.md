# Scripts

`dotfiles` で管理する個人用 CLI / 運用スクリプトの置き場です。

実体は `scripts/bin/` に置き、ルートの `install.sh` が `$HOME/.local/bin/` へ symlink します。`$HOME/.local/bin` 自体は `.config/zsh/.zshenv` ですでに `PATH` に含まれています。

新しいスクリプトを作る前に、この README と `scripts/bin/` を確認し、既存 CLI に同じ責務がないか確認します。

## Commands

### images-to-pdf

指定フォルダ直下の画像をファイル名順に1ページずつまとめて、親フォルダへ `<フォルダ名>.pdf` を生成します。
画像ファイルは変更せず、既存のPDFは上書きしません。下位フォルダは探索しません。

```zsh
images-to-pdf ~/Documents/capture/chapter2
# ~/Documents/capture/chapter2.pdf を生成
```

対象拡張子は JPEG (`.jpg`/`.jpeg`)、PNG、TIFF (`.tif`/`.tiff`)、BMP、GIF、WebP（大文字も可）です。
GIF・複数ページTIFFは先頭画像だけを使います。読み込めない画像がある場合はエラーで停止します。
macOS の PDFKit と Swift を利用するため、Xcode Command Line Tools が必要です。追加の Python パッケージは不要です。
`install.sh` が `scripts/bin/images-to-pdf` を `~/.local/bin` にリンクします。

## Installation

`install.sh` は `scripts/bin/` の executable を `$HOME/.local/bin/` へ symlink します。`uninstall.sh` は、この repository を指している symlink だけを解除します。

runtime state、秘密情報、SSH key などは `scripts/` に置かず、各ツールに適したローカル領域で管理します。
