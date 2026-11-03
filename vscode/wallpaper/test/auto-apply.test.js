'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs/promises');
const path = require('node:path');
const os = require('node:os');
const { pathsFor, inspect, enable, sync, disable, patchedHtml, CSS_HEADER } = require('../auto-apply');

const original = '<!doctype html>\n<html>\n<head>\n\t<link rel="stylesheet" href="../../../workbench/workbench.desktop.main.css">\n</head><body></body></html>\n';

async function fixture(t) {
  const root = await fs.mkdtemp(path.join(os.tmpdir(), 'wallpaper-auto-test-'));
  t.after(() => fs.rm(root, { recursive: true, force: true }));
  const files = pathsFor(root);
  await fs.mkdir(path.dirname(files.html), { recursive: true });
  await fs.writeFile(files.html, original);
  return { root, files };
}

test('元ファイルを保存してリンクを導入・再導入・安全に復元できる', async t => {
  const { root, files } = await fixture(t);
  assert.deepEqual(await enable(root, 'body { color: red; }'), { installed: true, newlyInstalled: true });
  assert.equal(await fs.readFile(files.backup, 'utf8'), original);
  assert.equal(await fs.readFile(files.html, 'utf8'), patchedHtml(original));
  assert.equal(await fs.readFile(files.css, 'utf8'), CSS_HEADER + 'body { color: red; }');
  assert.deepEqual(await enable(root, 'body { color: blue; }'), { installed: true, newlyInstalled: false });
  assert.deepEqual(await sync(root, 'body { color: blue; }'), { installed: true, changed: false });
  assert.deepEqual(await sync(root, 'body { color: green; }'), { installed: true, changed: true });
  assert.deepEqual(await disable(root), { installed: false, changed: true });
  assert.equal(await fs.readFile(files.html, 'utf8'), original);
  await assert.rejects(fs.stat(files.backup), { code: 'ENOENT' });
  await assert.rejects(fs.stat(files.css), { code: 'ENOENT' });
  assert.deepEqual(await disable(root), { installed: false, changed: false });
});

test('非対応の HTML は変更せずバックアップも作らない', async t => {
  const { root, files } = await fixture(t);
  await fs.writeFile(files.html, '<html><body></body></html>');
  await assert.rejects(enable(root, 'valid {}'), /対応する/);
  assert.equal((await inspect(root)).installed, false);
  await assert.rejects(fs.stat(files.backup), { code: 'ENOENT' });
});

test('インストール後に HTML が変更されたら復元も更新も拒否する', async t => {
  const { root, files } = await fixture(t);
  await enable(root, 'body{}');
  await fs.appendFile(files.html, '\n<!-- external change -->');
  await assert.rejects(disable(root), /別の変更/);
  await assert.rejects(sync(root, 'x{}'), /別の変更/);
  assert.equal(await fs.readFile(files.backup, 'utf8'), original);
});

test('管理外 CSS と既存バックアップを上書きしない', async t => {
  const { root, files } = await fixture(t);
  await fs.writeFile(files.css, 'not owned');
  await assert.rejects(enable(root, 'x{}'), /以前のバックアップ/);
  assert.equal(await fs.readFile(files.html, 'utf8'), original);
});

test('無効化設定は CSS を空に更新して HTML を維持する', async t => {
  const { root, files } = await fixture(t);
  await enable(root, 'a{}');
  assert.deepEqual(await sync(root, ''), { installed: true, changed: true });
  assert.equal(await fs.readFile(files.css, 'utf8'), CSS_HEADER);
  assert.equal(await fs.readFile(files.html, 'utf8'), patchedHtml(original));
});
