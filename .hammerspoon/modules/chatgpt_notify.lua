local M = {}

local SERVER_PORT = 17365
local ALERT_DURATION_SECONDS = 4

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

      local frontmostApp = hs.application.frontmostApplication()
      local braveIsFocused =
        frontmostApp
        and frontmostApp:bundleID() == braveBundleID

      if not braveIsFocused then
        showCompletionAlert(decodePayload(body))
      end

      return "ok", 200, {
        ["Content-Type"] = "text/plain",
      }
    end)
    :start()
end

return M
