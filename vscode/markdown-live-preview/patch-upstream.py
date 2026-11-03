#!/usr/bin/env python3
"""Apply a minimal pinned-source patch; fail rather than guess on upstream drift."""
from pathlib import Path
import sys

source = Path(sys.argv[1])
text = source.read_text(encoding="utf-8")


def replace_once(old: str, new: str) -> None:
    global text
    count = text.count(old)
    if count != 1:
        raise SystemExit(f"Expected one match in {source}, found {count}: {old[:80]!r}")
    text = text.replace(old, new, 1)


replace_once(
    "import { syntaxTree } from '@codemirror/language';",
    "import { syntaxTree } from '@codemirror/language';\n"
    "import { extractHeadings, type HeadingItem } from '../shared/headings';\n"
    "import { outlineIndentClassForLine } from './outlineIndent';",
)
replace_once(
    "function buildDecorations(view: EditorView): DecorationSet {",
    "function buildDecorations(view: EditorView, headings: readonly HeadingItem[]): DecorationSet {",
)
replace_once(
    "for (const [lineFrom, cls] of seenLine) {\n"
    "\t\tdecorations.push(Decoration.line({ class: cls }).range(lineFrom));\n"
    "\t}",
    "// Only augment lines already decorated by Live Preview. Adding line\n"
    "\t// decorations inside block-replaced tables/diagrams drops their widgets.\n"
    "\tfor (const [lineFrom, cls] of seenLine) {\n"
    "\t\tconst outline = outlineIndentClassForLine(headings, doc.lineAt(lineFrom).number);\n"
    "\t\tdecorations.push(Decoration.line({ class: outline ? `${cls} ${outline}` : cls }).range(lineFrom));\n"
    "\t}",
)
replace_once(
    "\t\tdecorations: DecorationSet;\n\n"
    "\t\tconstructor(view: EditorView) {\n"
    "\t\t\tthis.decorations = buildDecorations(view);\n"
    "\t\t}",
    "\t\tdecorations: DecorationSet;\n"
    "\t\tprivate headings: HeadingItem[];\n\n"
    "\t\tconstructor(view: EditorView) {\n"
    "\t\t\tthis.headings = extractHeadings(view.state.doc.toString());\n"
    "\t\t\tthis.decorations = buildDecorations(view, this.headings);\n"
    "\t\t}",
)
replace_once(
    "\t\t\t\tthis.decorations = buildDecorations(update.view);",
    "\t\t\t\tif (update.docChanged) this.headings = extractHeadings(update.state.doc.toString());\n"
    "\t\t\t\tthis.decorations = buildDecorations(update.view, this.headings);",
)

source.write_text(text, encoding="utf-8")
