'use strict';
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const test = require('node:test');

const loader = fs.readFileSync(path.join(__dirname, '..', 'renderer-loader.js'), 'utf8')
  .replace('import.meta.url', JSON.stringify('vscode-file://vscode-app/renderer-loader.js'));
const header = '/* VS Code Wallpaper: managed stylesheet; generated from user settings. */\n';

function workbench(id, initialCss = header + 'body { color: red; }') {
  let css = initialCss;
  let available = true;
  let poll;
  let interval;
  const links = [];
  const requests = [];
  const warnings = [];
  const context = {
    window: { vscode: { context: { resolveConfiguration: async () => ({ workspace: { id } }) } } },
    document: {
      createElement: () => ({
        remove() { this.removed = true; }
      }),
      head: {
        append(link) {
          links.push(link);
          queueMicrotask(() => {
            if (available) link.onload?.();
            else link.onerror?.();
          });
        }
      }
    },
    console: { warn: (...args) => warnings.push(args) },
    fetch: async (url, options) => {
      requests.push({ url, options });
      return available ? { ok: true, text: async () => css } : { ok: false };
    },
    setInterval: (callback, milliseconds) => {
      poll = callback;
      interval = milliseconds;
    },
    URL
  };
  return {
    start: async () => { await vm.runInNewContext(loader, context); await Promise.resolve(); },
    tick: async () => { assert.ok(poll); await poll(); await Promise.resolve(); },
    setCss: value => { css = value; },
    setAvailable: value => { available = value; },
    get links() { return links; },
    get requests() { return requests; },
    get warnings() { return warnings; },
    get interval() { return interval; }
  };
}

test('同じ CSS なら再描画せず、変更があれば再読み込みなしで置き換える', async () => {
  const client = workbench('first');
  await client.start();
  assert.equal(client.interval, 2000);
  const previousCount = client.links.length;
  await client.tick();
  assert.equal(client.links.length, previousCount);

  client.setCss(header + 'body { color: blue; }');
  await client.tick();
  assert.equal(client.links.length, previousCount + 1);
  assert.ok(client.links.at(-2).removed);
  assert.ok(!client.links.at(-1).removed);

  // No image is represented by a managed, empty CSS file.
  client.setCss(header);
  await client.tick();
  assert.equal(client.links.length, previousCount + 2);
  assert.ok(client.links.at(-2).removed);
  assert.ok(client.requests.every(x => x.options.cache === 'no-store'));
});

test('CSS が一時的にない場合は表示を保持し、復旧時に反映する', async () => {
  const client = workbench('second');
  await client.start();
  const old = client.links.at(-1);
  client.setAvailable(false);
  await client.tick();
  assert.ok(!old.removed);
  const count = client.links.length;
  client.setAvailable(true);
  client.setCss(header + 'body { color: green; }');
  await client.tick();
  assert.equal(client.links.length, count + 1);
  assert.ok(old.removed);
});

test('別ウィンドウは別々のワークスペース CSS を読み込む', async () => {
  const a = workbench('workspace-a');
  const b = workbench('workspace-b');
  await Promise.all([a.start(), b.start()]);
  assert.ok(a.requests[0].url.includes('vscode-wallpaper-workspace-a.css'));
  assert.ok(b.requests[0].url.includes('vscode-wallpaper-workspace-b.css'));
  assert.equal(a.warnings.length + b.warnings.length, 0);
});

test('無効なワークスペース ID は読み込まない', async () => {
  const client = workbench('../unknown');
  await client.start();
  assert.equal(client.links.length, 0);
  assert.equal(client.warnings.length, 1);
});
