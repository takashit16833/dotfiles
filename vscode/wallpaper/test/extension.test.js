'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');

const source = fs.readFileSync(path.join(__dirname, '..', 'extension.js'), 'utf8');

function fixture(changesCss = true) {
  const syncCalls = [];
  const notices = [];
  const commands = [];
  let onConfigurationChange;

  const vscode = {
    env: { appRoot: '/app' },
    workspace: {
      workspaceFolders: [{ uri: { fsPath: '/workspace' } }],
      getConfiguration: () => ({
        get: (name, fallback) => ({ enabled: true, image: 'https://example.org/a.jpg' })[name] ?? fallback
      }),
      onDidChangeConfiguration: callback => {
        onConfigurationChange = callback;
        return { dispose() {} };
      }
    },
    commands: {
      registerCommand: () => ({ dispose() {} }),
      executeCommand: async name => { commands.push(name); }
    },
    window: {
      showInformationMessage: async (...args) => {
        notices.push(args);
        return 'Reload Window';
      },
      showErrorMessage: message => { throw new Error(message); },
      showWarningMessage: message => { throw new Error(message); }
    }
  };
  const automatic = {
    inspect: async () => ({ installed: true }),
    sync: async (...args) => {
      syncCalls.push(args);
      return { installed: true, changed: changesCss && syncCalls.length > 1 };
    }
  };
  const dependencies = {
    'node:path': path,
    vscode,
    './auto-apply': automatic,
    './workspace-id': { currentWorkspaceId: async () => 'project-a' },
    './wallpaper': {
      readSettings: configuration => ({
        enabled: configuration.get('enabled', false),
        image: configuration.get('image', '')
      }),
      generateCss: settings => 'body { background: ' + settings.image + '; }',
      resolveImage: () => null
    },
    './workbench-script': {},
    './diagnostics-script': {},
    './responsive-test': {}
  };
  const module = { exports: {} };
  vm.runInNewContext(source, {
    module,
    require: name => {
      if (!(name in dependencies)) throw new Error('Unexpected dependency: ' + name);
      return dependencies[name];
    }
  });
  module.exports.activate({
    subscriptions: [],
    globalState: { get: () => true }
  });

  return {
    syncCalls, notices, commands,
    async flush() { await new Promise(resolve => setImmediate(resolve)); },
    change: () => onConfigurationChange({
      affectsConfiguration: name => name === 'vscodeWallpaper'
    }),
    unrelated: () => onConfigurationChange({ affectsConfiguration: () => false })
  };
}

test('設定変更時は CSS のみ更新し、再読み込み通知や実行はしない', async () => {
  const session = fixture();
  await session.flush();
  assert.equal(session.syncCalls.length, 1);
  assert.equal(session.notices.length, 0);

  session.unrelated();
  await session.flush();
  assert.equal(session.syncCalls.length, 1);

  session.change();
  await session.flush();
  assert.equal(session.syncCalls.length, 2);
  assert.equal(session.syncCalls[1][0], '/app');
  assert.equal(session.syncCalls[1][2], 'project-a');
  assert.equal(session.notices.length, 0);
  assert.deepEqual(session.commands, []);
});

test('CSS が変わらなければ通知せず、画面を再読み込みしない', async () => {
  const session = fixture(false);
  await session.flush();
  session.change();
  await session.flush();
  assert.equal(session.syncCalls.length, 2);
  assert.equal(session.notices.length, 0);
  assert.deepEqual(session.commands, []);
});
