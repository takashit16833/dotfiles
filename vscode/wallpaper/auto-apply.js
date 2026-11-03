'use strict';

// Explicit, reversible workbench HTML patch. No checksum bypass or debugging port.
const fs = require('node:fs/promises');
const path = require('node:path');

const HTML_RELATIVE_PATH = 'out/vs/code/electron-browser/workbench/workbench.html';
const BACKUP_NAME = 'workbench.html.vscode-wallpaper.backup';
const STYLE_NAME = 'vscode-wallpaper.css';
const CSS_HEADER = '/* VS Code Wallpaper: managed stylesheet; generated from user settings. */\n';
const WORKBENCH_CSS = '<link rel="stylesheet" href="../../../workbench/workbench.desktop.main.css">';
const LINK = '<!-- VS Code Wallpaper: managed automatic stylesheet -->\n\t\t<link rel="stylesheet" href="./vscode-wallpaper.css">';

function pathsFor(appRoot) {
  if (typeof appRoot !== 'string' || !path.isAbsolute(appRoot)) {
    throw new Error('VS Code のアプリケーションディレクトリが取得できません。');
  }
  const html = path.join(appRoot, HTML_RELATIVE_PATH);
  return { html, backup: path.join(path.dirname(html), BACKUP_NAME), css: path.join(path.dirname(html), STYLE_NAME) };
}

function patchedHtml(original) {
  const first = original.indexOf(WORKBENCH_CSS);
  if (first < 0 || original.indexOf(WORKBENCH_CSS, first + WORKBENCH_CSS.length) !== -1) {
    throw new Error('対応する VS Code の workbench.html が見つかりません。変更しませんでした。');
  }
  return original.replace(WORKBENCH_CSS, WORKBENCH_CSS + '\n\t\t' + LINK);
}

async function requireRegularOrAbsent(filename) {
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

async function inspect(appRoot) {
  const files = pathsFor(appRoot);
  const stat = await requireRegularOrAbsent(files.html);
  if (!stat) throw new Error('VS Code の workbench.html が見つかりません: ' + files.html);
  const html = await fs.readFile(files.html, 'utf8');
  const backupStat = await requireRegularOrAbsent(files.backup);
  const cssStat = await requireRegularOrAbsent(files.css);
  const hasLink = html.includes(LINK);
  if (!hasLink && html.includes('vscode-wallpaper.css')) {
    throw new Error('別の壁紙用リンクが存在します。既存ファイルは変更しません。');
  }
  if (hasLink) {
    if (!backupStat || !cssStat) throw new Error('壁紙のバックアップまたは CSS がありません。自動修復しません。');
    const backup = await fs.readFile(files.backup, 'utf8');
    if (patchedHtml(backup) !== html) {
      throw new Error('VS Code 本体の HTML に別の変更があります。安全のため操作を中止しました。');
    }
    const css = await fs.readFile(files.css, 'utf8');
    if (!css.startsWith(CSS_HEADER)) throw new Error('管理外の CSS が存在します。変更しません。');
    return { installed: true, files, stat, html, backup, css };
  }
  if (backupStat || cssStat) {
    throw new Error('以前のバックアップまたは CSS が残っています。内容を確認するまで操作しません。');
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

async function enable(appRoot, css) {
  if (typeof css !== 'string' || !css.trim()) throw new Error('壁紙 CSS がありません。enabled と image を確認してください。');
  const info = await inspect(appRoot);
  if (info.installed) {
    await sync(appRoot, css);
    return { installed: true, newlyInstalled: false };
  }
  const patched = patchedHtml(info.html);
  // Write the original backup before modifying VS Code; never overwrite it.
  await fs.writeFile(info.files.backup, info.html, { flag: 'wx', mode: 0o600 });
  try {
    await fs.writeFile(info.files.css, CSS_HEADER + css, { flag: 'wx', mode: 0o644 });
    await atomicWrite(info.files.html, patched, info.stat.mode);
  } catch (error) {
    const current = await fs.readFile(info.files.html, 'utf8').catch(() => null);
    if (current === info.html) {
      await fs.unlink(info.files.css).catch(() => {});
      await fs.unlink(info.files.backup).catch(() => {});
    }
    throw error;
  }
  return { installed: true, newlyInstalled: true };
}

async function sync(appRoot, css) {
  const info = await inspect(appRoot);
  if (!info.installed) return { installed: false, changed: false };
  const next = CSS_HEADER + (typeof css === 'string' ? css : '');
  if (info.css === next) return { installed: true, changed: false };
  await atomicWrite(info.files.css, next, 0o644);
  return { installed: true, changed: true };
}

async function disable(appRoot) {
  const info = await inspect(appRoot);
  if (!info.installed) return { installed: false, changed: false };
  await atomicWrite(info.files.html, info.backup, info.stat.mode);
  await fs.unlink(info.files.css);
  await fs.unlink(info.files.backup);
  return { installed: false, changed: true };
}

module.exports = { HTML_RELATIVE_PATH, CSS_HEADER, LINK, pathsFor, patchedHtml, inspect, enable, sync, disable };
