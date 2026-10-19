-- Hammerspoon をログイン時に自動起動する。
-- 一度 Hammerspoon を起動してこの設定を読み込めば、以後は常駐させて使う。
hs.autoLaunch(true)

-- Hammerspoon 自身のウィンドウ移動・サイズ変更アニメーションを無効にする。
hs.window.animationDuration = 0

-- この設定で共通して使う修飾キー。
-- アプリ切り替えとウィンドウ操作を同じ「Ctrl + Cmd + Option」系に揃える。
local hyper = { "ctrl", "cmd", "alt" }
local hyperShift = { "ctrl", "cmd", "alt", "shift" }

-- アプリ切り替えでは表示名ではなく bundle ID を唯一の識別子として使う。
-- 表示名やウィンドウタイトルはアプリや状態によって変わり得るため、判定には使わない。
local appBundleIDs = {
  chrome = "com.google.Chrome",
  brave = "com.brave.Browser",
  eTyping = "com.google.Chrome.app.diccnboabdebegbpmodfgcekollacjne",
  finder = "com.apple.finder",
  preview = "com.apple.Preview",
  obsidian = "md.obsidian",
  kitty = "net.kovidgoyal.kitty",
  kindle = "com.amazon.Lassen",
  wezterm = "com.github.wez.wezterm",
  vscode = "com.microsoft.VSCode",
}

-- 対象アプリにフォーカスしたら英数入力へ切り替える。
-- 英数入力の source ID は Mac ごとの入力ソース構成によって異なるため、
-- 既知の候補を順に試し、その Mac で有効なものへ切り替える。
local englishInputSourceIDs = {
  "com.apple.inputmethod.Kotoeri.RomajiTyping.Roman",
  "com.apple.keylayout.ABC",
}
-- bundle ID をここへ追加する。
local englishInputApps = {
  [appBundleIDs.wezterm] = true,
}

local function switchToEnglishInput()
  for _, sourceID in ipairs(englishInputSourceIDs) do
    if hs.keycodes.currentSourceID(sourceID) then
      return
    end
  end
end

englishInputSourceWatcher = hs.application.watcher.new(function(_, eventType, app)
  if eventType == hs.application.watcher.activated and app and englishInputApps[app:bundleID()] then
    switchToEnglishInput()
  end
end)

-- CursorUIViewService の応答停止を切り分けるため、英数入力の自動切り替えを停止しておく。
-- 再開する場合は、次の start() を有効にする。
-- englishInputSourceWatcher:start()

-- 現在見えている Space にある、指定アプリの標準ウィンドウだけを取得する。
-- hs.window.allWindows() は呼び出すたびに現在の Mission Control Space を問い合わせるため、
-- Space 切り替え直後の古い状態を使わず、他アプリの背面にあるウィンドウも拾える。
local function visibleWindowsForApp(bundleID)
  local windows = {}

  for _, window in ipairs(hs.window.allWindows()) do
    local app = window:application()
    if app and app:bundleID() == bundleID and window:isStandard() and window:isVisible() then
      table.insert(windows, window)
    end
  end

  return windows
end

-- 現在見えている Space に対象アプリのウィンドウがあれば、まとめて前面へ出す。
-- 別の Space にしか存在しないウィンドウは一切触らない。
local function focusVisibleWindowsForApp(bundleID)
  local windows = visibleWindowsForApp(bundleID)

  if #windows == 0 then
    return false
  end

  for _, window in ipairs(windows) do
    window:raise()
  end

  windows[1]:focus()
  return true
end

-- 新しいウィンドウの生成は非同期なアプリがあるため、短時間だけ現在の Space を確認し、
-- 新しいウィンドウが見えるようになった時点で前面へ出す。
-- 確認対象は常に現在見えている Space だけなので、別の Space へ移動することはない。
local function focusVisibleWindowWhenAvailable(bundleID)
  local attemptsRemaining = 5

  local function attemptFocus()
    if focusVisibleWindowsForApp(bundleID) or attemptsRemaining <= 0 then
      return
    end

    attemptsRemaining = attemptsRemaining - 1
    hs.timer.doAfter(0.1, attemptFocus)
  end

  hs.timer.doAfter(0.05, attemptFocus)
end

