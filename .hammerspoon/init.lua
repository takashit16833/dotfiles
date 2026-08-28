-- Hammerspoon をログイン時に自動起動する。
-- 一度 Hammerspoon を起動してこの設定を読み込めば、以後は常駐させて使う。
hs.autoLaunch(true)

-- Hammerspoon 自身のウィンドウ移動・サイズ変更アニメーションを無効にする。
hs.window.animationDuration = 0

-- この設定で共通して使う修飾キー。
-- アプリ切り替えとウィンドウ操作を同じ「Ctrl + Cmd + Option」系に揃える。
local hyper = { "ctrl", "cmd", "alt" }
local hyperShift = { "ctrl", "cmd", "alt", "shift" }

-- Chrome が ChatGPT の Web アプリに割り当てた App ID。
-- bundle ID と --app-id の両方で同じ識別子を使う。
local chatGPTAppID = "cadlkienfkclaiaibeoongdcgmdikeeg"

-- アプリ切り替えでは表示名ではなく bundle ID を唯一の識別子として使う。
-- 表示名やウィンドウタイトルはアプリや状態によって変わり得るため、判定には使わない。
local appBundleIDs = {
  chatgpt = "com.google.Chrome.app." .. chatGPTAppID,
  chrome = "com.google.Chrome",
  obsidian = "md.obsidian",
  kitty = "net.kovidgoyal.kitty",
  vscode = "com.microsoft.VSCode",
}

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
  local ok = hs.osascript.applescript(string.format([[
tell application id "%s"
  make new window
end tell
]], appBundleIDs.chrome))

  if ok then
    focusVisibleWindowWhenAvailable(appBundleIDs.chrome)
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

-- 起動中の task を保持し、Chrome への起動依頼が完了する前に GC されないようにする。
local chatGPTLaunchTask = nil

-- ChatGPT.app 自体を open すると、別 Space にある既存ウィンドウへ移動してしまう。
-- Chrome 本体へ --app-id を直接渡すと現在の Space に ChatGPT の新規ウィンドウが作られるため、
-- ChatGPT だけは shell を介さない hs.task でこの起動経路を使う。
local function openChatGPTWindow()
  chatGPTLaunchTask = hs.task.new(
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
    function(exitCode)
      chatGPTLaunchTask = nil

      if exitCode == 0 then
        focusVisibleWindowWhenAvailable(appBundleIDs.chatgpt)
      end
    end,
    { "--app-id=" .. chatGPTAppID }
  )

  if chatGPTLaunchTask and not chatGPTLaunchTask:start() then
    chatGPTLaunchTask = nil
  end
end

local function openObsidianWindow()
  openAppInstanceInBackground(appBundleIDs.obsidian)
end

-- Kitty は新しいインスタンスを起動することで、通常起動時と同じように local.conf と
-- そこから参照される startup session を読み込ませる。
local function openKittyWindow()
  openAppInstanceInBackground(appBundleIDs.kitty)
end

-- VS Code は --new-window を明示して、既存ウィンドウを別 Space から呼び戻さず
-- 現在の Space に新しいウィンドウを作る。
local function openVSCodeWindow()
  openAppInstanceInBackground(appBundleIDs.vscode, "--new-window")
end

-- アプリ切り替え用の設定。
-- 現在の Space にウィンドウが無ければ、各アプリ固有の方法で新しいウィンドウを作る。
local apps = {
  ["g"] = {
    bundleID = appBundleIDs.chatgpt,
    openWindow = openChatGPTWindow,
  },
  ["f"] = {
    bundleID = appBundleIDs.chrome,
    openWindow = openChromeWindow,
  },
  ["w"] = {
    bundleID = appBundleIDs.obsidian,
    openWindow = openObsidianWindow,
  },
  ["r"] = {
    bundleID = appBundleIDs.kitty,
    openWindow = openKittyWindow,
  },
  ["y"] = {
    bundleID = appBundleIDs.vscode,
    openWindow = openVSCodeWindow,
  },
}

-- 指定したアプリを、現在見えている Space の範囲内だけで扱う。
--
-- 未起動の場合:
--   bundle ID で通常起動する。
--
-- 起動済みの場合:
--   現在見えている Space にウィンドウがあれば、それらだけをまとめて前面へ出す。
--   現在の Space にウィンドウが無ければ、各アプリの openWindow で新しいウィンドウを作る。
local function activateApp(appConfig)
  local bundleID = appConfig.bundleID
  local runningApps = hs.application.applicationsForBundleID(bundleID)

  if #runningApps == 0 then
    hs.application.launchOrFocusByBundleID(bundleID)
    return
  end

  if focusVisibleWindowsForApp(bundleID) then
    return
  end

  if appConfig.openWindow then
    appConfig.openWindow()
  end
