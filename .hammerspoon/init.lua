-- Hammerspoon をログイン時に自動起動する。
-- 一度 Hammerspoon を起動してこの設定を読み込めば、以後は常駐させて使う。
hs.autoLaunch(true)

-- アプリ切り替え用の設定。
-- Cmd + Option + Fn で、普段使うアプリへ直接フォーカスを移す。
local apps = {
  F1 = "Google Chrome",
  F2 = "Obsidian",
  F3 = "WezTerm",
  F4 = "Visual Studio Code",
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

-- Cmd + Option + F1: Google Chrome
-- Cmd + Option + F2: Obsidian
-- Cmd + Option + F3: WezTerm
-- Cmd + Option + F4: Visual Studio Code
for key, appName in pairs(apps) do
  hs.hotkey.bind({ "cmd", "alt" }, key, function()
    activateApp(appName)
  end)
end
