local wezterm = require "wezterm"
local config = wezterm.config_builder()

-- 修飾キーを端末内のアプリへ伝える。
config.enable_kitty_keyboard = true

-- 左右のOptionを特殊文字に合成せず、修飾キーとして扱う。
config.send_composed_key_when_left_alt_is_pressed = false
config.send_composed_key_when_right_alt_is_pressed = false

-- Retro Hacker Blue の基本色。
local background = "#010111"
local foreground = "#5EAFFF"
local cyber_pink = "#FF4DE1"

-- Emacsのretro-hacker-blue-core.elにあるmode-lineの背景色・文字色に揃える。
-- タブバーの余白は透明のままにする。
local tab_bar_transparent = "rgba(0, 0, 0, 0)"
local tab_active_background = "#000E2F"
local tab_active_foreground = "#316CBD"
local tab_inactive_background = "#000008"
local tab_inactive_foreground = "#102F66"

config.colors = {
  foreground = foreground,
  background = background,

  -- カーソルは Cyber Pink。
  cursor_bg = cyber_pink,
  cursor_fg = background,
  cursor_border = cyber_pink,

  selection_fg = "#FFFFFF",
  selection_bg = "rgba(23, 51, 102, 0.70)",
  scrollbar_thumb = "#2759AA",
  split = "#00184A",

  ansi = {
    "#000000",
    cyber_pink,
    "#4682B4",
    "#FFD700",
    "#3B85D8",
    "#8A5EC0",
    "#00CED1",
    "#E0EEFF",
  },
  brights = {
    "#1A1A1A",
    cyber_pink,
    "#6CB8F0",
    "#FFFF00",
    foreground,
    "#B07CFF",
    "#00FFFF",
    "#FFFFFF",
  },
  -- Emacsのアクティブ・非アクティブのモードラインとそれぞれ同じ配色にする。
  tab_bar = {
    background = tab_bar_transparent,
    active_tab = {
      bg_color = tab_active_background,
      fg_color = tab_active_foreground,
      intensity = "Bold",
    },
    inactive_tab = {
      bg_color = tab_inactive_background,
      fg_color = tab_inactive_foreground,
    },
    inactive_tab_hover = {
      bg_color = tab_inactive_background,
      fg_color = tab_inactive_foreground,
    },
    inactive_tab_edge = tab_bar_transparent,
  },
}

-- macOS のタイトルバーを端末の背景に馴染ませる。
config.window_frame = {
  active_titlebar_bg = background,
  inactive_titlebar_bg = background,
  active_titlebar_border_bottom = background,
  inactive_titlebar_border_bottom = background,
}

-- タブは四角形で、端末のフォントサイズを使用する。
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = true
config.hide_tab_bar_if_only_one_tab = true
config.tab_max_width = 32

-- タブの追加ボタン・閉じるボタン・番号を表示しない。
config.show_new_tab_button_in_tab_bar = false
config.show_close_tab_button_in_tabs = false
config.show_tab_index_in_tab_bar = false

-- 両方のタブを四角形にし、Emacsの各モードラインと背景色・文字色を揃える。
wezterm.on("format-tab-title", function(tab, _, _, _, _, max_width)
  local title = tab.tab_title
  if not title or title == "" then
    title = tab.active_pane.title
  end

  local tab_background = tab.is_active and tab_active_background or tab_inactive_background
  local tab_foreground = tab.is_active and tab_active_foreground or tab_inactive_foreground
  local intensity = tab.is_active and "Bold" or "Normal"
  title = wezterm.truncate_right(title, math.max(1, max_width - 5))

  return {
    { Background = { Color = tab_bar_transparent } },
    { Text = " " },
    { Background = { Color = tab_background } },
    { Foreground = { Color = tab_foreground } },
    { Attribute = { Intensity = intensity } },
    { Text = "  " .. title .. "  " },
    { Background = { Color = tab_bar_transparent } },
  }
end)

-- Nightly 限定: macOS 標準タイトルバーを残し、背景色をターミナルと揃える。
config.window_decorations = "TITLE|RESIZE|MACOS_USE_BACKGROUND_COLOR_AS_TITLEBAR_COLOR"

-- Workspace 名をタイトルバーに表示する。
wezterm.on("format-window-title", function()
  return wezterm.mux.get_active_workspace()
end)

-- キー設定。
config.keys = {
  -- Cmd+Fを端末内のアプリへ渡す。
  { key = "f", mods = "CMD", action = wezterm.action.DisableDefaultAssignment },
  -- Deleteを標準のエスケープシーケンスで送信する。
  { key = "Delete", mods = "NONE", action = wezterm.action.SendString "\x1b[3~" },
  -- zshの行編集。
  { key = "LeftArrow", mods = "CMD", action = wezterm.action.SendString "\x01" },
  { key = "RightArrow", mods = "CMD", action = wezterm.action.SendString "\x05" },
  -- Cmd+BackspaceをSuper付きBackspaceとして送信する。
  { key = "Backspace", mods = "CMD", action = wezterm.action.SendString "\x1b[127;9u" },
  -- 単語単位の移動・削除。
  { key = "LeftArrow", mods = "ALT", action = wezterm.action.SendKey { key = "b", mods = "ALT" } },
  { key = "RightArrow", mods = "ALT", action = wezterm.action.SendKey { key = "f", mods = "ALT" } },
  { key = "Delete", mods = "ALT", action = wezterm.action.SendKey { key = "d", mods = "ALT" } },
  -- 暫定対応: WezTermで失われるCmd+Shiftの修飾キーを直接送信する。
  {
    key = "phys:K",
    mods = "CMD|SHIFT",
    action = wezterm.action.SendString "\x1b[107;10u",
  },
  {
    key = "phys:Z",
    mods = "CMD|SHIFT",
    action = wezterm.action.SendString "\x1b[122;10u",
  },
}

-- PC固有のWorkspace設定があれば読み込む。
local workspace_file = wezterm.home_dir .. "/.config/wezterm-local/local.lua"
local file = io.open(workspace_file, "r")
if file then
  file:close()
  wezterm.add_to_config_reload_watch_list(workspace_file)
  dofile(workspace_file)(wezterm, config)
end

-- ターミナルの文字サイズは13.5を維持する。
config.font_size = 13.5

-- フォント設定。
config.font = wezterm.font_with_fallback {
  "Menlo",
  "BIZ UDGothic",
}

-- 画面のチラつき（一瞬消えたりする）対策
-- 【候補1】描画を「Software」に変更（一番安定します）
-- config.front_end = "Software"

-- 【候補2】Softwareで直らない、または重い場合は「OpenGL」を試す
-- config.front_end = "OpenGL"

-- 【候補3】最新の描画エンジン「WebGpu」を試す
config.front_end = "WebGpu"

return config
