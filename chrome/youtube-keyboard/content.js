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
    "ytd-playlist-renderer",
    "ytd-grid-playlist-renderer",
    "ytd-radio-renderer",
    "ytd-compact-radio-renderer",
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
      card,
      card?.querySelector("img"),
      card?.querySelector("yt-image"),
      element,
      element.querySelector("img")
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

  const mediaKind = (element) => {
    try {
      const url = new URL(element.href, window.location.href);
      if (url.pathname === "/watch" && url.searchParams.get("v")) return "watch";
      if (url.pathname.startsWith("/shorts/") && url.pathname.split("/")[2]) return "shorts";
      return null;
    } catch {
      return null;
    }
  };

  const linkScore = (element) => {
    const rect = element.getBoundingClientRect();
    return hasArea(rect) ? rect.width * rect.height : 0;
  };

  const getCandidates = () => {
    const links = Array.from(document.querySelectorAll(MEDIA_LINK_SELECTOR));
    const byCard = new Map();

    let rejectedNoMediaId = 0;
    let rejectedDisconnected = 0;

    for (const element of links) {
      if (!mediaKind(element)) {
        rejectedNoMediaId++;
        continue;
      }
      if (!element.isConnected) {
        rejectedDisconnected++;
        continue;
      }

      const card = closestCard(element);
      const existing = byCard.get(card);

      if (!existing || linkScore(element) > linkScore(existing)) {
        byCard.set(card, element);
      }
    }

    const candidates = Array.from(byCard.values());
    const withGeometry = candidates.filter((element) => rectOf(element) !== null).length;
    const shorts = candidates.filter((element) => mediaKind(element) === "shorts").length;
    const mixes = candidates.filter((element) => {
      try {
        const url = new URL(element.href, window.location.href);
        return url.pathname === "/watch" && url.searchParams.has("list");
      } catch {
        return false;
      }
    }).length;

    log("candidates", candidates.length, {
      rawMediaLinks: links.length,
      cards: byCard.size,
      shorts,
      mixes,
      withGeometry,
      rejectedNoMediaId,
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

  const centerOfRect = (rect) => ({
    x: rect.left + rect.width / 2,
    y: rect.top + rect.height / 2
  });

  const verticalOverlap = (a, b) =>
    Math.max(0, Math.min(a.bottom, b.bottom) - Math.max(a.top, b.top));

  const sameVisualRow = (a, b) => {
    const overlap = verticalOverlap(a, b);
    const required = Math.min(a.height, b.height) * 0.35;
    return overlap >= required;
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
      const center = centerOfRect(rect);
      const distance = Math.hypot(
        center.x - viewportCenter.x,
        center.y - viewportCenter.y
      );
      return !best || distance < best.distance ? { element, distance } : best;
    }, null)?.element ?? candidates[0] ?? null;
  };

  const verticalScore = (originRect, candidateRect, direction) => {
    const origin = centerOfRect(originRect);
    const candidate = centerOfRect(candidateRect);
    const dx = candidate.x - origin.x;

    if (direction === "ArrowUp") {
      if (candidate.y >= originRect.top - 1) return Infinity;
      return (originRect.top - candidate.y) * 10000 + Math.abs(dx);
    }

    if (direction === "ArrowDown") {
      if (candidate.y <= originRect.bottom + 1) return Infinity;
      return (candidate.y - originRect.bottom) * 10000 + Math.abs(dx);
    }

    return Infinity;
  };

  const horizontalScore = (originRect, candidateRect, direction) => {
    if (!sameVisualRow(originRect, candidateRect)) return Infinity;

    const origin = centerOfRect(originRect);
    const candidate = centerOfRect(candidateRect);
    const dy = Math.abs(candidate.y - origin.y);

    if (direction === "ArrowLeft") {
      if (candidate.x >= origin.x - 1) return Infinity;
      return (origin.x - candidate.x) * 10000 + dy;
    }

    if (direction === "ArrowRight") {
      if (candidate.x <= origin.x + 1) return Infinity;
      return (candidate.x - origin.x) * 10000 + dy;
    }

    return Infinity;
  };

  const move = (direction) => {
    if (!selected || !document.contains(selected)) {
      select(initialCandidateFrom(getCandidates()));
      return;
    }

    const originRect = rectOf(selected);
    if (!originRect) {
      select(initialCandidateFrom(getCandidates()));
      return;
    }

    const horizontal = direction === "ArrowLeft" || direction === "ArrowRight";

    const next = getCandidates().reduce((best, element) => {
      if (closestCard(element) === closestCard(selected)) return best;

      const candidateRect = rectOf(element);
      if (!candidateRect) return best;

      const score = horizontal
        ? horizontalScore(originRect, candidateRect, direction)
        : verticalScore(originRect, candidateRect, direction);

      if (!Number.isFinite(score)) return best;
      return !best || score < best.score ? { element, score } : best;
    }, null)?.element;

    if (next) {
      select(next);
    } else if (horizontal) {
      log("horizontal move skipped: no stable same-row candidate", direction);
    }
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
