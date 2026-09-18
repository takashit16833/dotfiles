local wezterm = require 'wezterm'
local config = wezterm.config_builder()

-- Retro Hacker Blue の基本色。
local background = '#010111'
local foreground = '#5EAFFF'
local cyber_pink = '#FF4DE1'

config.colors = {
  foreground = foreground,
  background = background,

  -- カーソルは Cyber Pink。
  cursor_bg = cyber_pink,
  cursor_fg = background,
  cursor_border = cyber_pink,

  selection_fg = '#FFFFFF',
  selection_bg = 'rgba(23, 51, 102, 0.70)',
  scrollbar_thumb = '#2759AA',
  split = '#00184A',

  ansi = {
    '#000000',
    cyber_pink,
    '#4682B4',
    '#FFD700',
    '#3B85D8',
    '#8A5EC0',
    '#00CED1',
    '#E0EEFF',
  },
  brights = {
    '#1A1A1A',
    cyber_pink,
    '#6CB8F0',
    '#FFFF00',
    foreground,
    '#B07CFF',
    '#00FFFF',
    '#FFFFFF',
  },

  -- タブバーは背景色を揃え、文字色で状態を区別する。
  tab_bar = {
    background = background,
    active_tab = {
      bg_color = background,
      fg_color = cyber_pink,
      intensity = 'Bold',
    },
    inactive_tab = {
      bg_color = background,
      fg_color = '#4C9EEB',
    },
    inactive_tab_hover = {
      bg_color = background,
      fg_color = foreground,
    },
  },
}

-- 上記のタブバー配色を使用するため、シンプルなタブバーを選ぶ。
config.use_fancy_tab_bar = false

-- Nightly 限定: macOS 標準タイトルバーを残し、背景色をターミナルと揃える。
config.window_decorations = 'TITLE|RESIZE|MACOS_USE_BACKGROUND_COLOR_AS_TITLEBAR_COLOR'

-- macOS の修飾キーを Emacs / zsh で使う ESC シーケンスへ変換する。
-- Cmd+Z / Cmd+Shift+Z は Emacs 側の M-z / M-Z（Undo / Redo）に対応する。
config.keys = {
  {
    key = 'z',
    mods = 'OPT',
    action = wezterm.action.SendString '\x1bz',
  },
  {
    key = 'z',
    mods = 'CMD',
    action = wezterm.action.SendString '\x1bz',
  },
  {
    key = 'z',
    mods = 'CMD|SHIFT',
    action = wezterm.action.SendString '\x1bZ',
  },
  -- Option+X で Emacs の M-x を実行する。
  {
    key = 'x',
    mods = 'OPT',
    action = wezterm.action.SendString '\x1bx',
  },
}

-- ターミナルの文字サイズ。
config.font_size = 13.5

-- フォント設定。
config.font = wezterm.font_with_fallback {
  'Menlo',
  'BIZ UDGothic',
}

return config
