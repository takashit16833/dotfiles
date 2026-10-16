local M = {}

local MMDC_PATH = "/opt/homebrew/bin/mmdc"
local COPY_DELAY_SECONDS = 0.15
local COPY_TIMEOUT_SECONDS = 1

local function restorePasteboard(saved)
  hs.pasteboard.clearContents()

  if saved and next(saved) then
    hs.pasteboard.writeAllData(saved)
  end
end

local function normalizeMermaid(text)
  if not text then
    return nil
  end

  text = text:gsub("\r\n", "\n"):match("^%s*(.-)%s*$")
  return text:match("^```mermaid[^\n]*\n(.-)\n```$") or text
end

-- 標準アプリのウィンドウなら Cmd+W と既存の Hyper ウィンドウ操作が使える。
local function openPreview(pdfPath)
  local task = hs.task.new("/usr/bin/open", function(exitCode, stdout, stderr)
    if exitCode ~= 0 then
      hs.printf("[Mermaid Preview] open failed (%d): %s %s", exitCode, stdout or "", stderr or "")
      hs.alert.show("PDF をプレビューで開けませんでした")
      return
    end

    -- 文書のウィンドウが開くのを待ってから前面へ移す。
    hs.timer.doAfter(0.2, function()
      local app = hs.application.get("com.apple.Preview")
      if app then
        app:activate()
      end
    end)
  end, { "-a", "Preview", pdfPath })

  if not task or not task:start() then
    hs.alert.show("プレビューを起動できませんでした")
  end
end

local function runMmdc(inputPath, outputPath, finished)
  local task = hs.task.new(MMDC_PATH, function(exitCode, stdout, stderr)
    M.task = nil
    finished(exitCode == 0, stdout, stderr)
  end, { "-i", inputPath, "-o", outputPath })

  if not task then
    finished(false, "", "Mermaid CLI を起動できませんでした")
    return
  end

  -- Hammerspoon からも Homebrew の node を見つけられるようにする。
  local env = task:environment()
  env.PATH = "/opt/homebrew/bin:" .. (env.PATH or "/usr/bin:/bin")
  task:setEnvironment(env)

  M.task = task
  if not task:start() then
    M.task = nil
    finished(false, "", "Mermaid CLI を起動できませんでした")
  end
end

local function renderMermaid(text)
  text = normalizeMermaid(text)
  if not text or text == "" then
    hs.alert.show("Mermaid コードを選択してください")
    return
  end

  if M.task then
    hs.alert.show("Mermaid の変換中です")
    return
  end

  -- 出力名を毎回変え、プレビューが開いたままでも前の文書と衝突させない。
  local base = os.tmpname()
  os.remove(base)
  local inputPath = base .. ".mmd"
  local svgPath = base .. ".svg"
  local pdfPath = base .. ".pdf"

  local file = io.open(inputPath, "w")
  if not file then
    hs.alert.show("Mermaid の一時ファイルを作成できませんでした")
    return
  end
  file:write(text)
  file:close()

  local function fail(outputType, stdout, stderr)
    os.remove(inputPath)
    os.remove(svgPath)
    os.remove(pdfPath)
    hs.printf("[Mermaid Preview] %s conversion failed: %s %s", outputType, stdout or "", stderr or "")
    hs.alert.show("Mermaid の変換に失敗しました（Console を確認）")
  end

  -- SVG は元の用途どおり残し、macOS のプレビューで開く PDF も生成する。
  runMmdc(inputPath, svgPath, function(svgOK, stdout, stderr)
    if not svgOK then
      fail("SVG", stdout, stderr)
      return
    end

    runMmdc(inputPath, pdfPath, function(pdfOK, pdfStdout, pdfStderr)
      if not pdfOK then
        fail("PDF", pdfStdout, pdfStderr)
        return
      end

      os.remove(inputPath)
      openPreview(pdfPath)
    end)
  end)
end

local function previewSelection()
  local savedPasteboard = hs.pasteboard.readAllData()

  hs.timer.doAfter(COPY_DELAY_SECONDS, function()
    -- 前にコピーした文字列を誤って描画しないよう、コピー前に空にする。
    hs.pasteboard.clearContents()
    local deadline = hs.timer.secondsSinceEpoch() + COPY_TIMEOUT_SECONDS

    local function waitForCopy()
      local selectedText = hs.pasteboard.readString()

      if selectedText and selectedText ~= "" then
        restorePasteboard(savedPasteboard)
        renderMermaid(selectedText)
      elseif hs.timer.secondsSinceEpoch() >= deadline then
        restorePasteboard(savedPasteboard)
        hs.alert.show("Mermaid コードを選択してください")
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

  -- Hyper = Ctrl + Cmd + Option（init.lua の既存設定と同じ）。
  M.hotkey = hs.hotkey.bind({ "ctrl", "cmd", "alt" }, "l", previewSelection)
  return M
end

return M
