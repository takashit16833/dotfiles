-- Hammerspoon をログイン時に自動起動する。
-- 一度 Hammerspoon を起動してこの設定を読み込めば、以後は常駐させて使う。
hs.autoLaunch(true)

-- この設定で共通して使う修飾キー。
-- アプリ切り替えとウィンドウ操作を同じ「Ctrl + Cmd + Option」系に揃える。
local hyper = { "ctrl", "cmd", "alt" }

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
  hs.hotkey.bind(hyper, key, function()
    activateApp(appName)
  end)
end

-- 現在フォーカスされているウィンドウに対して処理を行う。
-- Finder の Desktop など、操作対象の通常ウィンドウが存在しない場合は何もしない。
local function withFocusedWindow(action)
  local window = hs.window.focusedWindow()
  if window then
    action(window)
  end
end

-- Ctrl + Cmd + Option + S: 現在のウィンドウを画面の左半分へ配置する。
hs.hotkey.bind(hyper, "s", function()
  withFocusedWindow(function(window)
    window:moveToUnit({ x = 0, y = 0, w = 0.5, h = 1 })
  end)
end)

-- Ctrl + Cmd + Option + K: 現在のウィンドウを画面の右半分へ配置する。
hs.hotkey.bind(hyper, "k", function()
  withFocusedWindow(function(window)
    window:moveToUnit({ x = 0.5, y = 0, w = 0.5, h = 1 })
  end)
end)

-- Ctrl + Cmd + Option + N: macOS の fullscreen にはせず、
-- 現在の画面で利用可能な領域いっぱいまでウィンドウを最大化する。
hs.hotkey.bind(hyper, "n", function()
  withFocusedWindow(function(window)
    window:maximize()
  end)
end)

-- Ctrl + Cmd + Option + T: 現在のウィンドウを 1920x1080 にして画面中央へ配置する。
-- Hammerspoon のウィンドウサイズは macOS の画面座標（point）単位。
-- 画面の利用可能領域より大きい場合は、画面内に収まるよう自動調整する。
hs.hotkey.bind(hyper, "t", function()
  withFocusedWindow(function(window)
    local screenFrame = window:screen():frame()
    local width = 1920
    local height = 1080
    local frame = {
      x = screenFrame.x + (screenFrame.w - width) / 2,
      y = screenFrame.y + (screenFrame.h - height) / 2,
      w = width,
      h = height,
    }

    window:setFrameInScreenBounds(frame)
  end)
end)
