local M = {}
local mermaidSource = require("modules.mermaid_source")

local MMDC_PATH = "/opt/homebrew/bin/mmdc"
local PNG_SCALE = 2 -- Preview で拡大しても文字がにじみにくいよう、2 倍の解像度で描画する。
local THEME_CONFIG_PATH = hs.configdir .. "/modules/mermaid_theme.json"
local BACKGROUND_COLOR = "#0F172A"
local COPY_DELAY_SECONDS = 0.15
local COPY_TIMEOUT_SECONDS = 1

local function restorePasteboard(saved)
  hs.pasteboard.clearContents()

  if saved and next(saved) then
    hs.pasteboard.writeAllData(saved)
  end
end


-- PNG は Preview の「ウインドウに合わせる」で縦横とも全体表示できる。
-- 生成ファイルのウィンドウを確認してから操作し、ほかの書類は変更しない。
local function openPreview(imagePath)
  local task = hs.task.new("/usr/bin/open", function(exitCode, stdout, stderr)
    M.openTask = nil
    if exitCode ~= 0 then
      hs.printf("[Mermaid Preview] open failed (%d): %s %s", exitCode, stdout or "", stderr or "")
      hs.alert.show("画像をプレビューで開けませんでした")
      return
    end

    local filename = imagePath:match("[^/]+$")
    local function fitImage(attempts)
      local app = hs.application.get("com.apple.Preview")
      if app then
        for _, window in ipairs(app:allWindows()) do
          if (window:title() or ""):find(filename, 1, true) then
            window:focus()
            -- Preview の「ウインドウに合わせる」。PDF は幅優先になることがある。
            hs.eventtap.keyStroke({ "cmd" }, "9", 0, app)
            return
          end
        end
      end

      if attempts > 0 then
        hs.timer.doAfter(0.1, function()
          fitImage(attempts - 1)
        end)
      else
        hs.printf("[Mermaid Preview] window not found for: %s", filename)
      end
    end

    hs.timer.doAfter(0.2, function()
      fitImage(20)
    end)
  end, { "-a", "Preview", imagePath })

  if not task then
    hs.alert.show("プレビューを起動できませんでした")
    return
  end

  M.openTask = task
  if not task:start() then
    M.openTask = nil
    hs.alert.show("プレビューを起動できませんでした")
  end
end

local function runMmdc(inputPath, outputPath, finished, scale)
  local args = { "-i", inputPath, "-o", outputPath, "-c", THEME_CONFIG_PATH, "-b", BACKGROUND_COLOR }
  if scale then
    table.insert(args, "-s")
    table.insert(args, tostring(scale))
  end

  local task = hs.task.new(MMDC_PATH, function(exitCode, stdout, stderr)
    M.task = nil
    finished(exitCode == 0, stdout, stderr)
  end, args)

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
  text = mermaidSource.normalize(text)
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
  local pngPath = base .. ".png"

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
    os.remove(pngPath)
    hs.printf("[Mermaid Preview] %s conversion failed: %s %s", outputType, stdout or "", stderr or "")
    hs.alert.show("Mermaid の変換に失敗しました（Console を確認）")
  end

  -- SVG は残し、プレビューには背景付き PNG を直接渡す。
  runMmdc(inputPath, svgPath, function(svgOK, stdout, stderr)
    if not svgOK then
      fail("SVG", stdout, stderr)
      return
    end

    runMmdc(inputPath, pngPath, function(pngOK, pngStdout, pngStderr)
      if not pngOK then
        fail("PNG", pngStdout, pngStderr)
        return
      end

      os.remove(inputPath)
      openPreview(pngPath)
    end, PNG_SCALE)
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
