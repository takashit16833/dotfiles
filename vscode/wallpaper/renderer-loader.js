// Runs in the VS Code workbench renderer, not in the extension host.
// Only loads the stylesheet whose name matches this window's workspace ID.
(async () => {
  try {
    const configuration = await window.vscode.context.resolveConfiguration();
    const workspaceId = configuration.workspace?.id ?? 'empty';
    if (!/^[a-zA-Z0-9_-]{1,128}$/.test(workspaceId)) {
      throw new Error('Invalid workspace identifier');
    }
    const stylesheetUrl = new URL('./vscode-wallpaper-' + workspaceId + '.css', import.meta.url);
    let attempt = 0;

    const load = () => {
      const link = document.createElement('link');
      link.rel = 'stylesheet';
      link.href = stylesheetUrl.href + '?attempt=' + attempt;
      link.onerror = () => {
        link.remove();
        attempt += 1;
        // Extension activation writes the workspace stylesheet after startup.
        setTimeout(load, Math.min(5000, 400 * (2 ** Math.min(attempt, 4))));
      };
      document.head.append(link);
    };
    load();
  } catch (error) {
    console.warn('VS Code Wallpaper: workspace stylesheet loader failed', error);
  }
})();
