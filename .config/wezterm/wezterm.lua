local wezterm = require 'wezterm'

-- config_builder を使うと、未知の設定キーなどを WezTerm が検出しやすくなる。
local config = wezterm.config_builder()

-- Retro Hacker Blue をベースにした共通色。
-- 元テーマ:
-- https://github.com/elmersh/retro-hacker-theme/blob/main/themes/retro-hacker-blue-theme.json
local background = '#010111'
local foreground = '#5EAFFF'

-- 元テーマの赤系アクセントとカーソル色は Cyber Pink に置き換える。
local cyber_pink = '#FF4DE1'

-- Terminal 本体、ANSI 16 色、カーソル、選択範囲、タブの配色。
config.colors = {
  foreground = foreground,
  background = background,

  -- カーソルはテーマ内で目立つ Cyber Pink に統一する。
  cursor_bg = cyber_pink,
  cursor_fg = background,
  cursor_border = cyber_pink,

  -- 選択範囲は青系を保ちつつ、文字が読みやすい程度にコントラストを付ける。
  selection_fg = '#FFFFFF',
  selection_bg = 'rgba(23, 51, 102, 0.70)',

  scrollbar_thumb = '#2759AA',
  split = foreground,

  -- 通常の ANSI 8 色。red だけ Cyber Pink に差し替える。
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

  -- Bright ANSI 8 色。bright red も Cyber Pink に統一する。
  brights = {
    '#1A1A1A', -- bright black
    cyber_pink, -- bright red
    '#6CB8F0', -- bright green
    '#FFFF00', -- bright yellow
    foreground, -- bright blue
    '#B07CFF', -- bright magenta
    '#00FFFF', -- bright cyan
    '#FFFFFF', -- bright white
  },

  -- Retro tab bar の配色。
  -- タブバー全体の背景を Terminal 本体と同じ色にし、上端を一体化して見せる。
  tab_bar = {
    background = background,

    active_tab = {
      bg_color = background,
      fg_color = foreground,
      intensity = 'Bold',
    },

    inactive_tab = {
      bg_color = '#000E2F',
      fg_color = '#4C9EEB',
    },

    inactive_tab_hover = {
      bg_color = '#000040',
      fg_color = foreground,
    },

    new_tab = {
      bg_color = background,
      fg_color = '#4C9EEB',
    },

    new_tab_hover = {
      bg_color = '#000040',
      fg_color = cyber_pink,
    },
  },
}

-- 元テーマのレトロな雰囲気と、単純なタブ表示を優先して Retro tab bar を使う。
config.use_fancy_tab_bar = false

-- macOS の独立したタイトルバーをなくし、ウィンドウ操作ボタンをタブバーへ統合する。
-- これにより、タイトルバー相当の領域も Terminal と同じ background 色になる。
-- RESIZE は残しているため、通常どおりウィンドウサイズを変更できる。
config.window_decorations = 'INTEGRATED_BUTTONS|RESIZE'
config.integrated_title_button_style = 'MacOsNative'
config.integrated_title_button_alignment = 'Left'

return config
