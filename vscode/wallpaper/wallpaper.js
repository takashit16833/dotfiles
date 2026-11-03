'use strict';
const path = require('node:path');
const os = require('node:os');
const { pathToFileURL, fileURLToPath } = require('node:url');

const DEFAULT_OPACITY = Object.freeze({ editor: 0.70, sidebar: 0.85, panel: 0.85, auxiliaryBar: 0.85, chrome: 0.92, gap: 0 });
const DEFAULT_BACKGROUND_COLORS = Object.freeze({
  editor: 'theme', sidebar: 'theme', panel: 'theme', auxiliaryBar: 'theme', chrome: 'theme', gap: 'theme'
});
const THEME_COLORS = Object.freeze({
  editor: 'var(--vscode-editor-background, #202020)',
  sidebar: 'var(--vscode-sideBar-background, #242424)',
  auxiliaryBar: 'var(--vscode-sideBar-background, #242424)',
  panel: 'var(--vscode-panel-background, #202020)',
  titlebar: 'var(--vscode-titleBar-activeBackground, #202020)',
  statusbar: 'var(--vscode-statusBar-background, #202020)',
  activitybar: 'var(--vscode-activityBar-background, #242424)'
});

function readSettings(configuration) {
  const get = (key, fallback) => configuration.get(key, fallback);
  return {
    enabled: get('enabled', false),
    image: get('image', ''),
    alternateImage: get('alternateImage', ''),
    switchMode: get('switchMode', 'orientation'),
    maxAspectRatio: get('maxAspectRatio', '16/10'),
    maxWidth: get('maxWidth', 1400),
    tint: get('tint', '#FFFFFF'),
    minimapOpacity: get('minimapOpacity', null),
    stickyScrollBlur: get('stickyScrollBlur', 12),
    opacity: { ...DEFAULT_OPACITY, ...get('opacity', {}) },
    backgroundColors: { ...DEFAULT_BACKGROUND_COLORS, ...get('backgroundColors', {}) }
  };
}

