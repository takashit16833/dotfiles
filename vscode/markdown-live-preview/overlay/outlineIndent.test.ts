import { describe, expect, it } from 'vitest';
import { extractHeadings } from '../shared/headings';
import { outlineIndentClassForLine } from './outlineIndent';

function classes(text: string): string[] {
  const headings = extractHeadings(text);
  return text.split('\n').map((_, index) => outlineIndentClassForLine(headings, index + 1));
}

describe('Retro Hacker Blue section indentation', () => {
  it('indents heading levels and their following content, and resets at a shallower heading', () => {
    expect(classes([
      '# Title',
      'Body of title',
      '## Child',
      'Body of child',
      '- list',
      '### Grandchild',
      'Grandchild body',
      '## Another child',
      'Body of another',
      '# Another title',
      'Body',
    ].join('\n'))).toEqual([
      'rhb-outline-heading rhb-outline-depth-0',
      'rhb-outline-content rhb-outline-depth-0',
      'rhb-outline-heading rhb-outline-depth-1',
      'rhb-outline-content rhb-outline-depth-1',
      'rhb-outline-content rhb-outline-depth-1',
      'rhb-outline-heading rhb-outline-depth-2',
      'rhb-outline-content rhb-outline-depth-2',
      'rhb-outline-heading rhb-outline-depth-1',
      'rhb-outline-content rhb-outline-depth-1',
      'rhb-outline-heading rhb-outline-depth-0',
      'rhb-outline-content rhb-outline-depth-0',
    ]);
  });

  it('leaves text before the first heading unindented', () => {
    expect(classes('frontmatter-like text\n\n# Title\nBody')).toEqual([
      '', '',
      'rhb-outline-heading rhb-outline-depth-0',
      'rhb-outline-content rhb-outline-depth-0',
    ]);
  });

  it('does not treat a heading-looking line in a code fence as a heading', () => {
    expect(classes('# First\n\`\`\`md\n## Not a heading\n\`\`\`\nAfter\n## Real\nBody')).toEqual([
      'rhb-outline-heading rhb-outline-depth-0',
      'rhb-outline-content rhb-outline-depth-0',
      'rhb-outline-content rhb-outline-depth-0',
      'rhb-outline-content rhb-outline-depth-0',
      'rhb-outline-content rhb-outline-depth-0',
      'rhb-outline-heading rhb-outline-depth-1',
      'rhb-outline-content rhb-outline-depth-1',
    ]);
  });
});