-- Chrome は既存プロセスへ新しいウィンドウの生成だけを依頼する。
-- activate は使わず、生成後に現在の Space から見えるウィンドウだけをフォーカスする。
local function openChromeWindow()
  local ok = hs.osascript.applescript(string.format(
    [[
tell application id "%s"
  make new window
end tell
]],
    appBundleIDs.chrome
  ))

  if ok then
    focusVisibleWindowWhenAvailable(appBundleIDs.chrome)
  end
end

-- Brave は既存プロセスへ新しいウィンドウの生成だけを依頼する。
-- Brave が未起動でも AppleScript から起動し、同じ処理でウィンドウを生成する。
-- activate は使わず、生成後に現在の Space から見えるウィンドウだけをフォーカスする。
local function openBraveWindow()
  local ok = hs.osascript.applescript(string.format(
    [[
tell application id "%s"
  make new window
end tell
]],
    appBundleIDs.brave
  ))

  if ok then
    focusVisibleWindowWhenAvailable(appBundleIDs.brave)
  end
end

-- Finder は常駐しているため、現在の Space にウィンドウが無い場合だけ
-- ホームフォルダを表示する新しいウィンドウを作る。
-- 別 Space の Finder ウィンドウを activate して Space を移動しない。
local function openFinderWindow()
  local ok = hs.osascript.applescript(string.format(
    [[
tell application id "%s"
  set newWindow to make new Finder window
  set target of newWindow to home
end tell
]],
    appBundleIDs.finder
  ))

  if ok then
    focusVisibleWindowWhenAvailable(appBundleIDs.finder)
  end
end

-- 新しいアプリインスタンスをバックグラウンドで起動する。
-- 名前ではなく bundle ID で指定し、既存の別 Space のウィンドウを activate しない。
local function openAppInstanceInBackground(bundleID, appArguments)
  local command = string.format('/usr/bin/open -g -n -b "%s"', bundleID)
  if appArguments then
    command = command .. " --args " .. appArguments
  end

  local _, ok = hs.execute(command, true)

  if ok then
    focusVisibleWindowWhenAvailable(bundleID)
  end
end

local function openObsidianWindow()
  openAppInstanceInBackground(appBundleIDs.obsidian)
end

-- 現在の Space に Kitty のウィンドウがなければ、新しいインスタンスを起動する。
local function openKittyWindow()
  openAppInstanceInBackground(appBundleIDs.kitty)
end

-- 現在の Space に WezTerm のウィンドウがなければ、新しいインスタンスを起動する。
local function openWezTermWindow()
  openAppInstanceInBackground(appBundleIDs.wezterm)
end

-- VS Code は --new-window を明示して、既存ウィンドウを別 Space から呼び戻さず
-- 現在の Space に新しいウィンドウを作る。
local function openVSCodeWindow()
  openAppInstanceInBackground(appBundleIDs.vscode, "--new-window")
end

-- アプリ切り替え用の設定。
-- 現在の Space にウィンドウが無ければ、各アプリ固有の方法で新しいウィンドウを作る。
local apps = {
  ["f"] = {
    bundleID = appBundleIDs.chrome,
    openWindow = openChromeWindow,
  },
  ["s"] = {
    bundleID = appBundleIDs.obsidian,
    openWindow = openObsidianWindow,
  },
  ["k"] = {
    bundleID = appBundleIDs.finder,
    openWindow = openFinderWindow,
  },
  ["w"] = {
    bundleID = appBundleIDs.brave,
    launch = openBraveWindow,
    openWindow = openBraveWindow,
  },
  ["t"] = {
    bundleID = appBundleIDs.wezterm,
    openWindow = openWezTermWindow,
  },
  ["n"] = {
    bundleID = appBundleIDs.vscode,
    openWindow = openVSCodeWindow,
  },
  ["y"] = {
    bundleID = appBundleIDs.kindle,
  },
  ["p"] = {
    bundleID = appBundleIDs.preview,
  },
}

-- 指定したアプリを、現在見えている Space の範囲内だけで扱う。
--
-- 未起動の場合:
--   launch があればアプリ固有の起動処理を使い、無ければ bundle ID で通常起動する。
--
-- 起動済みの場合:
--   現在見えている Space にウィンドウがあれば、それらだけをまとめて前面へ出す。
--   現在の Space にウィンドウが無ければ、各アプリの openWindow で新しいウィンドウを作る。
local function activateApp(appConfig)
  local bundleID = appConfig.bundleID
  local runningApps = hs.application.applicationsForBundleID(bundleID)

  if #runningApps == 0 then
    if appConfig.launch then
      appConfig.launch()
    else
      hs.application.launchOrFocusByBundleID(bundleID)
    end
    return
  end

  if focusVisibleWindowsForApp(bundleID) then
    return
  end

  if appConfig.openWindow then
    appConfig.openWindow()
  end
