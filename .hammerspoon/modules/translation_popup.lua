local M = {}

local COPY_DELAY_SECONDS = 0.15
local COPY_TIMEOUT_SECONDS = 1
local CHROME_BUNDLE_ID = "com.google.Chrome"
local GOOGLE_TRANSLATE_URL = "https://translate.google.com/?sl=auto&tl=ja&text=%s&op=translate"

local function trim(text)
  return text and text:match("^%s*(.-)%s*$") or nil
end

local function restorePasteboard(saved)
  hs.pasteboard.clearContents()

  if saved and next(saved) then
    hs.pasteboard.writeAllData(saved)
  end
end

local function openGoogleTranslate(text)
  local url = string.format(GOOGLE_TRANSLATE_URL, hs.http.encodeForQuery(text))

  if not hs.urlevent.openURLWithBundle(url, CHROME_BUNDLE_ID) then
    hs.alert.show("Google 翻訳を Chrome で開けませんでした")
  end
end

local function translateSelection()
  local savedPasteboard = hs.pasteboard.readAllData()

  hs.timer.doAfter(COPY_DELAY_SECONDS, function()
    -- 同じ文字列をコピーする場合にも対応する。
    hs.pasteboard.clearContents()

    local deadline = hs.timer.secondsSinceEpoch() + COPY_TIMEOUT_SECONDS

    local function waitForCopy()
      local selectedText = trim(hs.pasteboard.readString())

      if selectedText and selectedText ~= "" then
        restorePasteboard(savedPasteboard)
        openGoogleTranslate(selectedText)
      elseif hs.timer.secondsSinceEpoch() >= deadline then
        restorePasteboard(savedPasteboard)
        hs.alert.show("翻訳するテキストを選択してください")
      else
        hs.timer.doAfter(0.05, waitForCopy)
      end
    end

    hs.eventtap.keyStroke({ "cmd" }, "c", 0)
    hs.timer.doAfter(0.05, waitForCopy)
  end)
end

function M.start()
  if M.hotkey then
    M.hotkey:delete()
  end

  M.hotkey = hs.hotkey.bind({ "ctrl", "cmd", "alt" }, "q", translateSelection)
  return M
end

return M
