'use strict';

const { normalizeSettings, mediaQueryFor } = require('./wallpaper');

// Read-only diagnostics to run manually in the VS Code workbench DevTools.
function buildDiagnosticsScript(settings) {
  const config = normalizeSettings(settings);
  const query = mediaQueryFor(config);
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
    orientation: matchMedia('(orientation: portrait)').matches ? 'portrait' : 'landscape',
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

  // Probe opaque surfaces at several points, without editing VS Code.
  const samples = [
    ['編集タブ', '.part.editor', 0.50, 0.02],
    ['編集右端・スクロールバー', '.part.editor', 0.98, 0.55],
    ['パネルタブ', '.part.panel', 0.50, 0.025],
    ['パネル左上', '.part.panel', 0.20, 0.30],
    ['パネル左下', '.part.panel', 0.20, 0.75],
    ['パネル中央', '.part.panel', 0.55, 0.40],
    ['パネル右上', '.part.panel', 0.85, 0.30],
    ['パネル右下', '.part.panel', 0.85, 0.75]
  ];
  const opaque = [];
  for (const [position, selector, xPart, yPart] of samples) {
    const part = document.querySelector('.monaco-workbench ' + selector);
    if (!part) continue;
    const r = part.getBoundingClientRect();
    if (r.width < 1 || r.height < 1) continue;
    const x = r.left + r.width * xPart;
    const y = r.top + r.height * yPart;
    const painted = document.elementsFromPoint(x, y).slice(0, 24)
      .filter(el => el !== root)
      .map(el => ({ position, ...describe(el) }))
      .filter(row => !['transparent', 'rgba(0, 0, 0, 0)'].includes(row.background) || row.hasImage)
      .slice(0, 6);
    opaque.push(...painted);
  }
  console.info('VS Code Wallpaper: 編集タブ・スクロールバー・パネル内の背景');
  console.table(opaque);
  const selectors = [
    '.part.editor .tabs-container',
    '.part.editor .tab.active',
    '.part.editor .scrollbar.vertical',
    '.part.editor .scrollbar.vertical .slider',
    '.part.panel .monaco-list-rows',
    '.part.panel .pane.expanded',
    '.part.panel .scrollbar.vertical',
    '.part.panel .scrollbar.vertical .slider'
  ];
  console.info('VS Code Wallpaper: 個別要素の背景色');
  console.table(selectors.map(selector => {
    const el = document.querySelector('.monaco-workbench ' + selector);
    const style = el && getComputedStyle(el);
    return {
      selector,
      background: style?.backgroundColor || '要素なし',
      image: style?.backgroundImage || 'none'
    };
  }));

})();`;
}

module.exports = { buildDiagnosticsScript };
