'use strict';

const { generateCss } = require('./wallpaper');

// Two small, bundled checkered PNG images. No network is needed.
const TEST_IMAGES = Object.freeze({
  wide: 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAIAAACQkWg2AAAAJElEQVR42mP47xgARx/uRMERLnGGQaiBGEXI4oNRw2g8DAoNACg42xB/2REDAAAAAElFTkSuQmCC',
  narrow: 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAIAAACQkWg2AAAAJElEQVR42mPQLfgKR44Pr8MRLnGGQaiBGEXI4oNRw2g8DAoNAOirxZA6dGQ0AAAAAElFTkSuQmCC'
});
const TEST_THRESHOLDS = Object.freeze({ 'aspect-ratio': '1/2', width: 800 });

function generateResponsiveTestCss(settings, mode) {
  if (!Object.hasOwn(TEST_THRESHOLDS, mode)) {
    throw new Error('テストする切り替え条件を指定してください。');
  }
  const opacity = Object.fromEntries(
    ['editor', 'sidebar', 'panel', 'auxiliaryBar', 'chrome'].map(area => [area, 0.4])
  );
  return generateCss({
    ...settings,
    enabled: true,
    image: TEST_IMAGES.wide,
    alternateImage: TEST_IMAGES.narrow,
    switchMode: mode,
    maxAspectRatio: TEST_THRESHOLDS['aspect-ratio'],
    maxWidth: TEST_THRESHOLDS.width,
    tint: '#FFFFFF',
    opacity,
    backgroundColors: {
      editor: 'theme', sidebar: 'theme', panel: 'theme', auxiliaryBar: 'theme', chrome: 'theme'
    }
  });
}

module.exports = { TEST_IMAGES, TEST_THRESHOLDS, generateResponsiveTestCss };
