'use strict';

const path = require('node:path');
const vscode = require('vscode');
const { readSettings, resolveImage, generateCss } = require('./wallpaper');
const { buildApplyScript, buildRemoveScript } = require('./workbench-script');
const { buildDiagnosticsScript } = require('./diagnostics-script');

let previewPanel;

function currentSettings() {
  return readSettings(vscode.workspace.getConfiguration('vscodeWallpaper'));
}

function workspaceDirectory() {
  return vscode.workspace.workspaceFolders?.[0]?.uri.fsPath;
}

function cssFor(settings, webview) {
  const workspace = workspaceDirectory();
  return generateCss(settings, {
    workspaceDirectory: workspace,
    resolveUrl: value => {
      const image = resolveImage(value, { workspaceDirectory: workspace });
      if (!image) return null;
      return image.filename && webview
        ? webview.asWebviewUri(vscode.Uri.file(image.filename)).toString()
        : image.url;
    }
  });
}

function escapeHtml(value) {
  return String(value).replace(/[&<>"']/g, char => ({
    '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;'
  })[char]);
}

function renderPreview(panel) {
  const settings = currentSettings();
  if (!settings.enabled) {
    panel.webview.html = '<!doctype html><meta charset="utf-8"><p>vscodeWallpaper.enabled を true にしてください。</p>';
    return;
  }
  try {
    const css = cssFor(settings, panel.webview);
    const previewCss = `
      html, body { padding: 0; margin: 0; height: 100%; color: #efefef; font: 14px sans-serif; }
      .monaco-workbench { width: 100vw; height: 100vh; display: flex; flex-direction: column; }
      .part.titlebar, .part.statusbar { padding: 10px 16px; }
      .wallpaper-layout { flex: 1; min-height: 0; display: flex; }
      .part.sidebar { width: 27%; padding: 18px; box-sizing: border-box; }
      .wallpaper-center { flex: 1; display: flex; flex-direction: column; min-width: 0; }
      .part.editor { flex: 1; padding: 24px; min-height: 0; }
      .part.panel { height: 25%; padding: 14px 24px; box-sizing: border-box; }
      pre { font-size: 14px; line-height: 1.7; white-space: pre-wrap; }
    `;
    const roots = [settings.image, settings.alternateImage]
      .filter(Boolean).map(value => resolveImage(value, { workspaceDirectory: workspaceDirectory() }))
      .filter(image => image?.filename).map(image => vscode.Uri.file(path.dirname(image.filename)));
    // Webview のローカル画像参照は指定されたディレクトリだけを許可する。
    panel.webview.options = { enableScripts: false, localResourceRoots: roots };
    panel.webview.html = `<!doctype html><html lang="ja"><head><meta charset="utf-8">
      <meta http-equiv="Content-Security-Policy" content="default-src 'none'; img-src https: data: ${panel.webview.cspSource}; style-src 'unsafe-inline';">
      <style>${previewCss}\n${css}</style></head><body>
      <div class="monaco-workbench vs-dark"><div class="part titlebar">VS Code Wallpaper — プレビュー</div>
      <div class="wallpaper-layout"><aside class="part sidebar">EXPLORER<hr>src/<br>　Main.hs<br>　Model.hs<br>README.md</aside>
      <div class="wallpaper-center"><div class="part editor"><pre>module Main where\n\nmain :: IO ()\nmain = putStrLn "Hello"</pre></div>
      <div class="part panel">TERMINAL<hr>$ cabal test</div></div></div>
      <div class="part statusbar">Preview: 背景合成と切り替えのみを確認できます</div></div></body></html>`;
  } catch (error) {
    panel.webview.html = `<!doctype html><meta charset="utf-8"><p>設定エラー: ${escapeHtml(error.message)}</p>`;
  }
}

function activate(context) {
  context.subscriptions.push(vscode.commands.registerCommand('vscodeWallpaper.preview', () => {
    if (previewPanel) { previewPanel.reveal(); renderPreview(previewPanel); return; }
    previewPanel = vscode.window.createWebviewPanel('vscodeWallpaperPreview', 'VS Code Wallpaper プレビュー', vscode.ViewColumn.Active, {
      enableScripts: false
    });
    previewPanel.onDidDispose(() => { previewPanel = undefined; }, null, context.subscriptions);
    renderPreview(previewPanel);
  }));
  context.subscriptions.push(vscode.commands.registerCommand('vscodeWallpaper.showCss', async () => {
    try {
      const css = cssFor(currentSettings());
      if (!css) { vscode.window.showInformationMessage('vscodeWallpaper.enabled を true にしてください。'); return; }
      const doc = await vscode.workspace.openTextDocument({ language: 'css', content: css });
      await vscode.window.showTextDocument(doc, { preview: false });
    } catch (error) {
      vscode.window.showErrorMessage(`VS Code Wallpaper: ${error.message}`);
    }
  }));
  context.subscriptions.push(vscode.commands.registerCommand('vscodeWallpaper.showWorkbenchScript', async () => {
    try {
      const css = cssFor(currentSettings());
      if (!css) { vscode.window.showInformationMessage('vscodeWallpaper.enabled を true にしてください。'); return; }
      const doc = await vscode.workspace.openTextDocument({
        language: 'javascript',
        content: buildApplyScript(css)
      });
      await vscode.window.showTextDocument(doc, { preview: false });
    } catch (error) {
      vscode.window.showErrorMessage(`VS Code Wallpaper: ${error.message}`);
    }
  }));
  context.subscriptions.push(vscode.commands.registerCommand('vscodeWallpaper.showRemoveScript', async () => {
    const doc = await vscode.workspace.openTextDocument({
      language: 'javascript',
      content: buildRemoveScript()
    });
    await vscode.window.showTextDocument(doc, { preview: false });
  }));
  context.subscriptions.push(vscode.commands.registerCommand('vscodeWallpaper.showDiagnosticsScript', async () => {
    try {
      const doc = await vscode.workspace.openTextDocument({
        language: 'javascript',
        content: buildDiagnosticsScript(currentSettings())
      });
      await vscode.window.showTextDocument(doc, { preview: false });
    } catch (error) {
      vscode.window.showErrorMessage(`VS Code Wallpaper: ${error.message}`);
    }
  }));
  context.subscriptions.push(vscode.workspace.onDidChangeConfiguration(event => {
    if (event.affectsConfiguration('vscodeWallpaper') && previewPanel) renderPreview(previewPanel);
  }));
}

function deactivate() { previewPanel = undefined; }
module.exports = { activate, deactivate };