end

-- Ctrl + Cmd + Option + g: ChatGPT
-- Ctrl + Cmd + Option + f: Google Chrome
-- Ctrl + Cmd + Option + w: Obsidian
-- Ctrl + Cmd + Option + r: kitty
-- Ctrl + Cmd + Option + y: Visual Studio Code
for key, appConfig in pairs(apps) do
  hs.hotkey.bind(hyper, key, function()
    activateApp(appConfig)
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

-- setFrame* / moveToUnit / maximize などの高水準 API を使わず、
-- 実測でアニメーションなしだった setSize と setTopLeft だけで配置する。
-- 同じモニタ内では先にサイズを変え、最後に位置を合わせることで端への配置もずれにくくする。
local function setWindowFrameImmediately(window, frame)
  window:setSize({ w = frame.w, h = frame.h })
  window:setTopLeft({ x = frame.x, y = frame.y })
end

-- 画面に対する比率指定から実座標のフレームを作る。
local function unitFrameOnScreen(screen, unit)
  local screenFrame = screen:frame()
  return {
    x = screenFrame.x + screenFrame.w * unit.x,
    y = screenFrame.y + screenFrame.h * unit.y,
    w = screenFrame.w * unit.w,
    h = screenFrame.h * unit.h,
  }
end

-- Ctrl + Cmd + Option + K: 現在のウィンドウを画面の左半分へ配置する。
hs.hotkey.bind(hyper, "k", function()
  withFocusedWindow(function(window)
    local screen = window:screen()
    if screen then
      setWindowFrameImmediately(window, unitFrameOnScreen(screen, { x = 0, y = 0, w = 0.5, h = 1 }))
    end
  end)
end)

-- Ctrl + Cmd + Option + S: 現在のウィンドウを画面の右半分へ配置する。
hs.hotkey.bind(hyper, "s", function()
  withFocusedWindow(function(window)
    local screen = window:screen()
    if screen then
      setWindowFrameImmediately(window, unitFrameOnScreen(screen, { x = 0.5, y = 0, w = 0.5, h = 1 }))
    end
  end)
end)

-- Ctrl + Cmd + Option + N: macOS の fullscreen にはせず、
-- 現在の画面で利用可能な領域いっぱいまでウィンドウを最大化する。
hs.hotkey.bind(hyper, "n", function()
  withFocusedWindow(function(window)
    local screen = window:screen()
    if screen then
      setWindowFrameImmediately(window, screen:frame())
    end
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

-- 指定したウィンドウを、指定した画面で基準サイズにして中央へ配置する。
local function centerWindowOnScreen(window, screen)
  local screenFrame = screen:frame()
  local width, height = standardWindowSizeForScreen(screen)
  local frame = {
    x = screenFrame.x + (screenFrame.w - width) / 2,
    y = screenFrame.y + (screenFrame.h - height) / 2,
    w = width,
    h = height,
  }

  setWindowFrameImmediately(window, frame)
end

-- Ctrl + Cmd + Option + T: 現在のウィンドウを基準サイズにして画面中央へ配置する。
hs.hotkey.bind(hyper, "t", function()
  withFocusedWindow(function(window)
    local screen = window:screen()
    if screen then
      centerWindowOnScreen(window, screen)
    end
  end)
end)

-- 配置操作の対象か判定する。
-- デスクトップなどを除き、通常のアプリウィンドウだけを対象にする。
local function isArrangeTarget(window)
  return window:isStandard()
end

-- 現在見えている配置対象のウィンドウを、前面から順に取得する。
local function arrangeTargets()
  local windows = {}

  for _, window in ipairs(hs.window.orderedWindows()) do
    if isArrangeTarget(window) then
      table.insert(windows, window)
    end
  end

  return windows
end

-- 指定したモニタ上の配置対象ウィンドウだけを取得する。
local function arrangeTargetsOnScreen(screen)
  local windows = {}
  local screenId = screen:id()

  for _, window in ipairs(arrangeTargets()) do
    local windowScreen = window:screen()
    if windowScreen and windowScreen:id() == screenId then
      table.insert(windows, window)
    end
  end

  return windows
end

-- 3 ウィンドウの場合は、前面の 1 枚を左半分、残り 2 枚を右上・右下へ配置する。
local function tileThreeWindows(screen, windows)
  local frame = screen:frame()
  local halfWidth = frame.w / 2
  local halfHeight = frame.h / 2

  setWindowFrameImmediately(windows[1], {
    x = frame.x,
    y = frame.y,
    w = halfWidth,
    h = frame.h,
  })
  setWindowFrameImmediately(windows[2], {
    x = frame.x + halfWidth,
    y = frame.y,
    w = halfWidth,
    h = halfHeight,
  })
  setWindowFrameImmediately(windows[3], {
    x = frame.x + halfWidth,
    y = frame.y + halfHeight,
    w = halfWidth,
    h = halfHeight,
  })
end

-- 指定したモニタ上の全ウィンドウをタイル状に並べる。
-- 3 枚だけは「左半分 + 右上下」、それ以外は均等なグリッドにする。
local function tileWindowsOnScreen(screen)
  local windows = arrangeTargetsOnScreen(screen)
  local count = #windows
  if count == 0 then
    return
  end

  if count == 3 then
    tileThreeWindows(screen, windows)
    return
  end

  local screenFrame = screen:frame()
  local columns = math.max(1, math.ceil(math.sqrt(count)))
  local rows = math.ceil(count / columns)
  local tileHeight = screenFrame.h / rows

  local index = 1
  for row = 1, rows do
    local remaining = count - index + 1
    local itemsInRow = math.min(columns, remaining)
    local tileWidth = screenFrame.w / itemsInRow

    for column = 1, itemsInRow do
      local window = windows[index]
      setWindowFrameImmediately(window, {
        x = screenFrame.x + (column - 1) * tileWidth,
        y = screenFrame.y + (row - 1) * tileHeight,
        w = tileWidth,
        h = tileHeight,
      })
      index = index + 1
    end
  end
end

-- 指定したモニタ上の全ウィンドウを、基準サイズに揃えて中央へ重ねる。
local function centerWindowsOnScreen(screen)
  for _, window in ipairs(arrangeTargetsOnScreen(screen)) do
    centerWindowOnScreen(window, screen)
  end
end

-- 指定したモニタ上の全ウィンドウを、macOS の fullscreen モードにはせず最大化する。
local function maximizeWindowsOnScreen(screen)
  local frame = screen:frame()
  for _, window in ipairs(arrangeTargetsOnScreen(screen)) do
    setWindowFrameImmediately(window, frame)
  end
end

-- Ctrl + Cmd + Option + P: 現在フォーカス中のウィンドウがあるモニタをタイル表示する。
hs.hotkey.bind(hyper, "p", function()
  tileWindowsOnScreen(hs.screen.mainScreen())
end)

-- Ctrl + Cmd + Option + H: 現在フォーカス中のウィンドウがあるモニタの全ウィンドウを最大化する。
hs.hotkey.bind(hyper, "h", function()
  maximizeWindowsOnScreen(hs.screen.mainScreen())
end)

-- Ctrl + Cmd + Option + B: 現在フォーカス中のウィンドウがあるモニタの全ウィンドウを
-- 基準サイズに揃えて中央へ重ねる。
hs.hotkey.bind(hyper, "b", function()
  centerWindowsOnScreen(hs.screen.mainScreen())
end)

-- アクティブなウィンドウを隣のモニタへ循環移動し、
-- 移動先で基準サイズに揃えて画面中央へ配置する。
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

    if targetScreen then
      local screenFrame = targetScreen:frame()
      local width, height = standardWindowSizeForScreen(targetScreen)

      -- 別モニタへ移す場合は、まず目的の座標へ瞬間移動してからサイズを合わせる。
      -- これにより moveToScreen のアニメーションを使わずに済む。
      window:setTopLeft({
        x = screenFrame.x + (screenFrame.w - width) / 2,
        y = screenFrame.y + (screenFrame.h - height) / 2,
      })
      window:setSize({ w = width, h = height })
    end
  end)
end

-- Ctrl + Cmd + Option + Tab: 次のモニタへ循環移動し、中央へ配置する。
hs.hotkey.bind(hyper, "tab", function()
  moveFocusedWindowToAdjacentScreen("next")
end)

-- Ctrl + Cmd + Option + Shift + Tab: 前のモニタへ循環移動し、中央へ配置する。
hs.hotkey.bind(hyperShift, "tab", function()
  moveFocusedWindowToAdjacentScreen("previous")
end)
