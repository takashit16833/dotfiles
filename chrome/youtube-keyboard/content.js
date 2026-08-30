(() => {
  const LOG_PREFIX = "[yt-keyboard]";
  const log = (...args) => console.log(LOG_PREFIX, ...args);

  log("content script loaded", {
    href: window.location.href,
    readyState: document.readyState
  });

  const SELECTED_CLASS = "yt-keyboard-selected";
  const MODE_CLASS = "yt-keyboard-mode";

  const videoSelectors = [
    'ytd-rich-item-renderer a#thumbnail[href^="/watch"]',
    'ytd-video-renderer a#thumbnail[href^="/watch"]',
    'ytd-grid-video-renderer a#thumbnail[href^="/watch"]',
    'ytd-compact-video-renderer a#thumbnail[href^="/watch"]',
    'ytd-playlist-video-renderer a#thumbnail[href^="/watch"]'
  ];

  const cardSelector = [
    "ytd-rich-item-renderer",
    "ytd-video-renderer",
    "ytd-grid-video-renderer",
    "ytd-compact-video-renderer",
    "ytd-playlist-video-renderer"
  ].join(",");

  let active = false;
  let selected = null;

  const isEditable = (target) => {
    if (!(target instanceof Element)) return false;

    return Boolean(
      target.closest('input, textarea, select, [contenteditable="true"], [role="textbox"]')
    );
  };

  const hasArea = (rect) => rect.width > 1 && rect.height > 1;

  // YouTube frequently changes which wrapper owns layout. Some wrappers use
  // display: contents, so their own bounding box is zero even though their
  // descendants are visibly rendered. Resolve geometry from several stable
  // fallbacks instead of treating a zero-sized wrapper as invisible.
  const rectOf = (element) => {
    const card = element.closest(cardSelector);
    const probes = [
      element,
      element.querySelector("img"),
      element.querySelector("yt-image"),
      card,
      card?.querySelector("a#thumbnail"),
      card?.querySelector("img"),
      card?.querySelector("yt-image")
    ].filter(Boolean);

    for (const probe of probes) {
      const rect = probe.getBoundingClientRect();
      if (hasArea(rect)) return rect;
    }

    // Range can recover the rendered bounds of descendants when the host
    // element itself has no box (for example with display: contents).
    try {
      const range = document.createRange();
      range.selectNodeContents(card ?? element);
      const rect = range.getBoundingClientRect();
      if (hasArea(rect)) return rect;
    } catch {
      // Ignore and report no geometry below.
    }

    return null;
  };

  const getCandidates = () => {
    const seen = new Set();
    const candidates = [];

    for (const selector of videoSelectors) {
      for (const element of document.querySelectorAll(selector)) {
        const key = element.href;
        if (!key || seen.has(key) || !element.isConnected) continue;
        seen.add(key);
        candidates.push(element);
      }
    }

    const withGeometry = candidates.filter((element) => rectOf(element) !== null).length;
    log("candidates", candidates.length, { withGeometry });
    return candidates;
  };

  const centerOf = (element) => {
    const rect = rectOf(element);
    if (!rect) return null;

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
    if (!element) {
      log("select skipped: no candidate");
      return;
    }

    selected?.classList.remove(SELECTED_CLASS);
    selected = element;
    selected.classList.add(SELECTED_CLASS);
    log("selected", selected.href);

    const card = selected.closest(cardSelector);
    (card ?? selected).scrollIntoView({
      block: "center",
      inline: "center",
      behavior: "smooth"
    });
  };

  const initialCandidate = () => {
    const candidates = getCandidates();
    const viewportCenter = {
      x: window.innerWidth / 2,
      y: window.innerHeight / 2
    };

    const positioned = candidates
      .map((element) => ({ element, rect: rectOf(element) }))
      .filter(({ rect }) => rect !== null);

    const inViewport = positioned.filter(({ rect }) =>
      rect.bottom > 0 &&
      rect.top < window.innerHeight &&
      rect.right > 0 &&
      rect.left < window.innerWidth
    );

    const pool = inViewport.length > 0 ? inViewport : positioned;

    return pool.reduce((best, { element, rect }) => {
      const x = rect.left + rect.width / 2;
      const y = rect.top + rect.height / 2;
      const distance = Math.hypot(x - viewportCenter.x, y - viewportCenter.y);

      if (!best || distance < best.distance) {
        return { element, distance };
      }

      return best;
    }, null)?.element ?? candidates[0] ?? null;
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
    log("move", direction);

    if (!selected || !document.contains(selected)) {
      select(initialCandidate());
      return;
    }

    const origin = centerOf(selected);
    if (!origin) {
      select(initialCandidate());
      return;
    }

    const next = getCandidates().reduce((best, element) => {
      if (element === selected) return best;

      const center = centerOf(element);
      if (!center) return best;

      const score = directionalScore(origin, center, direction);
      if (!Number.isFinite(score)) return best;
      if (!best || score < best.score) return { element, score };
      return best;
    }, null)?.element;

    if (next) select(next);
  };

  const activate = () => {
    active = true;
    document.documentElement.classList.add(MODE_CLASS);
    log("activated");
    select(initialCandidate());
  };

  const deactivate = () => {
    active = false;
    document.documentElement.classList.remove(MODE_CLASS);
    clearSelection();
    log("deactivated");
  };

  document.addEventListener(
    "keydown",
    (event) => {
      const togglePressed =
        event.ctrlKey &&
        event.shiftKey &&
        !event.metaKey &&
        !event.altKey &&
        event.code === "KeyY";

      if (togglePressed) {
        log("toggle key received", {
          key: event.key,
          code: event.code,
          ctrlKey: event.ctrlKey,
          shiftKey: event.shiftKey
        });
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
        log("open", selected.href);
        selected.click();
        deactivate();
      }
    },
    true
  );

  document.addEventListener("yt-navigate-start", () => {
    log("yt-navigate-start");
    deactivate();
  });
})();
