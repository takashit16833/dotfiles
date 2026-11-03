'use strict';

const assert = require('node:assert/strict');
const test = require('node:test');
const { generateResponsiveTestCss, TEST_IMAGES } = require('../responsive-test');

test('縦長・横長で2枚の埋め込み画像を切り替えるCSSを生成する', () => {
  const css = generateResponsiveTestCss({ enabled: false, image: '', alternateImage: '' }, 'orientation');
  assert.match(css, /@media \(orientation: portrait\)/);
  assert.match(css, /background-blend-mode: multiply, normal/);
  assert.ok(css.includes(TEST_IMAGES.wide));
  assert.ok(css.includes(TEST_IMAGES.narrow));
  assert.equal(css.includes('https://'), false);
});

test('横幅800pxで同じ生成処理が動く', () => {
  const css = generateResponsiveTestCss({}, 'width');
  assert.match(css, /@media \(max-width: 800px\)/);
  assert.ok(css.includes(TEST_IMAGES.wide));
  assert.ok(css.includes(TEST_IMAGES.narrow));
});

test('無効な切り替えは拒否し、元の設定を変更しない', () => {
  const config = { enabled: true, image: 'https://example.org/user.png', opacity: { editor: 0.75 } };
  const before = JSON.stringify(config);
  generateResponsiveTestCss(config, 'width');
  assert.equal(JSON.stringify(config), before);
  assert.throws(() => generateResponsiveTestCss(config, 'invalid'), /切り替え条件/);
});

test('2枚のテスト画像は16x16の異なるPNGである', () => {
  assert.notEqual(TEST_IMAGES.wide, TEST_IMAGES.narrow);
  for (const value of Object.values(TEST_IMAGES)) {
    const bytes = Buffer.from(value.replace('data:image/png;base64,', ''), 'base64');
    assert.equal(bytes.subarray(0, 8).toString('hex'), '89504e470d0a1a0a');
    assert.equal(bytes.readUInt32BE(16), 16);
    assert.equal(bytes.readUInt32BE(20), 16);
  }
});
