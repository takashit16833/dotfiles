'use strict';

// Explicit, reversible VS Code workbench patch. No checksum bypass or debug port.
// The renderer selects a different stylesheet for each window's workspace ID.
const fs = require('node:fs/promises');
const path = require('node:path');

const HTML_RELATIVE_PATH = 'out/vs/code/electron-browser/workbench/workbench.html';
const BACKUP_NAME = 'workbench.html.vscode-wallpaper.backup';
const STYLE_NAME = 'vscode-wallpaper.css'; // Retained for migration from v0.4.
const LOADER_NAME = 'vscode-wallpaper-loader.js';
const CSS_HEADER = '/* VS Code Wallpaper: managed stylesheet; generated from user settings. */\n';
const WORKBENCH_CSS = '<link rel="stylesheet" href="../../../workbench/workbench.desktop.main.css">';
const LEGACY_LINK = '<!-- VS Code Wallpaper: managed automatic stylesheet -->\n\t\t<link rel="stylesheet" href="./vscode-wallpaper.css">';
const LINK = '<!-- VS Code Wallpaper: managed per-workspace stylesheet -->\n\t\t<script type="module" src="./vscode-wallpaper-loader.js"></script>';

function pathsFor(appRoot) {
  if (typeof appRoot !== 'string' || !path.isAbsolute(appRoot)) {
    throw new Error('VS Code のアプリケーションディレクトリが取得できません。');
  }
  const html = path.join(appRoot, HTML_RELATIVE_PATH);
  const dir = path.dirname(html);
  return { html, dir, backup: path.join(dir, BACKUP_NAME), css: path.join(dir, STYLE_NAME), loader: path.join(dir, LOADER_NAME) };
}

function workspaceStylePath(files, id) {
  if (typeof id !== 'string' || !/^[a-zA-Z0-9_-]{1,128}$/.test(id)) {
    throw new Error('不正なワークスペース識別子です。');
  }
  return path.join(files.dir, 'vscode-wallpaper-' + id + '.css');
}

function patchWith(original, link) {
  const index = original.indexOf(WORKBENCH_CSS);
  if (index < 0 || original.indexOf(WORKBENCH_CSS, index + WORKBENCH_CSS.length) !== -1) {
    throw new Error('対応する VS Code の workbench.html が見つかりません。変更しませんでした。');
  }
  return original.replace(WORKBENCH_CSS, WORKBENCH_CSS + '\n\t\t' + link);
}

function patchedHtml(original) { return patchWith(original, LINK); }
function patchedLegacyHtml(original) { return patchWith(original, LEGACY_LINK); }

async function regularOrAbsent(filename) {
  try {
    const stat = await fs.lstat(filename);
    if (!stat.isFile() || stat.isSymbolicLink()) {
      throw new Error('管理対象が通常ファイルではありません: ' + filename);
    }
    return stat;
  } catch (error) {
    if (error.code === 'ENOENT') return null;
    throw error;
  }
}

async function readOwnedCss(filename) {
  if (!await regularOrAbsent(filename)) return null;
  const content = await fs.readFile(filename, 'utf8');
  if (!content.startsWith(CSS_HEADER)) throw new Error('管理外の CSS が存在します: ' + filename);
  return content;
}

async function inspect(appRoot) {
  const files = pathsFor(appRoot);
  const stat = await regularOrAbsent(files.html);
  if (!stat) throw new Error('VS Code の workbench.html が見つかりません: ' + files.html);
  const html = await fs.readFile(files.html, 'utf8');
  const backupStat = await regularOrAbsent(files.backup);
  const loaderStat = await regularOrAbsent(files.loader);
  const css = await readOwnedCss(files.css);
  const modern = html.includes(LINK);
  const legacy = !modern && html.includes(LEGACY_LINK);

  if (modern || legacy) {
    if (!backupStat) throw new Error('元の workbench.html のバックアップがありません。');
    const backup = await fs.readFile(files.backup, 'utf8');
    if ((modern ? patchedHtml(backup) : patchedLegacyHtml(backup)) !== html) {
      throw new Error('VS Code 本体の HTML に別の変更があります。操作を中止しました。');
    }
    if (legacy && !css) throw new Error('旧方式の CSS がありません。');
    if (modern) {
      if (!loaderStat) throw new Error('壁紙読み込みスクリプトがありません。');
      const actual = await fs.readFile(files.loader, 'utf8');
      const expected = await fs.readFile(path.join(__dirname, 'renderer-loader.js'), 'utf8');
      if (actual !== expected) throw new Error('壁紙読み込みスクリプトが変更されています。');
    }
    return { installed: true, legacy, files, stat, backup, html, css };
  }

  if (backupStat || loaderStat || css || html.includes('vscode-wallpaper')) {
    throw new Error('以前の壁紙ファイルが残っています。確認せずに上書きしません。');
  }
  return { installed: false, files, stat, html };
}

