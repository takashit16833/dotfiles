// Runs in the VS Code workbench renderer, not in the extension host.
// Each window loads and refreshes only its own workspace stylesheet.
(async () => {
  try {
    const configuration = await window.vscode.context.resolveConfiguration();
    const workspaceId = configuration.workspace?.id ?? 'empty';
    if (!/^[a-zA-Z0-9_-]{1,128}$/.test(workspaceId)) {
      throw new Error('Invalid workspace identifier');
    }
    const stylesheetUrl = new URL('./vscode-wallpaper-' + workspaceId + '.css', import.meta.url);
    const intervalMs = 2000;
    const header = '/* VS Code Wallpaper: managed stylesheet;';
    let activeLink;
    let appliedCss;
    let pendingCss;
    let checking = false;
    let requestNumber = 0;

    // Preserve startup loading even before the extension creates the CSS file.
    const initial = document.createElement('link');
    initial.rel = 'stylesheet';
    initial.href = stylesheetUrl.href;
    initial.onload = () => {
      if (activeLink && activeLink !== initial) initial.remove();
      else activeLink = initial;
    };
    initial.onerror = () => initial.remove();
    document.head.append(initial);

    const check = async () => {
      if (checking) return;
      checking = true;
      try {
        // Bypass the file protocol's cache when checking for changes.
        const href = stylesheetUrl.href + '?revision=' + (++requestNumber);
        const response = await fetch(href, { cache: 'no-store' });
        if (!response.ok) return; // The extension may not have written it yet.
        const css = await response.text();
        if (!css.startsWith(header) || css === appliedCss || css === pendingCss) return;
        pendingCss = css;
        const next = document.createElement('link');
        next.rel = 'stylesheet';
        next.href = href;
        next.onload = () => {
          activeLink?.remove();
          initial.remove();
          activeLink = next;
          appliedCss = css;
          pendingCss = undefined;
        };
        next.onerror = () => {
          next.remove();
          pendingCss = undefined;
        };
        // Keep the old stylesheet active until the replacement is loaded.
        document.head.append(next);
      } catch {
        // Missing/unavailable local CSS: keep the last working style and retry.
      } finally {
        checking = false;
      }
    };
    await check();
    setInterval(check, intervalMs);
  } catch (error) {
    console.warn('VS Code Wallpaper: workspace stylesheet loader failed', error);
  }
})();