function normalizeSettings(settings) {
  const value = {
    ...settings,
    tint: settings.tint ?? '#FFFFFF',
    minimapOpacity: settings.minimapOpacity ?? null,
    stickyScrollBlur: settings.stickyScrollBlur ?? 12,
    opacity: { ...DEFAULT_OPACITY, ...(settings.opacity || {}) },
    backgroundColors: { ...DEFAULT_BACKGROUND_COLORS, ...(settings.backgroundColors || {}) }
  };
  if (!['orientation', 'aspect-ratio', 'width'].includes(value.switchMode)) {
    throw new Error('switchMode は orientation、aspect-ratio、width のいずれかを指定してください。');
  }
  const match = /^(\d+)\s*\/\s*(\d+)$/.exec(String(value.maxAspectRatio));
  if (!match || !Number(match[1]) || !Number(match[2]) || +match[1] > 10000 || +match[2] > 10000) {
    throw new Error('maxAspectRatio は 16/10 のように指定してください。');
  }
  value.maxAspectRatio = `${+match[1]}/${+match[2]}`;
  if (!Number.isInteger(value.maxWidth) || value.maxWidth < 1 || value.maxWidth > 10000) {
    throw new Error('maxWidth は 1～10000 の整数を指定してください。');
  }
  if (!/^#[0-9a-fA-F]{6}$/.test(value.tint)) {
    throw new Error('tint は #FFFFFF のような6桁の色を指定してください。');
  }
  if (value.minimapOpacity !== null &&
      (!Number.isFinite(value.minimapOpacity) || value.minimapOpacity < 0 || value.minimapOpacity > 1)) {
    throw new Error('minimapOpacity は null または 0～1 の数値を指定してください。');
  }
  if (!Number.isInteger(value.stickyScrollBlur) || value.stickyScrollBlur < 0 || value.stickyScrollBlur > 30) {
    throw new Error('stickyScrollBlur は 0～30 の整数を指定してください。');
  }
  for (const [area, opacity] of Object.entries(value.opacity)) {
    if (!Object.hasOwn(DEFAULT_OPACITY, area) || !Number.isFinite(opacity) || opacity < 0 || opacity > 1) {
      throw new Error(`opacity.${area} は 0～1 を指定してください。`);
    }
  }
  for (const [area, color] of Object.entries(value.backgroundColors)) {
    if (!Object.hasOwn(DEFAULT_BACKGROUND_COLORS, area) ||
        (color !== 'theme' && !(typeof color === 'string' && /^#[0-9a-fA-F]{6}$/.test(color)))) {
      throw new Error(`backgroundColors.${area} は theme または #RRGGBB を指定してください。`);
    }
  }
  return value;
}

function resolveImage(value, options = {}) {
  if (!value) return null;
  if (typeof value !== 'string') throw new Error('画像の指定は文字列にしてください。');
  if (/[\u0000-\u001f<>]/.test(value)) throw new Error('画像の指定に使用できない文字があります。');
  if (/^https?:\/\//i.test(value)) return { url: value };
  if (/^data:image\/(png|jpeg|gif|webp);base64,/i.test(value)) return { url: value };
  if (/^vscode-file:\/\//i.test(value)) return { url: value };
  let filename;
  if (/^file:\/\//i.test(value)) {
    try { filename = fileURLToPath(value); } catch { throw new Error('不正な file:// URL です。'); }
  } else if (value.startsWith('~/')) {
    filename = path.join(os.homedir(), value.slice(2));
  } else if (path.isAbsolute(value)) {
    filename = value;
  } else if (value.startsWith('./') || value.startsWith('../')) {
    if (!options.workspaceDirectory) throw new Error('相対画像パスには作業フォルダーが必要です。');
    filename = path.resolve(options.workspaceDirectory, value);
  } else {
    throw new Error('画像には https:// URL、絶対パス、~/ または ./ から始まるパスを指定してください。');
  }
  const fileUri = pathToFileURL(filename).href;
  return { url: fileUri.replace(/^file:\/\//, 'vscode-file://vscode-app'), filename };
}

function cssImage(url) {
  if (/[<>\u0000-\u001f]/.test(url)) throw new Error('画像 URL に使用できない文字があります。');
  return `url("${url.replace(/\\/g, '\\\\').replace(/"/g, '\\"')}")`;
}

function mediaQueryFor(config) {
  if (config.switchMode === 'orientation') return '(orientation: portrait)';
  if (config.switchMode === 'aspect-ratio') {
    return `(max-aspect-ratio: ${config.maxAspectRatio.replace('/', ' / ')})`;
  }
  return `(max-width: ${config.maxWidth}px)`;
}

function generateCss(settings, options = {}) {
  if (!settings.enabled) return '';
  const config = normalizeSettings(settings);
  const resolver = options.resolveUrl || (value => resolveImage(value, options)?.url);
  const defaultUrl = resolver(config.image);
  if (!defaultUrl) throw new Error('vscodeWallpaper.image を設定してください。');
  const alternateUrl = config.alternateImage ? resolver(config.alternateImage) : null;
  const root = options.rootSelector || '.monaco-workbench';
  const imageRule = image => `linear-gradient(${config.tint}, ${config.tint}), ${cssImage(image)}`;
  const query = mediaQueryFor(config);
  const overlay = (selector, area, themeColor) => {
    const specified = config.backgroundColors[area];
    const color = specified === 'theme' ? themeColor : specified;
    return `${selector} { background-color: color-mix(in srgb, ${color} ${config.opacity[area] * 100}%, transparent) !important; }`;
  };
  return `/* Generated by VS Code Wallpaper. */
${root} {
  background-color: var(--vscode-editor-background, #202020) !important;
  background-image: ${imageRule(defaultUrl)} !important;
  background-blend-mode: multiply, normal !important;
  background-size: cover, cover !important;
  background-position: center, center !important;
  background-repeat: no-repeat !important;
}
${alternateUrl ? `@media ${query} {
  ${root} { background-image: ${imageRule(alternateUrl)} !important; }
}\n` : ''}${overlay(`${root} .part.editor`, 'editor', THEME_COLORS.editor)}
${overlay(`${root} .part.sidebar`, 'sidebar', THEME_COLORS.sidebar)}
${overlay(`${root} .part.auxiliarybar`, 'auxiliaryBar', THEME_COLORS.auxiliaryBar)}
/* Floating sidebars use more specific !important rules in VS Code floatingPanels.css. */
${overlay(`${root}.floating-panels .part.sidebar`, 'sidebar', THEME_COLORS.sidebar)}
${overlay(`${root}.floating-panels .part.auxiliarybar`, 'auxiliaryBar', THEME_COLORS.auxiliaryBar)}
${overlay(`${root} .part.panel`, 'panel', THEME_COLORS.panel)}
/* 浮動パネルには VS Code 本体のより詳細な !important 規則があるため、同じ条件で上書きする。 */
${overlay(`${root}.floating-panels .part.panel`, 'panel', THEME_COLORS.panel)}
${overlay(`${root} .part.titlebar`, 'chrome', THEME_COLORS.titlebar)}
${overlay(`${root} .part.statusbar`, 'chrome', THEME_COLORS.statusbar)}
${overlay(`${root} .part.activitybar`, 'chrome', THEME_COLORS.activitybar)}
/* 実機で確認した不透明な下地を透明にする。 */
${root} .monaco-grid-view,
${root} .part.panel .pane.expanded.horizontal,
${root} .part.panel .terminal-outer-container,
${root} .part.panel .terminal.xterm,
${root} .part.panel .xterm-scrollable-element,
${root} .part.editor :is(.content, .editor-group-container, .editor-container, .editor-instance, .monaco-editor, .monaco-editor-background, .margin, .title, .tabs-container),
${root} :is(.part.sidebar, .part.auxiliarybar, .part.panel) > .content,
${root} .part.panel .xterm-viewport {
  background-color: transparent !important;
}

/* Floating-card gutters are margins. Paint these only, not the card surfaces. */
${config.opacity.gap > 0 ? `
${root}.floating-panels:not(.modern-ui-compact) .split-view-view:has(> .part:is(.editor, .sidebar, .auxiliarybar, .panel)) {
  --vscode-wallpaper-gap-left: var(--modern-ui-floating-card-margin, 0px);
  --vscode-wallpaper-gap-right: var(--modern-ui-floating-card-inner-margin, 0px);
  --vscode-wallpaper-gap-top: var(--modern-ui-floating-card-inner-margin, 0px);
  --vscode-wallpaper-gap-bottom: var(--modern-ui-floating-card-margin, 0px);
  --vscode-wallpaper-gap-color: color-mix(in srgb, ${config.backgroundColors.gap === 'theme' ? THEME_COLORS.editor : config.backgroundColors.gap} ${config.opacity.gap * 100}%, transparent);
}

/* Keep the gap dimensions aligned with VS Code floatingPanels.css. */
${root}.floating-panels:not(.modern-ui-compact) .split-view-view:has(> .part.floating-part-outer-right),
${root}.floating-panels:not(.modern-ui-compact) .split-view-view:has(> .part.editor.floating-editor-outer-right) {
  --vscode-wallpaper-gap-right: var(--modern-ui-floating-card-outer-margin, 0px);
}
${root}.floating-panels:not(.modern-ui-compact):not(.noactivitybar) .split-view-view:has(> .part.sidebar.left) {
  --vscode-wallpaper-gap-left: var(--modern-ui-floating-card-inner-margin, 0px);
}
${root}.floating-panels.top-window-edge:not(.modern-ui-compact) .split-view-view:has(> .part:is(.sidebar, .auxiliarybar, .editor, .panel.top, .panel.left, .panel.right)),
${root}.floating-panels.panel-position-top:not(.nopanel):not(.modern-ui-compact) .split-view-view:has(> .part.editor),
${root}.floating-panels.panel-position-bottom:not(.nopanel):not(.nomaineditorarea):not(.modern-ui-compact) .split-view-view:has(> .part.panel.bottom) {
  --vscode-wallpaper-gap-top: var(--modern-ui-floating-card-margin, 0px);
}

/* Four non-overlapping strips prevent extra opacity at the corners. */
${root}.floating-panels:not(.modern-ui-compact) .split-view-view:has(> .part:is(.editor, .sidebar, .auxiliarybar, .panel))::before {
  content: "";
  position: absolute;
  inset: 0;
  pointer-events: none;
  background-image:
    linear-gradient(var(--vscode-wallpaper-gap-color), var(--vscode-wallpaper-gap-color)),
    linear-gradient(var(--vscode-wallpaper-gap-color), var(--vscode-wallpaper-gap-color)),
    linear-gradient(var(--vscode-wallpaper-gap-color), var(--vscode-wallpaper-gap-color)),
    linear-gradient(var(--vscode-wallpaper-gap-color), var(--vscode-wallpaper-gap-color));
  background-position:
    left top,
    right top,
    var(--vscode-wallpaper-gap-left) top,
    var(--vscode-wallpaper-gap-left) bottom;
  background-size:
    var(--vscode-wallpaper-gap-left) 100%,
    var(--vscode-wallpaper-gap-right) 100%,
    calc(100% - var(--vscode-wallpaper-gap-left) - var(--vscode-wallpaper-gap-right)) var(--vscode-wallpaper-gap-top),
    calc(100% - var(--vscode-wallpaper-gap-left) - var(--vscode-wallpaper-gap-right)) var(--vscode-wallpaper-gap-bottom);
  background-repeat: no-repeat;
}
` : ''}

/* Measured opaque surfaces: editor tab strip and Explorer lists in the bottom panel.
   Preserve selected rows, individual tabs, and scrollbar thumbs. */
${root} .part.editor .tabs-and-actions-container,
${root} .part.panel .monaco-list-rows {
  background-color: transparent !important;
}

/* VS Code Modern UI paints tab fills and a title gradient independently.
   Clear them without changing tab text or borders. */
${root}.modern-ui-tabs .part.editor > .content .editor-group-container > .title.tabs {
  background-color: transparent !important;
  background-image: none !important;
}
${root}.modern-ui-tabs .part.editor .tabs-container > .tab > .tab-fill {
  background-color: transparent !important;
}

/* Clear the terminal switcher containers, leaving individual terminal rows intact. */
${root} .part.panel .pane-body.integrated-terminal :is(.tabs-container, .tabs-list-container, .tabs-list, .monaco-list-rows) {
  background-color: transparent !important;
}

/* VS Code scrollbar CSS uses background shorthand for the track,
   and separate variables for the slider. Keep the slider untouched. */
${root} {
  --vscode-scrollbar-background: transparent !important;
  --vscode-breadcrumb-background: transparent !important;
}
${root} :is(.part.editor, .part.panel) .monaco-scrollable-element > .scrollbar {
  background: transparent !important;
  background-color: transparent !important;
}

/* Breadcrumbs include a row, nested controls, and an editor-type label.
   Keep the more specific selectors for independently painted layers. */
${root} .part.editor :is(.breadcrumbs-below-tabs, .breadcrumbs-control, .breadcrumbs-editor-type),
${root} .part.editor .breadcrumbs-below-tabs .breadcrumbs-control,
${root} .part.editor .breadcrumbs-below-tabs .monaco-breadcrumbs,
${root} .part.editor .breadcrumbs-control.with-editor-type > .breadcrumbs-editor-type {
  background-color: transparent !important;
  background-image: none !important;
}

/* Minimap background is painted into canvas; fade only by explicit user choice. */
${config.minimapOpacity === null ? '' : `${root} .part.editor .monaco-editor .minimap canvas {
  opacity: ${config.minimapOpacity} !important;
}
`}

/* Blur what is behind Sticky Scroll, not the pinned text itself.
   The component backgrounds are transparent, so the wallpaper stays visible. */
${config.stickyScrollBlur > 0 ? `${root} .part.editor .monaco-editor .sticky-widget:not(.peek) {
  backdrop-filter: blur(${config.stickyScrollBlur}px) !important;
}` : ''}

/* Sticky Scroll pins enclosing code to the top of the editor.
   VS Code stickyScroll.css gives the gutter and lines-scrollable separate opaque
   backgrounds. Their descendants inherit them, so clear only these two layers.
   Exclude peek editors and retain sticky-line hover/foreground styling. */
${root} .part.editor .monaco-editor .sticky-widget:not(.peek) .sticky-widget-line-numbers,
${root} .part.editor .monaco-editor .sticky-widget:not(.peek) .sticky-widget-lines-scrollable {
  background-color: transparent !important;
}

/* The Search / Explorer title remains opaque even when the sidebar is translucent.
   Keep its buttons and text unchanged. */
${root} :is(.part.sidebar, .part.auxiliarybar) > .composite.title {
  background-color: transparent !important;
}

/* The Extensions list rows container was measured as opaque.
   Keep selected/hovered rows unchanged, and only clear the list's backing layer. */
${root} :is(.part.sidebar, .part.auxiliarybar) .monaco-list-rows {
  background-color: transparent !important;
}

/* VS Code paneHeaders.css paints sidebar panes and headers opaque.
   Preserve header hover styling while showing the shared wallpaper. */
${root}.modern-ui :is(.part.sidebar, .part.auxiliarybar) .monaco-pane-view .pane,
${root}.modern-ui :is(.part.sidebar, .part.auxiliarybar) .monaco-pane-view .pane > .pane-header:not(:hover) {
  background-color: transparent !important;
}
`;
}

module.exports = { DEFAULT_OPACITY, DEFAULT_BACKGROUND_COLORS, readSettings, normalizeSettings, resolveImage, cssImage, mediaQueryFor, generateCss };
