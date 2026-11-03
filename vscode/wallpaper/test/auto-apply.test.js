'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs/promises');
const path = require('node:path');
const os = require('node:os');
const { pathsFor, workspaceStylePath, inspect, enable, sync, disable,
  patchedHtml, LEGACY_LINK, CSS_HEADER } = require('../auto-apply');

const cssAnchor = '<link rel="stylesheet" href="../../../workbench/workbench.desktop.main.css">';
const original = '<!doctype html>\n<html><head>\n\t' + cssAnchor + '\n</head><body></body></html>\n';

async function fixture(t) {
  const root = await fs.mkdtemp(path.join(os.tmpdir(), 'wallpaper-auto-test-'));
  t.after(() => fs.rm(root, { recursive: true, force: true }));
  const files = pathsFor(root);
  await fs.mkdir(path.dirname(files.html), { recursive: true });
  await fs.writeFile(files.html, original);
  return { root, files };
}

test('ワークスペースごとの CSS を起動用 HTML から読み分ける', async t => {
  const { root, files } = await fixture(t);
  assert.deepEqual(await enable(root, 'body { color: red; }', 'folder-a'),
    { installed: true, newlyInstalled: true });
  assert.equal(await fs.readFile(files.backup, 'utf8'), original);
  assert.equal(await fs.readFile(files.html, 'utf8'), patchedHtml(original));
  assert.equal(await fs.readFile(files.css, 'utf8'), CSS_HEADER);
  assert.equal(await fs.readFile(workspaceStylePath(files, 'folder-a'), 'utf8'),
    CSS_HEADER + 'body { color: red; }');
  assert.equal(await fs.readFile(files.loader, 'utf8'),
    await fs.readFile(path.join(__dirname, '..', 'renderer-loader.js'), 'utf8'));

  assert.deepEqual(await sync(root, 'body { color: blue; }', 'folder-b'),
    { installed: true, changed: true });
  assert.equal(await fs.readFile(workspaceStylePath(files, 'folder-a'), 'utf8'),
    CSS_HEADER + 'body { color: red; }');
  assert.equal(await fs.readFile(workspaceStylePath(files, 'folder-b'), 'utf8'),
    CSS_HEADER + 'body { color: blue; }');
  assert.deepEqual(await sync(root, 'body { color: blue; }', 'folder-b'),
    { installed: true, changed: false });

  assert.deepEqual(await disable(root), { installed: false, changed: true });
  assert.equal(await fs.readFile(files.html, 'utf8'), original);
  for (const filename of [files.backup, files.css, files.loader,
    workspaceStylePath(files, 'folder-a'), workspaceStylePath(files, 'folder-b')]) {
    await assert.rejects(fs.stat(filename), { code: 'ENOENT' });
  }
  assert.deepEqual(await disable(root), { installed: false, changed: false });
});

test('画像が設定されていないワークスペースも空の CSS で管理する', async t => {
  const { root, files } = await fixture(t);
  await enable(root, '', 'empty');
  assert.equal(await fs.readFile(workspaceStylePath(files, 'empty'), 'utf8'), CSS_HEADER);
  assert.equal((await inspect(root)).installed, true);
});

test('以前の全ウィンドウ共通 CSS から安全に移行して元のバックアップを保つ', async t => {
  const { root, files } = await fixture(t);
  const legacy = original.replace(cssAnchor, cssAnchor + '\n\t\t' + LEGACY_LINK);
  await fs.writeFile(files.html, legacy);
  await fs.writeFile(files.backup, original);
  await fs.writeFile(files.css, CSS_HEADER + 'body { background: old; }');
  assert.equal((await inspect(root)).legacy, true);
  await sync(root, 'body { background: project; }', 'project');
  assert.equal((await inspect(root)).legacy, false);
  assert.equal(await fs.readFile(files.backup, 'utf8'), original);
  assert.equal(await fs.readFile(files.css, 'utf8'), CSS_HEADER);
  assert.equal(await fs.readFile(workspaceStylePath(files, 'project'), 'utf8'),
    CSS_HEADER + 'body { background: project; }');
  await disable(root);
  assert.equal(await fs.readFile(files.html, 'utf8'), original);
});

test('VS Code 本体が別の方法で変更された場合は復元・同期を拒否する', async t => {
  const { root, files } = await fixture(t);
  await enable(root, 'a{}', 'project');
  await fs.appendFile(files.html, '\n<!-- external change -->');
  await assert.rejects(disable(root), /別の変更/);
  await assert.rejects(sync(root, 'b{}', 'project'), /別の変更/);
  assert.equal(await fs.readFile(files.backup, 'utf8'), original);
});

test('管理外 CSS・スクリプト・非対応 HTML を上書きしない', async t => {
  const { root, files } = await fixture(t);
  await fs.writeFile(files.html, '<html><body></body></html>');
  await assert.rejects(enable(root, 'a{}', 'project'), /対応する/);
  await fs.writeFile(files.html, original);
  await fs.writeFile(files.css, 'not owned');
  await assert.rejects(enable(root, 'a{}', 'project'), /管理外/);
  await fs.unlink(files.css);
  await fs.writeFile(files.loader, 'not owned');
  await assert.rejects(enable(root, 'a{}', 'project'), /以前の壁紙ファイル/);
});

test('ワークスペース ID を使ったファイル名の逸脱を拒否する', async t => {
  const { root, files } = await fixture(t);
  assert.throws(() => workspaceStylePath(files, '../other'), /不正な/);
  assert.throws(() => workspaceStylePath(files, ''), /不正な/);
  await assert.rejects(enable(root, 'a{}', '../other'), /不正な/);
});

test('v0.5 の読み込みスクリプトを識別し、CSS を保ったまま更新する', async t => {
  const { root, files } = await fixture(t);
  await enable(root, 'body { color: old; }', 'project');
  const previous = await fs.readFile(
    path.join(__dirname, 'fixtures', 'renderer-loader-v0.5.js'), 'utf8');
  await fs.writeFile(files.loader, previous);
  assert.equal((await inspect(root)).outdatedLoader, true);

  const changed = await sync(root, 'body { color: new; }', 'project');
  assert.deepEqual(changed, { installed: true, changed: true, loaderChanged: true });
  assert.equal((await inspect(root)).outdatedLoader, false);
  assert.equal(await fs.readFile(workspaceStylePath(files, 'project'), 'utf8'),
    CSS_HEADER + 'body { color: new; }');
  await disable(root);
  assert.equal(await fs.readFile(files.html, 'utf8'), original);
});

test('不明な読み込みスクリプトは更新も解除も拒否する', async t => {
  const { root, files } = await fixture(t);
  await enable(root, 'body{}', 'project');
  await fs.writeFile(files.loader, 'unrelated changes');
  await assert.rejects(sync(root, 'body{color:red}', 'project'), /読み込みスクリプト/);
  await assert.rejects(disable(root), /読み込みスクリプト/);
  assert.equal(await fs.readFile(files.backup, 'utf8'), original);
});
