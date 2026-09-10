local M = {}

local COPY_DELAY_SECONDS = 0.15
local COPY_TIMEOUT_SECONDS = 1

local function trim(text)
  return text and text:match("^%s*(.-)%s*$") or nil
end

local function restorePasteboard(saved)
  hs.pasteboard.clearContents()

  if saved and next(saved) then
    hs.pasteboard.writeAllData(saved)
  end
end

local function helperPaths()
  local tmpDir = (os.getenv("TMPDIR") or "/tmp"):gsub("/+$", "")
  local appPath = tmpDir .. "/dotfiles-translation-popup/TranslationPopup.app"
  local executablePath = appPath .. "/Contents/MacOS/TranslationPopup"
  local buildScript = hs.configdir .. "/helpers/translation-popup/build.sh"

  return appPath, executablePath, buildScript
end

local function launchPopup(text)
  local appPath, executablePath, buildScript = helperPaths()

  local function openPopup()
    M.openTask = hs.task.new("/usr/bin/open", function()
      M.openTask = nil
    end, { "-n", appPath, "--args", text })

    M.openTask:start()
  end

  if hs.fs.attributes(executablePath, "mode") == "file" then
    openPopup()
    return
  end

  if M.buildTask then
    hs.alert.show("翻訳ヘルパーを準備中です")
    return
  end

  M.buildTask = hs.task.new("/bin/bash", function(exitCode, _, stderr)
    M.buildTask = nil

    if exitCode ~= 0 then
      hs.alert.show("翻訳ヘルパーのビルドに失敗しました")
      print("TranslationPopup build failed:", stderr)
      return
    end

    openPopup()
  end, { buildScript })

  M.buildTask:start()
end

local function translateSelection()
  local savedPasteboard = hs.pasteboard.readAllData()

  -- Option+T の修飾キーが離れてから Cmd+C を送る。
  -- ブラウザへ余計な修飾キーが混ざるのを避けるため、短時間だけ待つ。
  hs.timer.doAfter(COPY_DELAY_SECONDS, function()
    hs.pasteboard.callbackWhenChanged(COPY_TIMEOUT_SECONDS, function(changed)
      local selectedText = changed and trim(hs.pasteboard.getContents()) or nil

      restorePasteboard(savedPasteboard)

      if not selectedText or selectedText == "" then
        hs.alert.show("翻訳するテキストを選択してください")
        return
      end

      launchPopup(selectedText)
    end)

    hs.eventtap.keyStroke({ "cmd" }, "c", 0)
  end)
end

function M.start()
  M.hotkey = hs.hotkey.bind({ "alt" }, "t", translateSelection)
end

return M
