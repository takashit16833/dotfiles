'use strict';

const assert = require('node:assert/strict');
const vm = require('node:vm');
const test = require('node:test');
const { SHEET_KEY, buildApplyScript, buildRemoveScript } = require('../workbench-script');

function fakeWorkbench() {
  const workbench = {};
  const fake = {
    document: {
      adoptedStyleSheets: [],
      querySelector: selector => selector === '.monaco-workbench' ? workbench : null
    },
    window: {},
    CSSStyleSheet: class {
      replaceSync(css) { this.css = css; }
    },
    console: { info() {} },
    getComputedStyle: () => ({ backgroundImage: 'url("image.jpg")' })
  };
  return fake;
}

test('一時スタイルを画面へ追加・更新・解除でき、他のシートは保持する', () => {
  const fake = fakeWorkbench();
  const existing = { system: true };
  fake.document.adoptedStyleSheets = [existing];
  vm.runInNewContext(buildApplyScript('.monaco-workbench { color: red; }'), fake);
  assert.equal(fake.document.adoptedStyleSheets.length, 2);
  assert.equal(fake.document.adoptedStyleSheets[1].css, '.monaco-workbench { color: red; }');
  const first = fake.window[SHEET_KEY];
  vm.runInNewContext(buildApplyScript('.monaco-workbench { color: blue; }'), fake);
  assert.equal(fake.document.adoptedStyleSheets.length, 2);
  assert.notEqual(first, fake.window[SHEET_KEY]);
  assert.equal(fake.document.adoptedStyleSheets[1].css, '.monaco-workbench { color: blue; }');
  vm.runInNewContext(buildRemoveScript(), fake);
  assert.equal(fake.document.adoptedStyleSheets.length, 1);
  assert.equal(fake.document.adoptedStyleSheets[0], existing);
  assert.equal(Object.hasOwn(fake.window, SHEET_KEY), false);
});

test('画面が見つからなければ適用しない', () => {
  const fake = fakeWorkbench();
  fake.document.querySelector = () => null;
  assert.throws(() => vm.runInNewContext(buildApplyScript('body { color: red; }'), fake), /画面が見つかりません/);
  assert.equal(fake.document.adoptedStyleSheets.length, 0);
});

test('空 CSS とスクリプトへ混入する文字列を安全に扱う', () => {
  assert.throws(() => buildApplyScript(''), /CSS/);
  const fake = fakeWorkbench();
  const malicious = 'body::after { content: "a\`); globalThis.hacked = true; //"; }';
  vm.runInNewContext(buildApplyScript(malicious), fake);
  assert.equal(fake.document.adoptedStyleSheets[0].css, malicious);
  assert.equal(fake.hacked, undefined);
});
