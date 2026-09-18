local wezterm = require 'wezterm'
local config = wezterm.config_builder()

-- 以前の WezTerm 設定から Retro Hacker Blue の配色だけを復元する。
-- キーバインドや Workspace の設定は、移行方針が決まってから追加する。
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

  -- 以前のタブバー配色を復元する。
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

-- Option+Z を ESC+z として送り、zsh 側の zi ウィジェットを呼び出す。
config.keys = {
  {
    key = 'z',
    mods = 'OPT',
    action = wezterm.action.SendString '\x1bz',
  },
}

return config
