/* Determine section depth without changing Markdown HTML structure.
 * VS Code emits vscode.markdown.updateContent after refreshing the preview. */
(() => {
  "use strict";

  function updateOutline() {
    const root = document.querySelector(".markdown-body");
    if (!root) return false;

    let currentLevel = 0;

    for (const element of root.children) {
      const heading = /^H([1-6])$/.exec(element.tagName);
      if (heading) {
        currentLevel = Number(heading[1]);
      }

      // VS Code's last empty .code-line is a source-position marker.
      // Don't indent it or inserted preview styles.
      if (element.matches("link, style, script") ||
          (element.classList.contains("code-line") && !element.textContent.trim())) {
        continue;
      }

      const isHeading = Boolean(heading);
      const isContent = !isHeading && currentLevel !== 0;
      element.classList.toggle("rhb-outline-heading", isHeading);
      element.classList.toggle("rhb-outline-content", isContent);

      if (isHeading || isContent) {
        const depth = String(Math.max(0, currentLevel - 1));
        if (element.style.getPropertyValue("--rhb-outline-depth") !== depth) {
          element.style.setProperty("--rhb-outline-depth", depth);
        }
      }
    }
    return true;
  }

  // VS Code appends the initial .markdown-body after the preview page loads.
  // A contributed script may run before that insertion happens.
  function initializeOutline() {
    if (updateOutline()) return;
    const observer = new MutationObserver(() => {
      if (updateOutline()) observer.disconnect();
    });
    observer.observe(document.body, { childList: true });
  }

  window.addEventListener("vscode.markdown.updateContent", updateOutline);

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", initializeOutline, { once: true });
  } else {
    initializeOutline();
  }
})();
