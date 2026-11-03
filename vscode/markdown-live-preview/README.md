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

The source of the stylesheet is `retro-hacker-blue.css`. The install script
copies it to the extension's user-data styles directory; rerun the script after
edits to the source. It does not overwrite unrelated style files.

**Limitations:** This first stage matches heading colors and bars, ordered-list
markers, quotes, inline code, code-block backgrounds and the content column.
It does **not** reproduce the heading-dependent indentation of headings and
all their following content. The standard preview does that in `preview.js`;
Markdown Live Preview uses CodeMirror and needs its own line decorations.
Do not use CSS-only approximations that could break editing/cursor positions.
