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

-- 選択中のタブだけ、暗い青のカプセルに明るい青文字を浮かべる。
local tab_pill_background = "#05233D"
local tab_glow_blue = "#7EE8FF"
local tab_inactive_foreground = "#5B86BC"
local tab_hover_background = "#17264A"
local tab_hover_foreground = "#E0EEFF"

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
  -- タブバーの余白は端末と同色。形状と余白は format-tab-title で指定する。
  tab_bar = {
    background = background,
    active_tab = {
      bg_color = tab_pill_background,
      fg_color = tab_glow_blue,
      intensity = "Bold",
    },
    inactive_tab = {
      bg_color = background,
      fg_color = tab_inactive_foreground,
    },
    inactive_tab_hover = {
      bg_color = tab_hover_background,
      fg_color = tab_hover_foreground,
    },
    inactive_tab_edge = background,
  },
}

-- macOS のタイトルバーを端末の背景に馴染ませる。
config.window_frame = {
  active_titlebar_bg = background,
  inactive_titlebar_bg = background,
  active_titlebar_border_bottom = background,
  inactive_titlebar_border_bottom = background,
}

-- 文字で両端の丸みを描き、選択中だけカプセル型にする。
-- レトロタブの文字サイズには端末の config.font_size が使われる。
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = true
config.hide_tab_bar_if_only_one_tab = true
config.tab_max_width = 32

-- タブの追加ボタン・閉じるボタン・番号を表示しない。
config.show_new_tab_button_in_tab_bar = false
config.show_close_tab_button_in_tabs = false
config.show_tab_index_in_tab_bar = false

-- 標準のタブ名を維持しつつ、アクティブタブだけ青いラベルにする。
wezterm.on("format-tab-title", function(tab, _, _, _, hover, max_width)
  local title = tab.tab_title
  if not title or title == "" then
    title = tab.active_pane.title
  end

  if tab.is_active then
    title = wezterm.truncate_right(title, math.max(1, max_width - 8))
    return {
      { Background = { Color = background } },
      { Text = " " },
      { Foreground = { Color = tab_pill_background } },
      { Text = wezterm.nerdfonts.ple_left_half_circle_thick },
      { Background = { Color = tab_pill_background } },
      { Foreground = { Color = tab_glow_blue } },
      { Attribute = { Intensity = "Bold" } },
      { Text = "  " .. title .. "  " },
      { Background = { Color = background } },
      { Foreground = { Color = tab_pill_background } },
      { Text = wezterm.nerdfonts.ple_right_half_circle_thick },
      { Text = " " },
    }
  end

  -- 非アクティブは従来の配色を維持し、タブ同士に間隔を空ける。
  local tab_background = hover and tab_hover_background or background
  local tab_foreground = hover and tab_hover_foreground or tab_inactive_foreground
  title = wezterm.truncate_right(title, math.max(1, max_width - 4))
  return {
    { Background = { Color = background } },
    { Text = " " },
    { Background = { Color = tab_background } },
    { Foreground = { Color = tab_foreground } },
    { Text = " " .. title .. " " },
    { Background = { Color = background } },
    { Text = " " },
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

-- ターミナルの文字サイズ。
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
