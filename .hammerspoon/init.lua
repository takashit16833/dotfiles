-- Hammerspoon をログイン時に自動起動する。
-- 一度 Hammerspoon を起動してこの設定を読み込めば、以後は常駐させて使う。
hs.autoLaunch(true)

-- この設定で共通して使う修飾キー。
-- アプリ切り替えとウィンドウ操作を同じ「Ctrl + Cmd + Option」系に揃える。
local hyper = { "ctrl", "cmd", "alt" }
local hyperShift = { "ctrl", "cmd", "alt", "shift" }

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

-- Ctrl + Cmd + Option + K: 現在のウィンドウを画面の左半分へ配置する。
hs.hotkey.bind(hyper, "k", function()
  withFocusedWindow(function(window)
    window:moveToUnit({ x = 0, y = 0, w = 0.5, h = 1 })
  end)
end)

-- Ctrl + Cmd + Option + S: 現在のウィンドウを画面の右半分へ配置する。
hs.hotkey.bind(hyper, "s", function()
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

-- ウィンドウ操作で共通して使う基準サイズ。
-- Hammerspoon のウィンドウサイズは macOS の画面座標（point）単位。
local standardWindowWidth = 1504
local standardWindowHeight = 940

-- 指定した画面で、基準サイズを超えない範囲のウィンドウサイズを返す。
-- 小さい画面では利用可能領域に収まるように縮める。
local function standardWindowSizeForScreen(screen)
  local screenFrame = screen:frame()
  return math.min(standardWindowWidth, screenFrame.w), math.min(standardWindowHeight, screenFrame.h)
end

-- Ctrl + Cmd + Option + T: 現在のウィンドウを基準サイズにして画面中央へ配置する。
hs.hotkey.bind(hyper, "t", function()
  withFocusedWindow(function(window)
    local screen = window:screen()
    local screenFrame = screen:frame()
    local width, height = standardWindowSizeForScreen(screen)
    local frame = {
      x = screenFrame.x + (screenFrame.w - width) / 2,
      y = screenFrame.y + (screenFrame.h - height) / 2,
      w = width,
      h = height,
    }

    window:setFrameInScreenBounds(frame)
  end)
end)

-- 斜め配置の対象か判定する。
-- 通常ウィンドウだけを対象とし、Finder は除外する。
local function isDiagonalArrangeTarget(window)
  local app = window:application()
  return window:isStandard() and app and app:name() ~= "Finder"
end

-- 現在見えている斜め配置対象のウィンドウを、前面から順に取得する。
local function diagonalArrangeTargets()
  local windows = {}

  for _, window in ipairs(hs.window.orderedWindows()) do
    if isDiagonalArrangeTarget(window) then
      table.insert(windows, window)
    end
  end

  return windows
end

-- 指定した画面上の対象ウィンドウを、左上から右下への対角線に沿って配置する。
-- 各ウィンドウは基準サイズに揃え、画面内に収まる範囲で中心点を等間隔に並べる。
local function arrangeWindowsDiagonallyOnScreen(screen, targets)
  local windows = {}
  local screenId = screen:id()

  for _, window in ipairs(targets) do
    local windowScreen = window:screen()
    if windowScreen and windowScreen:id() == screenId then
      table.insert(windows, window)
    end
  end

  if #windows == 0 then
    return
  end

  local screenFrame = screen:frame()
  local width, height = standardWindowSizeForScreen(screen)

  -- 対角線上の位置を t=0（左上）〜t=1（右下）で表す。
  -- ウィンドウ全体が画面内に収まる t の範囲だけを使用する。
  local minT = math.max(width / (2 * screenFrame.w), height / (2 * screenFrame.h))
  local maxT = math.min(1 - width / (2 * screenFrame.w), 1 - height / (2 * screenFrame.h))

  for index, window in ipairs(windows) do
    local t
    if #windows == 1 then
      t = 0.5
    else
      t = minT + (maxT - minT) * (index - 1) / (#windows - 1)
    end

    local centerX = screenFrame.x + screenFrame.w * t
    local centerY = screenFrame.y + screenFrame.h * t
    local frame = {
      x = centerX - width / 2,
      y = centerY - height / 2,
      w = width,
      h = height,
    }

    window:setFrameInScreenBounds(frame)
  end
end

-- Ctrl + Cmd + Option + H: 現在のモニタだけを斜め配置する。
hs.hotkey.bind(hyper, "h", function()
  arrangeWindowsDiagonallyOnScreen(hs.screen.mainScreen(), diagonalArrangeTargets())
end)

-- Ctrl + Cmd + Option + Shift + H: すべてのモニタを、それぞれ独立して斜め配置する。
hs.hotkey.bind(hyperShift, "h", function()
  local targets = diagonalArrangeTargets()

  for _, screen in ipairs(hs.screen.allScreens()) do
    arrangeWindowsDiagonallyOnScreen(screen, targets)
  end
end)