async function atomicWrite(filename, content, mode) {
  const temp = filename + '.tmp-' + process.pid + '-' + Math.random().toString(16).slice(2);
  try {
    await fs.writeFile(temp, content, { flag: 'wx', mode });
    await fs.rename(temp, filename);
  } catch (error) {
    await fs.unlink(temp).catch(() => {});
    throw error;
  }
}

async function writeWorkspaceCss(files, css, id) {
  const filename = workspaceStylePath(files, id);
  const previous = await readOwnedCss(filename);
  const next = CSS_HEADER + css;
  if (previous === next) return false;
  await atomicWrite(filename, next, 0o644);
  return true;
}

async function enable(appRoot, css, id) {
  if (typeof css !== 'string') throw new Error('CSS が不正です。');
  const info = await inspect(appRoot);
  const stylePath = workspaceStylePath(info.files, id);
  const previousWorkspaceCss = await readOwnedCss(stylePath);
  if (info.installed && !info.legacy) {
    await writeWorkspaceCss(info.files, css, id);
    return { installed: true, newlyInstalled: false };
  }

  const loader = await fs.readFile(path.join(__dirname, 'renderer-loader.js'), 'utf8');
  const isUpgrade = info.installed && info.legacy;
  const original = isUpgrade ? info.backup : info.html;
  const patched = patchedHtml(original);
  if (!isUpgrade) {
    await fs.writeFile(info.files.backup, original, { flag: 'wx', mode: 0o600 });
  }
  try {
    if (await regularOrAbsent(info.files.loader)) throw new Error('既存の壁紙スクリプトがあります。');
    await fs.writeFile(info.files.loader, loader, { flag: 'wx', mode: 0o644 });
    await writeWorkspaceCss(info.files, css, id);
    if (isUpgrade) {
      await atomicWrite(info.files.css, CSS_HEADER, 0o644);
    } else {
      await fs.writeFile(info.files.css, CSS_HEADER, { flag: 'wx', mode: 0o644 });
    }
    await atomicWrite(info.files.html, patched, info.stat.mode);
  } catch (error) {
    const current = await fs.readFile(info.files.html, 'utf8').catch(() => null);
    if (current === info.html) {
      await fs.unlink(info.files.loader).catch(() => {});
      if (previousWorkspaceCss === null) {
        await fs.unlink(stylePath).catch(() => {});
      } else {
        await atomicWrite(stylePath, previousWorkspaceCss, 0o644).catch(() => {});
      }
      if (isUpgrade) {
        await atomicWrite(info.files.css, info.css, 0o644).catch(() => {});
      } else {
        await fs.unlink(info.files.css).catch(() => {});
        await fs.unlink(info.files.backup).catch(() => {});
      }
    }
    throw error;
  }
  return { installed: true, newlyInstalled: !isUpgrade };
}

async function sync(appRoot, css, id) {
  if (typeof css !== 'string') throw new Error('CSS が不正です。');
  const info = await inspect(appRoot);
  if (!info.installed) return { installed: false, changed: false };
  if (info.legacy) {
    await enable(appRoot, css, id);
    return { installed: true, changed: true };
  }
  const changed = await writeWorkspaceCss(info.files, css, id);
  return { installed: true, changed };
}

async function disable(appRoot) {
  const info = await inspect(appRoot);
  if (!info.installed) return { installed: false, changed: false };

  // Check all managed CSS files before restoring the HTML.
  const names = (await fs.readdir(info.files.dir)).filter(name =>
    /^vscode-wallpaper-[a-zA-Z0-9_-]+\.css$/.test(name));
  for (const name of names) await readOwnedCss(path.join(info.files.dir, name));
  await atomicWrite(info.files.html, info.backup, info.stat.mode);
  for (const name of names) await fs.unlink(path.join(info.files.dir, name));
  if (!info.legacy) await fs.unlink(info.files.loader);
  if (info.css) await fs.unlink(info.files.css);
  await fs.unlink(info.files.backup);
  return { installed: false, changed: true };
}

module.exports = {
  HTML_RELATIVE_PATH, CSS_HEADER, LEGACY_LINK, LINK, pathsFor, patchedHtml,
  workspaceStylePath, inspect, enable, sync, disable
};
