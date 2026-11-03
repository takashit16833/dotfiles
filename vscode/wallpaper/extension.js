'use strict';

const path = require('node:path');
const automatic = require('./auto-apply');
const { currentWorkspaceId } = require('./workspace-id');
const vscode = require('vscode');
const { readSettings, resolveImage, generateCss } = require('./wallpaper');
const { buildApplyScript, buildRemoveScript } = require('./workbench-script');
const { buildDiagnosticsScript } = require('./diagnostics-script');
const { generateResponsiveTestCss } = require('./responsive-test');

let previewPanel;

function currentSettings() {
  return readSettings(vscode.workspace.getConfiguration('vscodeWallpaper'));
}

function workspaceDirectory() {
  return vscode.workspace.workspaceFolders?.[0]?.uri.fsPath;
}

function cssFor(settings, webview, workspace = workspaceDirectory()) {
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

async function autoState() {
  return {
    css: cssFor(currentSettings()),
    workspaceId: await currentWorkspaceId(vscode.workspace)
  };
}

async function refreshAutomatic(context, notify = false) {
  if (!context.globalState.get('vscodeWallpaper.autoEnabled', false)) return;
  const state = await automatic.inspect(vscode.env.appRoot);
  if (!state.installed) {
    if (notify) vscode.window.showWarningMessage('VS Code の更新などで自動壁紙の読み込みが外れています。Enable Automatic Wallpaper を再実行してください。');
    return;
  }
  const { css, workspaceId } = await autoState();
  const result = await automatic.sync(vscode.env.appRoot, css, workspaceId);
  if (result.loaderChanged && notify) {
    const action = await vscode.window.showInformationMessage(
      'VS Code Wallpaper: 設定変更をすぐ反映する機能に更新しました。読み込み処理を切り替えるため、一度だけウィンドウを再読み込みしてください。',
      'Reload Window'
    );
    if (action === 'Reload Window') {
      await vscode.commands.executeCommand('workbench.action.reloadWindow');
    }
  }
}

function activate(context) {
  context.subscriptions.push(vscode.commands.registerCommand('vscodeWallpaper.enableAutomatic', async () => {
    const choice = await vscode.window.showWarningMessage(
      '自動適用では VS Code 本体の workbench.html に CSS の読み込みを追加します。元ファイルはバックアップしますが、整合性警告が出る可能性があります。VS Code 更新後は再導入が必要です。',
      { modal: true }, '自動適用を有効にする'
    );
    if (choice !== '自動適用を有効にする') return;
    try {
      const { css, workspaceId } = await autoState();
      const result = await automatic.enable(vscode.env.appRoot, css, workspaceId);
      await context.globalState.update('vscodeWallpaper.autoEnabled', true);
      const reload = await vscode.window.showInformationMessage(
        result.newlyInstalled ? '自動適用を導入しました。VS Code の再読み込み後から有効になります。' : '壁紙 CSS を更新しました。',
        'Reload Window'
      );
      if (reload === 'Reload Window') await vscode.commands.executeCommand('workbench.action.reloadWindow');
    } catch (error) {
      vscode.window.showErrorMessage('VS Code Wallpaper: ' + error.message);
    }
  }));
  context.subscriptions.push(vscode.commands.registerCommand('vscodeWallpaper.disableAutomatic', async () => {
    try {
      const result = await automatic.disable(vscode.env.appRoot);
      await context.globalState.update('vscodeWallpaper.autoEnabled', false);
      if (!result.changed) { vscode.window.showInformationMessage('自動適用は導入されていません。'); return; }
      const reload = await vscode.window.showInformationMessage(
        'バックアップから workbench.html を復元しました。再読み込みで解除されます。', 'Reload Window'
      );
      if (reload === 'Reload Window') await vscode.commands.executeCommand('workbench.action.reloadWindow');
    } catch (error) {
      vscode.window.showErrorMessage('VS Code Wallpaper: ' + error.message);
    }
  }));
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
  context.subscriptions.push(vscode.commands.registerCommand('vscodeWallpaper.showResponsiveTestScript', async () => {
    const choice = await vscode.window.showQuickPick([
      { label: '縦長・横長', description: '高さが横幅以上なら青、横幅の方が大きければ赤', mode: 'orientation' },
      { label: '横幅：800px', description: '幅が800px以下なら青、超えたら赤', mode: 'width' }
    ], { placeHolder: '画像切り替えの検証方法を選んでください' });
    if (!choice) return;
    try {
      const css = generateResponsiveTestCss(currentSettings(), choice.mode);
      const comment = choice.mode === 'orientation'
        ? '縦長・横長：高さが横幅以上なら青、横幅の方が大きければ赤'
        : '横幅：800px以下なら青、超えたら赤';
      const script = `/* ${comment}。
一時壁紙を入れ替えるが、設定・VS Code本体ファイルは変更しない。
元に戻すには Show Temporary Workbench Script を再実行するか、
Show Remove Script / Developer: Reload Window を使う。 */
${buildApplyScript(css)}`;
      const doc = await vscode.workspace.openTextDocument({
        language: 'javascript', content: script
      });
      await vscode.window.showTextDocument(doc, { preview: false });
    } catch (error) {
      vscode.window.showErrorMessage(`VS Code Wallpaper: ${error.message}`);
    }
  }));
  context.subscriptions.push(vscode.workspace.onDidChangeConfiguration(event => {
    if (!event.affectsConfiguration('vscodeWallpaper')) return;
    if (previewPanel) renderPreview(previewPanel);
    refreshAutomatic(context, true).catch(error => {
      vscode.window.showErrorMessage('VS Code Wallpaper: ' + error.message);
    });
  }));
  // Called after startup; the linked CSS is loaded by VS Code before activation.
  refreshAutomatic(context, true).catch(error => {
    vscode.window.showWarningMessage('VS Code Wallpaper: 自動壁紙を更新できませんでした: ' + error.message);
  });
}

function deactivate() { previewPanel = undefined; }
module.exports = { activate, deactivate };
