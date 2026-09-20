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
  -- タブバーは背景色を揃え、文字色で状態を区別する。
  tab_bar = {
    background = background,

    active_tab = {
      bg_color = "#287FD9",
      fg_color = background,
      intensity = "Bold",
    },

    inactive_tab = {
      bg_color = "#174A9C",
      fg_color = "#E0EEFF",
    },

    inactive_tab_hover = {
      bg_color = "#3B85D8",
      fg_color = background,
    },
  },
  -- タブの配色。
  tab_bar = {
    background = background,

    -- アクティブ: 濃紺の背景と明るい文字。
    active_tab = {
      bg_color = "#111D39",
      fg_color = "#E0EEFF",
      intensity = "Bold",
    },

    -- 非アクティブ: 背景に溶け込ませる。
    inactive_tab = {
      bg_color = background,
      fg_color = "#5B86BC",
    },

    -- マウスを重ねたときだけ少し明るくする。
    inactive_tab_hover = {
      bg_color = "#17264A",
      fg_color = "#E0EEFF",
    },

    -- タブ間の境界線を背景に溶け込ませる。
    inactive_tab_edge = background,
  },
}

-- タブバー全体の背景とフォント。
config.window_frame = {
  active_titlebar_bg = background,
  inactive_titlebar_bg = background,
  font = wezterm.font("Menlo"),
  font_size = 13.0,
}

-- タブバーは2つ以上のタブがあるときだけ表示する。
config.use_fancy_tab_bar = true
config.hide_tab_bar_if_only_one_tab = true

-- タブの追加ボタン・閉じるボタン・番号を表示しない。
config.show_new_tab_button_in_tab_bar = false
config.show_close_tab_button_in_tabs = false
config.show_tab_index_in_tab_bar = false

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

return config
