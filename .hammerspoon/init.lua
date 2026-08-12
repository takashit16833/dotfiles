-- Hammerspoon をログイン時に自動起動する。
-- 一度 Hammerspoon を起動してこの設定を読み込めば、以後は常駐させて使う。
hs.autoLaunch(true)

-- アプリ切り替え用の設定。
-- Ctrl + Cmd + Option + 数字キーで、普段使うアプリへ直接フォーカスを移す。
local apps = {
  ["3"] = "Google Chrome",
  ["4"] = "Obsidian",
  ["5"] = "WezTerm",
  ["6"] = "Visual Studio Code",
}

-- 指定したアプリを前面へ出す。
--
-- 起動済みの場合:
--   activate(true) により、そのアプリのウィンドウをまとめて前面へ出す。
--
-- 未起動の場合:
--   launchOrFocus でアプリを起動し、そのままフォーカスする。
--
-- Mission Control の別 Space にあるウィンドウを現在の Space へ移動する処理ではない。
-- macOS の Space / fullscreen の挙動はそのまま尊重する。
local function activateApp(appName)
  local app = hs.application.get(appName)

  if app then
    app:unhide()
    app:activate(true)
    return
  end

  hs.application.launchOrFocus(appName)
end

-- Ctrl + Cmd + Option + 3: Google Chrome
-- Ctrl + Cmd + Option + 4: Obsidian
-- Ctrl + Cmd + Option + 5: WezTerm
-- Ctrl + Cmd + Option + 6: Visual Studio Code
for key, appName in pairs(apps) do
  hs.hotkey.bind({ "ctrl", "cmd", "alt" }, key, function()
    activateApp(appName)
  end)
end
