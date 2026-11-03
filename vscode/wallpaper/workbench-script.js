'use strict';

const SHEET_KEY = '__vscodeWallpaperTemporaryStyleSheet';

// Generate script for a manually initiated, in-memory workbench test.
// No VS Code files, persistent settings, ports or checksum checks are modified.
function buildApplyScript(css) {
  if (typeof css !== 'string' || !css.trim()) {
    throw new Error('適用する CSS がありません。');
  }
  return `/* VS Code Wallpaper: 一時適用テスト。開発者ツールの Console でのみ実行する。 */
(() => {
  const workbench = document.querySelector('.monaco-workbench');
  if (!workbench) {
    throw new Error('VS Code の画面が見つかりません。開発者ツールの実行対象を確認してください。');
  }
  const key = ${JSON.stringify(SHEET_KEY)};
  const previous = window[key];
  const next = new CSSStyleSheet();
  next.replaceSync(${JSON.stringify(css)});
  document.adoptedStyleSheets = [
    ...document.adoptedStyleSheets.filter(sheet => sheet !== previous),
    next
  ];
  window[key] = next;
  console.info('VS Code Wallpaper: 一時 CSS を適用しました', {
    backgroundImage: getComputedStyle(workbench).backgroundImage
  });
})();`;
}

function buildRemoveScript() {
  return `/* VS Code Wallpaper: 一時適用の取り消し */
(() => {
  const key = ${JSON.stringify(SHEET_KEY)};
  const sheet = window[key];
  if (sheet) {
    document.adoptedStyleSheets = document.adoptedStyleSheets.filter(item => item !== sheet);
    delete window[key];
  }
  console.info('VS Code Wallpaper: 一時 CSS を解除しました');
})();`;
}

module.exports = { SHEET_KEY, buildApplyScript, buildRemoveScript };
