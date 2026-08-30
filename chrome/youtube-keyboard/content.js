(() => {
  const SELECTED_CLASS = "yt-keyboard-selected";
  const MODE_CLASS = "yt-keyboard-mode";

  const videoSelectors = [
    'ytd-rich-item-renderer a#thumbnail[href^="/watch"]',
    'ytd-video-renderer a#thumbnail[href^="/watch"]',
    'ytd-grid-video-renderer a#thumbnail[href^="/watch"]',
    'ytd-compact-video-renderer a#thumbnail[href^="/watch"]',
    'ytd-playlist-video-renderer a#thumbnail[href^="/watch"]'
  ];

  let active = false;
  let selected = null;

  const isEditable = (target) => {
    if (!(target instanceof Element)) return false;

    return Boolean(
      target.closest('input, textarea, select, [contenteditable="true"], [role="textbox"]')
    );
  };

  const isVisible = (element) => {
    const rect = element.getBoundingClientRect();
    const style = window.getComputedStyle(element);

    return (
      rect.width > 0 &&
      rect.height > 0 &&
      style.visibility !== "hidden" &&
      style.display !== "none"
    );
  };

  const getCandidates = () => {
    const seen = new Set();

    return videoSelectors
      .flatMap((selector) => Array.from(document.querySelectorAll(selector)))
      .filter((element) => {
        if (seen.has(element) || !isVisible(element)) return false;
        seen.add(element);
        return true;
      });
  };

  const centerOf = (element) => {
    const rect = element.getBoundingClientRect();
    return {
      x: rect.left + rect.width / 2,
      y: rect.top + rect.height / 2
    };
  };

  const clearSelection = () => {
    selected?.classList.remove(SELECTED_CLASS);
    selected = null;
  };

  const select = (element) => {
    if (!element) return;

    selected?.classList.remove(SELECTED_CLASS);
    selected = element;
    selected.classList.add(SELECTED_CLASS);
    selected.scrollIntoView({ block: "center", inline: "center", behavior: "smooth" });
  };

  const initialCandidate = () => {
    const candidates = getCandidates();
    const viewportCenter = {
      x: window.innerWidth / 2,
      y: window.innerHeight / 2
    };

    const inViewport = candidates.filter((element) => {
      const rect = element.getBoundingClientRect();
      return rect.bottom > 0 && rect.top < window.innerHeight;
    });

    const pool = inViewport.length > 0 ? inViewport : candidates;

    return pool.reduce((best, element) => {
      const center = centerOf(element);
      const distance = Math.hypot(
        center.x - viewportCenter.x,
        center.y - viewportCenter.y
      );

      if (!best || distance < best.distance) {
        return { element, distance };
      }

      return best;
    }, null)?.element;
  };

  const directionalScore = (origin, candidate, direction) => {
    const dx = candidate.x - origin.x;
    const dy = candidate.y - origin.y;

    let primary;
    let secondary;

    switch (direction) {
      case "ArrowLeft":
        if (dx >= -1) return Infinity;
        primary = -dx;
        secondary = Math.abs(dy);
        break;
      case "ArrowRight":
        if (dx <= 1) return Infinity;
        primary = dx;
        secondary = Math.abs(dy);
        break;
      case "ArrowUp":
        if (dy >= -1) return Infinity;
        primary = -dy;
        secondary = Math.abs(dx);
        break;
      case "ArrowDown":
        if (dy <= 1) return Infinity;
        primary = dy;
        secondary = Math.abs(dx);
        break;
      default:
        return Infinity;
    }

    return primary + secondary * 2;
  };

  const move = (direction) => {
    if (!selected || !document.contains(selected)) {
      select(initialCandidate());
      return;
    }

    const origin = centerOf(selected);
    const candidates = getCandidates().filter((element) => element !== selected);

    const next = candidates.reduce((best, element) => {
      const score = directionalScore(origin, centerOf(element), direction);

      if (!Number.isFinite(score)) return best;
      if (!best || score < best.score) return { element, score };
      return best;
    }, null)?.element;

    if (next) select(next);
  };

  const activate = () => {
    active = true;
    document.documentElement.classList.add(MODE_CLASS);
    select(initialCandidate());
  };

  const deactivate = () => {
    active = false;
    document.documentElement.classList.remove(MODE_CLASS);
    clearSelection();
  };

  document.addEventListener(
    "keydown",
    (event) => {
      const togglePressed =
        event.ctrlKey && event.shiftKey && !event.metaKey && !event.altKey && event.code === "KeyY";

      if (togglePressed) {
        event.preventDefault();
        event.stopPropagation();
        active ? deactivate() : activate();
        return;
      }

      if (!active || isEditable(event.target)) return;

      if (event.key === "Escape") {
        event.preventDefault();
        event.stopPropagation();
        deactivate();
        return;
      }

      if (["ArrowLeft", "ArrowRight", "ArrowUp", "ArrowDown"].includes(event.key)) {
        event.preventDefault();
        event.stopPropagation();
        move(event.key);
        return;
      }

      if (event.key === "Enter" && selected) {
        event.preventDefault();
        event.stopPropagation();
        selected.click();
        deactivate();
      }
    },
    true
  );

  document.addEventListener("yt-navigate-start", deactivate);
})();
