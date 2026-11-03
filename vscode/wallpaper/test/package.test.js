'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const test = require('node:test');

const packageJson = require('../package.json');
const extensionDirectory = path.resolve(__dirname, '..');

test('VSIX のパッケージ設定は files と .vscodeignore を併用しない', () => {
  const hasIgnoreFile = fs.existsSync(path.join(extensionDirectory, '.vscodeignore'));
  const hasFilesProperty = Object.hasOwn(packageJson, 'files');
  assert.equal(hasIgnoreFile && hasFilesProperty, false);
});

test('VSIX の生成時に repository の確認が不要な設定になっている', () => {
  assert.equal(packageJson.repository.url, 'https://github.com/takashit16833/dotfiles.git');
});
