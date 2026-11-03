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


test('インラインコードは文字色を保ったまま背景のみ半透明にする', () => {
  const css = fs.readFileSync(path.join(__dirname, '..', 'retro-hacker-blue.css'), 'utf8');
  const block = css.match(/body\.vscode-dark \.mlp-inline-code\s*\{([^}]*)\}/)?.[1];
  assert.ok(block);
  assert.match(block, /background-color:\s*color-mix\(in srgb,\s*#052A59 70%,\s*transparent\)/);
  assert.match(block, /color:\s*#7CBEFF/);
  assert.doesNotMatch(block, /(?:^|;)\s*opacity:/);
});

test('Live Preview のページと CodeMirror 背景を透明化する', () => {
  const css = fs.readFileSync(path.join(__dirname, '..', 'retro-hacker-blue.css'), 'utf8');
  const selectors = [
    'html,',
    'html body.vscode-dark,',
    'html body.vscode-dark #mlp-root,',
    'html body.vscode-dark #mlp-root .cm-editor,',
    'html body.vscode-dark #mlp-root .cm-scroller'
  ];
  for (const selector of selectors) assert.ok(css.includes(selector), selector);
  const rule = css.match(/html,\s*html body\.vscode-dark,([\s\S]*?)\}/)?.[1];
  assert.ok(rule);
  assert.match(rule, /background-color:\s*transparent !important;/);
  assert.match(rule, /background-image:\s*none !important;/);
  assert.doesNotMatch(rule, /(?:^|;)\s*(?:opacity|filter|color|padding|margin):/);
});
