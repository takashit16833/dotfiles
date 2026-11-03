'use strict';

const { normalizeSettings } = require('./wallpaper');

// Read-only diagnostics to run manually in the VS Code workbench DevTools.
function buildDiagnosticsScript(settings) {
  const config = normalizeSettings(settings);
  const query = config.switchMode === 'aspect-ratio'
    ? `(max-aspect-ratio: ${config.maxAspectRatio.replace('/', ' / ')})`
    : `(max-width: ${config.maxWidth}px)`;
  const hasAlternateImage = !!config.alternateImage;
  return `/* VS Code Wallpaper: 読み取り専用の実画面診断 */
(() => {
  const root = document.querySelector('.monaco-workbench');
  if (!root) throw new Error('VS Code の画面が見つかりません。');
  const media = ${JSON.stringify(query)};
  const alt = ${JSON.stringify(hasAlternateImage)};
  const rect = root.getBoundingClientRect();
  const midY = rect.top + rect.height / 2;
  const leftX = rect.left + Math.min(50, rect.width / 8);
  const describe = el => {
    const style = getComputedStyle(el);
    const r = el.getBoundingClientRect();
    return {
      element: el.tagName.toLowerCase() + (el.id ? '#' + el.id : '') +
        [...el.classList].slice(0, 3).map(c => '.' + c).join(''),
      rect: Math.round(r.x) + ',' + Math.round(r.y) + ' / ' +
        Math.round(r.width) + 'x' + Math.round(r.height),
      display: style.display,
      background: style.backgroundColor,
      hasImage: style.backgroundImage !== 'none'
    };
  };
  console.info('VS Code Wallpaper: サイズと切り替え', {
    width: window.innerWidth, height: window.innerHeight,
    aspectRatio: (window.innerWidth / window.innerHeight).toFixed(3),
    query: media, queryMatches: matchMedia(media).matches,
    alternateImageConfigured: alt,
    rootBackgroundImage: getComputedStyle(root).backgroundImage
  });
  console.info('VS Code Wallpaper: 各領域（0x0 は非表示）');
  console.table([...root.querySelectorAll(
    '.part.editor, .part.sidebar, .part.auxiliarybar, .part.panel, .part.activitybar'
  )].map(describe));
  console.info('VS Code Wallpaper: 左側の重なり（上から順）');
  console.table(document.elementsFromPoint(leftX, midY).slice(0, 16).map(describe));
})();`;
}

module.exports = { buildDiagnosticsScript };
