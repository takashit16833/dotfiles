local wezterm = require 'wezterm'

local config = wezterm.config_builder()

-- Retro Hacker Blue
-- Based on:
-- https://github.com/elmersh/retro-hacker-theme/blob/main/themes/retro-hacker-blue-theme.json
--
-- The original red accents and cursor color are replaced with cyber pink.
local cyber_pink = '#FF4DE1'

config.colors = {
  foreground = '#5EAFFF',
  background = '#010111',

  cursor_bg = cyber_pink,
  cursor_fg = '#010111',
  cursor_border = cyber_pink,

  selection_fg = '#FFFFFF',
  selection_bg = 'rgba(23, 51, 102, 0.70)',

  scrollbar_thumb = '#2759AA',
  split = '#5EAFFF',

  ansi = {
    '#000000', -- black
    cyber_pink, -- red
    '#4682B4', -- green
    '#FFD700', -- yellow
    '#3B85D8', -- blue
    '#8A5EC0', -- magenta
    '#00CED1', -- cyan
    '#E0EEFF', -- white
  },

  brights = {
    '#1A1A1A', -- bright black
    cyber_pink, -- bright red
    '#6CB8F0', -- bright green
    '#FFFF00', -- bright yellow
    '#5EAFFF', -- bright blue
    '#B07CFF', -- bright magenta
    '#00FFFF', -- bright cyan
    '#FFFFFF', -- bright white
  },

  tab_bar = {
    background = '#010114',

    active_tab = {
      bg_color = '#010111',
      fg_color = '#5EAFFF',
      intensity = 'Bold',
    },

    inactive_tab = {
      bg_color = '#000E2F',
      fg_color = '#4C9EEB',
    },

    inactive_tab_hover = {
      bg_color = '#000040',
      fg_color = '#5EAFFF',
    },

    new_tab = {
      bg_color = '#010114',
      fg_color = '#4C9EEB',
    },

    new_tab_hover = {
      bg_color = '#000040',
      fg_color = cyber_pink,
    },
  },
}

-- The retro tab bar matches the source theme more closely and keeps the UI simple.
config.use_fancy_tab_bar = false

return config
