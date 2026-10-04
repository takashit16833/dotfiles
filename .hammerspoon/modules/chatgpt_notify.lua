local M = {}

local SERVER_PORT = 17365
local ALERT_DURATION_SECONDS = 3

local function decodePayload(body)
  if not body or body == "" then
    return {}
  end

  local ok, payload = pcall(hs.json.decode, body)
  if ok and type(payload) == "table" then
    return payload
  end

  return {}
end

local function showCompletionAlert(payload)
  local threadTitle = payload.title or "ChatGPT"
  local preview = payload.preview or ""
  local message = "ChatGPT 回答完了\n\n" .. threadTitle

  if preview ~= "" then
    message = message .. "\n" .. preview
  end

  hs.alert.show(message, ALERT_DURATION_SECONDS)
  hs.sound.getByName("Glass"):play()
end

local function isBraveFocused(braveBundleID)
  local frontmostApp = hs.application.frontmostApplication()
  return frontmostApp and frontmostApp:bundleID() == braveBundleID
end

function M.start(options)
  local braveBundleID = options.braveBundleID

  M.server = hs.httpserver.new(false, false)
    :setInterface("localhost")
    :setPort(SERVER_PORT)
    :setCallback(function(method, path, _, body)
      if method ~= "POST" or path ~= "/chatgpt-done" then
        return "not found", 404, {
          ["Content-Type"] = "text/plain",
        }
      end

      local payload = decodePayload(body)
      local tabFocused = payload.tabFocused

      -- 古い userscript では tabFocused が送られないため、
      -- その場合だけ従来どおり Brave の前面判定へ戻す。
      if tabFocused == nil then
        tabFocused = isBraveFocused(braveBundleID)
      end

      if not tabFocused then
        showCompletionAlert(payload)
      end

      return "ok", 200, {
        ["Content-Type"] = "text/plain",
      }
    end)
    :start()
end

return M
