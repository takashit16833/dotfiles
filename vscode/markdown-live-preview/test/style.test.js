'use strict';

const assert = require('node:assert/strict');
const test = require('node:test');
const fs = require('node:fs');
const path = require('node:path');

test('Markdown Live Preview のコードブロックは半透明で文字や字下げを変えない', () => {
  const css = fs.readFileSync(path.join(__dirname, '..', 'retro-hacker-blue.css'), 'utf8');
  const rule = css.match(/body\.vscode-dark \.cm-line\.mlp-line-code\s*\{([^}]*)\}/)?.[1];
  assert.ok(rule, 'code block background rule must exist');
  assert.match(rule, /background-color:\s*color-mix\(in srgb,\s*#0A1A36 70%,\s*transparent\)/);
  assert.doesNotMatch(rule, /(?:^|;)\s*(?:opacity|filter|color|padding|margin):/);
});
