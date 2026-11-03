# Markdown Live Preview — Retro Hacker Blue

This is an **experimental editing view**, separate from the existing
`vscode/markdown-preview/` extension. Do not switch the default editor until
its rendering and editing behavior have been checked.

On macOS, after installing `t-shoot.markdown-live-preview-editor`:

```bash
cd ~/dotfiles
git pull
bash vscode/markdown-live-preview/install.sh
```

Open a Markdown file with **Reopen Editor With... → Markdown Live Preview**.
The user settings activate `retro-hacker-blue.css` but leave the current
Markdown Preview as the default. If necessary, reload the VS Code window.

Fenced code blocks use a 70% opaque dark-blue background instead of a fully opaque block. This matches the ordinary Markdown Preview and lets the shared VS Code wallpaper show through while preserving code text contrast.

The source of the stylesheet is `retro-hacker-blue.css`. The install script
copies it to the extension's user-data styles directory; rerun the script after
edits to the source. It does not overwrite unrelated style files.

To verify the stylesheet's code-block background after updating:

```bash
node --test vscode/markdown-live-preview/test/style.test.js
```

## Section indentation

The Marketplace extension cannot infer the previous heading from CSS alone.
The pinned upstream source (commit `b0ce2e0c005ff69e322a840f236e03efc698abf2`, version 0.5.0)
is therefore built locally with a small CodeMirror line-decoration patch.
The full upstream source and installed extension are **not** committed to dotfiles.

```bash
cd ~/dotfiles
git pull
bash vscode/markdown-live-preview/install-editor.sh
```

This script clones the pinned upstream source into a temporary directory,
applies `patch-upstream.py`, copies the tested helper from `overlay/`, runs
the TypeScript build and unit tests, then installs the VSIX **only if these
checks pass**. It replaces the same extension ID you installed from Marketplace.
Reload VS Code after installation. Do not treat the Marketplace version as
equivalent: a future automatic extension update may replace this local build.

The line decoration is attached only to existing CodeMirror lines, avoiding
conflicts with block-replaced diagrams and tables. Horizontal indentation uses
padding (not margins) for correct cursor measurements.

**Known limitation:** Rendered block widgets such as tables and Mermaid
diagrams are not yet assigned section padding. Heading, paragraph, list,
blockquote and code lines are. Verify appearance and editing behavior in a
real VS Code window before making this the default Markdown editor.
