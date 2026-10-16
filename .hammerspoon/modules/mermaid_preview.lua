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
  return text:match("^\`\`\`mermaid[^\n]*\n(.-)\n\`\`\`$") or text
end

local function showPreview(svgPath)
  if not M.preview then
    local screen = hs.screen.mainScreen():frame()
    local width = math.min(900, screen.w)
    local height = math.min(640, screen.h)

    M.preview = hs.webview.new({
      x = screen.x + (screen.w - width) / 2,
      y = screen.y + (screen.h - height) / 2,
      w = width,
      h = height,
    })
      :windowStyle({ "titled", "closable", "resizable", "miniaturizable" })
      :closeOnEscape(true)
      :windowTitle("Mermaid Preview")
  end

  -- 一時ファイル名は生成ごとに異なるので、前の SVG が再表示されることはない。
  M.preview:url("file://" .. svgPath)
  M.preview:show()

  local window = M.preview:hswindow()
  if window then
    window:focus()
  end

  if M.outputPath then
    os.remove(M.outputPath)
  end
  M.outputPath = svgPath
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

  -- 入出力とも一意の一時ファイルにし、連続実行でも描画結果を混同しない。
  local base = os.tmpname()
  os.remove(base)
  local inputPath = base .. ".mmd"
  local outputPath = base .. ".svg"

  local file = io.open(inputPath, "w")
  if not file then
    hs.alert.show("Mermaid の一時ファイルを作成できませんでした")
    return
  end
  file:write(text)
  file:close()

  local task = hs.task.new(MMDC_PATH, function(exitCode, stdout, stderr)
    M.task = nil
    os.remove(inputPath)

    if exitCode ~= 0 then
      os.remove(outputPath)
      hs.printf("[Mermaid Preview] mmdc failed (%d): %s %s", exitCode, stdout or "", stderr or "")
      hs.alert.show("Mermaid の変換に失敗しました（Console を確認）")
      return
    end

    showPreview(outputPath)
  end, { "-i", inputPath, "-o", outputPath })

  if not task then
    os.remove(inputPath)
    hs.alert.show("Mermaid CLI を起動できませんでした")
    return
  end

  -- GUI アプリからも Homebrew の node を見つけられるようにする。
  local env = task:environment()
  env.PATH = "/opt/homebrew/bin:" .. (env.PATH or "/usr/bin:/bin")
  task:setEnvironment(env)

  M.task = task
  if not task:start() then
    M.task = nil
    os.remove(inputPath)
    hs.alert.show("Mermaid CLI を起動できませんでした")
  end
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
