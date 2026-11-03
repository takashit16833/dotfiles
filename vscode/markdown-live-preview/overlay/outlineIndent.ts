import type { HeadingItem } from '../shared/headings';

/**
 * Return the section class for a document line, using the most recent heading.
 * Depth and body inset deliberately match vscode/markdown-preview/preview.js.
 * A binary search keeps scrolling cheap even in documents with many headings.
 */
export function outlineIndentClassForLine(headings: readonly HeadingItem[], line: number): string {
  let low = 0;
  let high = headings.length;
  while (low < high) {
    const mid = (low + high) >>> 1;
    if (headings[mid].line <= line) low = mid + 1;
    else high = mid;
  }
  if (low === 0) return '';
  const heading = headings[low - 1];
  return `rhb-outline-${heading.line === line ? 'heading' : 'content'} rhb-outline-depth-${heading.level - 1}`;
}
