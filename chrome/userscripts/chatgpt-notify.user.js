// ==UserScript==
// @name         ChatGPT Response Complete Notification
// @namespace    local
// @version      1.1.0
// @description  ChatGPTの回答完了をHammerspoonへ通知する
// @match        https://chatgpt.com/*
// @grant        GM_xmlhttpRequest
// @connect      127.0.0.1
// @run-at       document-idle
// ==/UserScript==

(() => {
  'use strict';

  const STOP_SELECTOR = '[data-testid="stop-button"]';
  const NOTIFY_URL = 'http://127.0.0.1:17365/chatgpt-done';
  const PREVIEW_LENGTH = 50;
  const COMPLETION_DELAY_MS = 500;

  let generating = hasStopButton();
  let completionTimer = null;

  function hasStopButton() {
    return document.querySelector(STOP_SELECTOR) !== null;
  }

  function getLastUserMessage() {
    return (
      [...document.querySelectorAll('[data-message-author-role="user"]')]
        .at(-1)
        ?.innerText
        ?.replace(/\s+/g, ' ')
        ?.trim() ?? ''
    );
  }

  function truncate(text) {
    if (text.length <= PREVIEW_LENGTH) {
      return text;
    }

    return `${text.slice(0, PREVIEW_LENGTH)}…`;
  }

  function notifyCompletion() {
    GM_xmlhttpRequest({
      method: 'POST',
      url: NOTIFY_URL,
      headers: {
        'Content-Type': 'application/json',
      },
      data: JSON.stringify({
        title: document.title.trim(),
        preview: truncate(getLastUserMessage()),
      }),
    });
  }

  function checkGenerationState() {
    const currentlyGenerating = hasStopButton();

    if (currentlyGenerating) {
      generating = true;
      clearTimeout(completionTimer);
      return;
    }

    if (!generating) {
      return;
    }

    clearTimeout(completionTimer);
    completionTimer = setTimeout(() => {
      if (hasStopButton()) {
        return;
      }

      generating = false;
      notifyCompletion();
    }, COMPLETION_DELAY_MS);
  }

  new MutationObserver(checkGenerationState).observe(document.body, {
    childList: true,
    subtree: true,
  });
})();
