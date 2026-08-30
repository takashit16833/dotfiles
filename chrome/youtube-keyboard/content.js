(() => {
  const LOG_PREFIX = "[yt-keyboard]";
  const log = (...args) => console.log(LOG_PREFIX, ...args);

  log("content script loaded", {
    href: window.location.href,
    readyState: document.readyState
  });

  const SELECTED_CLASS = "yt-keyboard-selected";
  const MODE_CLASS = "yt-keyboard-mode";
  const CANDIDATE_WAIT_MS = 3000;
  const CANDIDATE_POLL_MS = 100;

  // Prefer semantic media links over YouTube's renderer tag names. Renderer
  // names and nesting change frequently, while watch/shorts URLs are the
  // stable contract we actually need.
  const MEDIA_LINK_SELECTOR = [
    'a[href^="/watch"]',
    'a[href^="https://www.youtube.com/watch"]',
    'a[href^="/shorts/"]',
    'a[href^="https://www.youtube.com/shorts/"]'
  ].join(",");

  const cardSelectors = [
    "ytd-rich-item-renderer",
    "ytd-video-renderer",
    "ytd-grid-video-renderer",
    "ytd-compact-video-renderer",
    "ytd-playlist-video-renderer",
    "yt-lockup-view-model",
    "ytd-rich-grid-media",
    "ytd-rich-grid-slim-media",
    "ytd-reel-item-renderer",
    "ytm-shorts-lockup-view-model",
    "ytm-shorts-lockup-view-model-v2"
  ];

  let active = false;
  let selected = null;
  let activationGeneration = 0;

  const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

  const isEditable = (target) => {
    if (!(target instanceof Element)) return false;
    return Boolean(
      target.closest('input, textarea, select, [contenteditable="true"], [role="textbox"]')
    );
  };

  const hasArea = (rect) => rect.width > 1 && rect.height > 1;

  const closestCard = (element) => {
    for (const selector of cardSelectors) {
      const card = element.closest(selector);
      if (card) return card;
    }
    return element.parentElement ?? element;
  };

  const rectOf = (element) => {
    const card = closestCard(element);
    const probes = [
      element,
      element.querySelector("img"),
      card,
      card?.querySelector("img"),
      card?.querySelector("yt-image")
    ].filter(Boolean);

    for (const probe of probes) {
      const rect = probe.getBoundingClientRect();
      if (hasArea(rect)) return rect;
    }

    try {
      const range = document.createRange();
      range.selectNodeContents(card ?? element);
      const rect = range.getBoundingClientRect();
      if (hasArea(rect)) return rect;
    } catch {
      // No usable geometry.
    }

    return null;
  };

  const mediaKey = (element) => {
    try {
      const url = new URL(element.href, window.location.href);

      if (url.pathname === "/watch") {
        const videoId = url.searchParams.get("v");
        return videoId ? `watch:${videoId}` : null;
      }

      if (url.pathname.startsWith("/shorts/")) {
        const shortId = url.pathname.split("/")[2];
        return shortId ? `shorts:${shortId}` : null;
      }

      return null;
    } catch {
      return null;
    }
  };

  const getCandidates = () => {
    const links = Array.from(document.querySelectorAll(MEDIA_LINK_SELECTOR));
    const seen = new Set();
    const candidates = [];

    let rejectedNoMediaId = 0;
    let rejectedDuplicate = 0;
    let rejectedDisconnected = 0;

    for (const element of links) {
      const key = mediaKey(element);
      if (!key) {
        rejectedNoMediaId++;
        continue;
      }
      if (seen.has(key)) {
        rejectedDuplicate++;
        continue;
      }
      if (!element.isConnected) {
        rejectedDisconnected++;
        continue;
      }

      seen.add(key);
      candidates.push(element);
    }

    const withGeometry = candidates.filter((element) => rectOf(element) !== null).length;
    const shorts = candidates.filter((element) => mediaKey(element)?.startsWith("shorts:")).length;
    log("candidates", candidates.length, {
      rawMediaLinks: links.length,
      shorts,
      withGeometry,
      rejectedNoMediaId,
      rejectedDuplicate,
      rejectedDisconnected,
      firstHref: links[0]?.getAttribute("href") ?? null
    });

    return candidates;
  };

  const waitForCandidates = async (generation) => {
    const deadline = Date.now() + CANDIDATE_WAIT_MS;

    while (active && generation === activationGeneration) {
      const candidates = getCandidates();
      if (candidates.length > 0) return candidates;
      if (Date.now() >= deadline) break;
      await sleep(CANDIDATE_POLL_MS);
    }

    return [];
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
    if (!element) return;

    selected?.classList.remove(SELECTED_CLASS);
    selected = element;
    selected.classList.add(SELECTED_CLASS);
    log("selected", selected.href);

    closestCard(selected).scrollIntoView({
      block: "center",
      inline: "center",
      behavior: "smooth"
    });
  };

  const initialCandidateFrom = (candidates) => {
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
      return !best || distance < best.distance ? { element, distance } : best;
    }, null)?.element ?? candidates[0] ?? null;
  };

  const directionalScore = (origin, candidate, direction) => {
    const dx = candidate.x - origin.x;
    const dy = candidate.y - origin.y;

    switch (direction) {
      case "ArrowLeft":
        return dx < -1 ? -dx + Math.abs(dy) * 2 : Infinity;
      case "ArrowRight":
        return dx > 1 ? dx + Math.abs(dy) * 2 : Infinity;
      case "ArrowUp":
        return dy < -1 ? -dy + Math.abs(dx) * 2 : Infinity;
      case "ArrowDown":
        return dy > 1 ? dy + Math.abs(dx) * 2 : Infinity;
      default:
        return Infinity;
    }
  };

  const move = (direction) => {
    if (!selected || !document.contains(selected)) {
      select(initialCandidateFrom(getCandidates()));
      return;
    }

    const origin = centerOf(selected);
    if (!origin) {
      select(initialCandidateFrom(getCandidates()));
      return;
    }

    const next = getCandidates().reduce((best, element) => {
      if (element === selected) return best;
      const center = centerOf(element);
      if (!center) return best;
      const score = directionalScore(origin, center, direction);
      if (!Number.isFinite(score)) return best;
      return !best || score < best.score ? { element, score } : best;
    }, null)?.element;

    if (next) select(next);
  };

  const activate = async () => {
    active = true;
    const generation = ++activationGeneration;
    document.documentElement.classList.add(MODE_CLASS);
    log("activated; waiting for candidates");

    const candidates = await waitForCandidates(generation);
    if (!active || generation !== activationGeneration) return;

    if (candidates.length === 0) {
      log("activation timed out: no candidates");
      return;
    }

    select(initialCandidateFrom(candidates));
  };

  const deactivate = () => {
    active = false;
    activationGeneration++;
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
        event.preventDefault();
        event.stopPropagation();
        active ? deactivate() : void activate();
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

  document.addEventListener("yt-navigate-start", deactivate);
})();