end

-- Ctrl + Cmd + Option + f: Google Chrome
-- Ctrl + Cmd + Option + s: Obsidian
-- Ctrl + Cmd + Option + k: Finder
-- Ctrl + Cmd + Option + w: Brave Browser
-- Ctrl + Cmd + Option + t: WezTerm
-- Ctrl + Cmd + Option + n: Visual Studio Code
-- Ctrl + Cmd + Option + y: Kindle
-- Ctrl + Cmd + Option + p: Preview
for key, appConfig in pairs(apps) do
  hs.hotkey.bind(hyper, key, function()
    activateApp(appConfig)
  end)
end
-- e-typing は Chrome からインストールした Web アプリで、通常のアプリ切り替え規則の例外。
-- 未起動なら現在の Space で起動し、現在の Space にあれば前面へ出す。
-- 別の Space ですでに起動している場合は、その Space へ移動も新規起動もせず何もしない。
local function activateETyping()
  local bundleID = appBundleIDs.eTyping
  local runningApps = hs.application.applicationsForBundleID(bundleID)

  if #runningApps == 0 then
    hs.application.launchOrFocusByBundleID(bundleID)
    return
  end

  focusVisibleWindowsForApp(bundleID)
end

-- Ctrl + Cmd + Option + x: e-typing
hs.hotkey.bind(hyper, "x", activateETyping)

-- 現在フォーカスされているウィンドウに対して処理を行う。
-- Finder の Desktop など、操作対象の通常ウィンドウが存在しない場合は何もしない。
local function withFocusedWindow(action)
  local window = hs.window.focusedWindow()
  if window then
    action(window)
  end
end

-- Ctrl + Cmd + Option + Enter: アクティブなウィンドウの画像をクリップボードへコピーする。
hs.hotkey.bind(hyper, "return", function()
  withFocusedWindow(function(window)
    local image = window:snapshot()
    if image then
      hs.pasteboard.writeObjects(image)
    end
  end)
end)

-- 横幅が 2400 ポイント以上の画面では左右を 1/3、それ以外では 1/2 に配置する。
-- 27 インチ外部モニター（3008 ポイント）と MacBook（15 / 16 インチ）を想定。
-- 中央は画面の大きさに関係なく 1/3 とする。
-- 現在の配置は参照せず、同じキーで常に同じ位置・サイズへ移動する。
local wideScreenMinWidth = 2400

local function placeFocusedWindow(position)
  withFocusedWindow(function(window)
    local screen = window:screen()
    if not screen then
      return
    end

    local third = 1 / 3
    local unit
    if position == "center" then
      unit = { x = third, y = 0, w = third, h = 1 }
    else
      local width = screen:frame().w >= wideScreenMinWidth and third or 0.5
      unit = {
        x = position == "left" and 0 or 1 - width,
        y = 0,
        w = width,
        h = 1,
      }
    end

    window:moveToUnit(unit)
  end)
end

-- Ctrl + Cmd + Option + I: 広い画面では左 1/3、それ以外では左 1/2。
hs.hotkey.bind(hyper, "i", function()
  placeFocusedWindow("left")
end)

-- Ctrl + Cmd + Option + O: どの画面でも中央 1/3。
hs.hotkey.bind(hyper, "o", function()
  placeFocusedWindow("center")
end)

-- Ctrl + Cmd + Option + -: 広い画面では右 1/3、それ以外では右 1/2。
hs.hotkey.bind(hyper, "-", function()
  placeFocusedWindow("right")
end)

-- Ctrl + Cmd + Option + A: 最大化と、最大化する前の位置・サイズを切り替える。
-- ウィンドウごとに記憶し、ほかの操作で配置が変わった場合は新しい位置・サイズから開始する。
local maximizedWindowFrames = {}

local function framesNearlyEqual(a, b)
  local tolerance = 5 -- アプリによる位置・サイズの丸め誤差を許容する。
  return math.abs(a.x - b.x) <= tolerance
    and math.abs(a.y - b.y) <= tolerance
    and math.abs(a.w - b.w) <= tolerance
    and math.abs(a.h - b.h) <= tolerance
end

