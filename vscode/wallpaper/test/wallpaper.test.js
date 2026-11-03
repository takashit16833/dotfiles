'use strict';

const assert = require('node:assert/strict');
const test = require('node:test');
const { readSettings, generateCss, resolveImage, normalizeSettings, cssImage } = require('../wallpaper');

const config = {
  enabled: true,
  image: 'https://example.org/wide.jpg',
  alternateImage: 'https://example.org/narrow.jpg',
  switchMode: 'aspect-ratio',
  maxAspectRatio: '16/10',
  maxWidth: 1400,
  tint: '#7085B0',
  backgroundColors: { editor: '#505050', sidebar: 'theme', panel: 'theme', auxiliaryBar: 'theme', chrome: 'theme' },
  opacity: { editor: 0.65, sidebar: 0.85, panel: 0.8, auxiliaryBar: 0.7, chrome: 0.92 }
};

test('readSettings には実装側のデフォルトがある', () => {
  const actual = readSettings({ get: (_key, fallback) => fallback });
  assert.equal(actual.enabled, false);
  assert.equal(actual.opacity.editor, 0.7);
  assert.equal(actual.tint, '#FFFFFF');
  assert.equal(actual.backgroundColors.editor, 'theme');
});

test('無効時には CSS を生成しない', () => assert.equal(generateCss({ enabled: false }), ''));

test('画像は画面全体に1枚、乗算、比率切り替え', () => {
  const css = generateCss(config);
  assert.match(css, /background-blend-mode: multiply, normal/);
  assert.match(css, /@media \(max-aspect-ratio: 16 \/ 10\)/);
  assert.match(css, /url\("https:\/\/example\.org\/wide\.jpg"\)/);
  assert.match(css, /url\("https:\/\/example\.org\/narrow\.jpg"\)/);
  assert.doesNotMatch(css, /body::after/);
  assert.match(css, /color-mix\(in srgb, #505050 65%, transparent\)/);
  assert.match(css, /var\(--vscode-sideBar-background, #242424\) 85%/);
  assert.match(css, /\.part\.auxiliarybar.*70%, transparent/);
});

test('横幅切替と代替画像なし', () => {
  const css = generateCss({ ...config, switchMode: 'width', alternateImage: '' });
  assert.doesNotMatch(css, /@media/);
  const wide = generateCss({ ...config, switchMode: 'width' });
  assert.match(wide, /@media \(max-width: 1400px\)/);
});

test('不正な設定を拒否する', () => {
  assert.throws(() => normalizeSettings({ ...config, maxAspectRatio: '0/10' }), /maxAspectRatio/);
  assert.throws(() => normalizeSettings({ ...config, tint: 'red' }), /tint/);
  assert.throws(() => normalizeSettings({ ...config, opacity: { editor: 1.5 } }), /opacity.editor/);
  assert.throws(() => normalizeSettings({ ...config, backgroundColors: { panel: 'rgb(0 0 0)' } }), /backgroundColors.panel/);
  assert.throws(() => generateCss({ ...config, image: '' }), /image/);
});

test('画像のローカルパス変換と相対パスの基準', () => {
  assert.match(resolveImage('/tmp/a b.png').url, /^vscode-file:\/\/vscode-app\/tmp\/a%20b.png$/);
  assert.match(resolveImage('./image.png', { workspaceDirectory: '/tmp/project' }).url, /project\/image\.png$/);
  assert.throws(() => resolveImage('./image.png'), /作業フォルダー/);
  assert.throws(() => resolveImage('javascript:alert(1)'), /画像には/);
});

test('CSS URL をエスケープし、HTML の混入を拒否する', () => {
  assert.equal(cssImage('https://example.org/a"b.png'), 'url("https://example.org/a\\"b.png")');
  assert.throws(() => cssImage('</style>'), /使用できない/);
  assert.throws(() => resolveImage('https://example.org/\n'), /使用できない/);
});

test('既定色は特定のテーマに依存せず、現在のテーマ色を参照する', () => {
  const settings = readSettings({ get: (_key, fallback) => fallback });
  const css = generateCss({ ...settings, enabled: true, image: 'https://example.org/test.jpg' });
  assert.match(css, /linear-gradient\(#FFFFFF, #FFFFFF\)/);
  assert.match(css, /var\(--vscode-editor-background, #202020\) 70%/);
  assert.doesNotMatch(css, /\.monaco-workbench\.vs-dark/);
  assert.doesNotMatch(css, /--vscode-editor-background: transparent/);
});

test('実画面で確認された不透明な下地を透明化する', () => {
  const css = generateCss(config);
  assert.match(css, /\.monaco-workbench \.monaco-grid-view,/);
  assert.match(css, /\.part\.panel \.pane\.expanded\.horizontal,/);
  assert.match(css, /\.part\.panel \.terminal-outer-container,/);
  assert.match(css, /\.part\.panel \.terminal\.xterm,/);
  assert.match(css, /\.part\.panel \.xterm-scrollable-element,/);
  assert.match(css, /background-color: transparent !important;/);
  assert.match(css, /\.part\.panel \{ background-color: color-mix\(/);
});

test('浮動パネルの背景色は VS Code 本体と同じ詳細度の規則で上書きする', () => {
  const css = generateCss(config);
  const normalRule = '.monaco-workbench .part.panel { background-color: color-mix(in srgb, var(--vscode-panel-background, #202020) 80%, transparent) !important; }';
  const floatingRule = '.monaco-workbench.floating-panels .part.panel { background-color: color-mix(in srgb, var(--vscode-panel-background, #202020) 80%, transparent) !important; }';
  assert.ok(css.includes(normalRule));
  assert.ok(css.includes(floatingRule));
  assert.ok(css.indexOf(floatingRule) > css.indexOf(normalRule));
});
