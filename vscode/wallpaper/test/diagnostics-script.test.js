'use strict';

const assert = require('node:assert/strict');
const vm = require('node:vm');
const test = require('node:test');
const { buildDiagnosticsScript } = require('../diagnostics-script');

const config = {
  enabled: true, image: 'https://example.org/image.jpg',
  alternateImage: 'https://example.org/other.jpg',
  switchMode: 'aspect-ratio', maxAspectRatio: '16/10',
  maxWidth: 1400, tint: '#FFFFFF'
};

function run(script) {
  const results = { info: [], tables: [] };
  const root = {
    tagName: 'DIV', id: '', classList: ['monaco-workbench'],
    getBoundingClientRect: () => ({ x: 0, y: 0, width: 1200, height: 800, left: 0, top: 0 }),
    querySelectorAll: () => [node]
  };
  const node = {
    tagName: 'DIV', id: 'workbench.parts.panel', classList: ['part', 'panel'],
    getBoundingClientRect: () => ({ x: 0, y: 600, width: 400, height: 200 })
  };
  const context = {
    document: {
      querySelector: () => root,
      elementsFromPoint: () => [node, root]
    },
    window: { innerWidth: 1200, innerHeight: 800 },
    matchMedia: query => ({ matches: query.includes('aspect-ratio') }),
    console: { info: (...args) => results.info.push(args), table: rows => results.tables.push(rows) },
    getComputedStyle: el => ({
      display: 'block', backgroundColor: 'rgba(0, 0, 0, 0)',
      backgroundImage: el === root ? 'url("image.jpg")' : 'none'
    })
  };
  vm.runInNewContext(script, context);
  return results;
}

test('縦横比・代替画像・表示中の領域と左側の重なりを報告する', () => {
  const report = run(buildDiagnosticsScript(config));
  assert.equal(report.info[0][1].query, '(max-aspect-ratio: 16 / 10)');
  assert.equal(report.info[0][1].alternateImageConfigured, true);
  assert.equal(report.info[0][1].queryMatches, true);
  assert.equal(report.tables[0][0].element, 'div#workbench.parts.panel.part.panel');
  assert.equal(report.tables[1].length, 2);
});

test('横幅の切り替え条件と画像なしを報告する', () => {
  const report = run(buildDiagnosticsScript({ ...config, switchMode: 'width', alternateImage: '' }));
  assert.equal(report.info[0][1].query, '(max-width: 1400px)');
  assert.equal(report.info[0][1].alternateImageConfigured, false);
});

test('診断コードは DOM や設定を変更しない', () => {
  const script = buildDiagnosticsScript(config);
  assert.doesNotMatch(script, /writeFile|style\.setProperty|\.remove\(|replaceSync|adoptedStyleSheets\s*=/);
  assert.doesNotMatch(script, /fetch\(|XMLHttpRequest|WebSocket/);
});