hs.hotkey.bind(hyper, "a", function()
  withFocusedWindow(function(window)
    local windowID = window:id()
    if not windowID then
      return
    end

    local frame = window:frame()
    local saved = maximizedWindowFrames[windowID]
    if saved and framesNearlyEqual(frame, saved.maximized) then
      window:setFrame(saved.original, 0)
      maximizedWindowFrames[windowID] = nil
    else
      window:maximize(0)
      maximizedWindowFrames[windowID] = {
        original = frame,
        maximized = window:frame(),
      }
    end
  end)
end)

-- アクティブなウィンドウを隣のモニタへ循環移動する。
-- サイズと相対位置は変えず、モニタだけを移動する。
-- hs.screen:next()/previous() の順序は Hammerspoon が決めるため、
-- 3 画面以上では物理配置上の時計回り・反時計回りとは限らない。
local function moveFocusedWindowToAdjacentScreen(direction)
  withFocusedWindow(function(window)
    local currentScreen = window:screen()
    if not currentScreen then
      return
    end

    local targetScreen
    if direction == "next" then
      targetScreen = currentScreen:next()
    else
      targetScreen = currentScreen:previous()
    end

    if not targetScreen then
      return
    end
    window:moveToScreen(targetScreen, true, false, 0)
  end)
end

-- Ctrl + Cmd + Option + Tab: 次のモニタへ循環移動する。
hs.hotkey.bind(hyper, "tab", function()
  moveFocusedWindowToAdjacentScreen("next")
end)

-- Ctrl + Cmd + Option + Shift + Tab: 前のモニタへ循環移動する。
hs.hotkey.bind(hyperShift, "tab", function()
  moveFocusedWindowToAdjacentScreen("previous")
end)

-- Mouse4 / Mouse5 を、マウスカーソル下ではなくアクティブなウィンドウの
-- 「戻る / 進む」操作へ変換する。実機では Mouse4 = 3、Mouse5 = 4。
local navigationMouseButtons = {
  [3] = true,
  [4] = true,
}

-- 文字名からの変換は JIS 配列で実機と異なる keycode になったため、
-- VS Code 以外では Cmd + [ / ] 相当の実機で確認した物理 keycode を直接送る。
local function sendDefaultNavigation(button)
  local keyCode = button == 3 and 30 or 42
  hs.eventtap.event.newKeyEvent({ "cmd" }, keyCode, true):post()
  hs.eventtap.event.newKeyEvent({ "cmd" }, keyCode, false):post()
end

-- VS Code の「進む」は JIS の「ろ」キー（virtual keycode 94）に Ctrl を付けた操作。
-- 文字名ではなく、実機で確認した keycode を直接送ってキーボード配列の差を避ける。
local function sendVSCodeForward()
  hs.eventtap.event.newKeyEvent({ "ctrl" }, 94, true):post()
  hs.eventtap.event.newKeyEvent({ "ctrl" }, 94, false):post()
end

local function sendMouseNavigation(button, bundleID)
  if bundleID == appBundleIDs.vscode then
    if button == 3 then
      hs.eventtap.keyStroke({ "ctrl" }, "-", 0)
    else
      sendVSCodeForward()
    end
    return
  end

  sendDefaultNavigation(button)
end

mouseNavigationEventTap = hs.eventtap.new({
  hs.eventtap.event.types.otherMouseDown,
  hs.eventtap.event.types.otherMouseUp,
}, function(event)
  local button = event:getProperty(hs.eventtap.event.properties.mouseEventButtonNumber)

  if not navigationMouseButtons[button] then
    return false
  end

  local window = hs.window.focusedWindow()
  local app = window and window:application()
  local bundleID = app and app:bundleID()

  -- アクティブな通常ウィンドウを特定できない場合は Mouse4 / Mouse5 をそのまま通す。
  if not bundleID then
    return false
  end

  -- MouseUp は握り潰し、操作は MouseDown の一度だけ実行する。
  if event:getType() == hs.eventtap.event.types.otherMouseUp then
    return true
  end

  sendMouseNavigation(button, bundleID)
  return true
end)

mouseNavigationEventTap:start()

-- Ctrl + Cmd + Option + Q: 選択中のテキストを macOS 標準の翻訳 UI で表示する。
require("modules.translation_popup").start()

-- Ctrl + Cmd + Option + L: 選択した Mermaid コードを SVG / PDF に変換し、PDF をプレビューで開く。
require("modules.mermaid_preview").start()

-- ChatGPT の回答完了通知はブラウザ側の userscript と組み合わせて使う。
require("modules.chatgpt_notify").start()
