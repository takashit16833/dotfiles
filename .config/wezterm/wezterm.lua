local wezterm = require 'wezterm'
local act = wezterm.action

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
  -- ペイン分割の仕切り線は VS Code と同じ暗い青にして主張を抑える。
  split = '#00184A',

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

  -- Retro tab bar は Terminal 本体と同じ背景色にして、文字色だけで状態を表現する。
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

-- 元テーマのレトロな雰囲気と、単純なタブ表示を優先して Retro tab bar を使う。
config.use_fancy_tab_bar = false

-- タブ追加はキーボード操作を前提にし、常設の + ボタンを消してタブバーをすっきりさせる。
config.show_new_tab_button_in_tab_bar = false

-- タブは Terminal 上部を圧迫しないよう、画面下部へ配置する。
-- macOS のタイトルバーとタブバーを分離することで、ウィンドウ操作ボタンは上部に残す。
config.tab_bar_at_bottom = true

-- Nightly 限定機能を使い、macOS 標準タイトルバーの背景色を
-- Terminal の background と同じ色にする。
-- TITLE と RESIZE は残すため、macOS 標準のウィンドウ操作とリサイズはそのまま利用できる。
config.window_decorations =
  'TITLE|RESIZE|MACOS_USE_BACKGROUND_COLOR_AS_TITLEBAR_COLOR'

-- Terminal の基本フォントサイズ。
config.font_size = 13.5

-- macOS 固有の Cmd / Option ショートカットは、標準的な Emacs 系キーへ変換するだけにする。
-- 行編集の意味は zsh 側に持たせ、Terminal を乗り換えたときの修正範囲をここに限定する。
--
-- Cmd + Left / Right      -> Ctrl-A / Ctrl-E
-- Cmd + Backspace / Delete -> Meta-Ctrl-U / Ctrl-K
-- Option + Left / Right   -> Meta-B / Meta-F
-- Option + Backspace / Delete -> Meta-Backspace / Meta-D
--
-- Option + Z / G は zsh 側の zi / lazygit widget 用に ESC sequence へ変換する。
config.keys = {
  {
    key = 'LeftArrow',
    mods = 'CMD',
    action = act.SendKey { key = 'a', mods = 'CTRL' },
  },
  {
    key = 'RightArrow',
    mods = 'CMD',
    action = act.SendKey { key = 'e', mods = 'CTRL' },
  },
  {
    key = 'Backspace',
    mods = 'CMD',
    action = act.SendKey { key = 'u', mods = 'CTRL|ALT' },
  },
  {
    key = 'Delete',
    mods = 'CMD',
    action = act.SendKey { key = 'k', mods = 'CTRL' },
  },
  {
    key = 'LeftArrow',
    mods = 'OPT',
    action = act.SendKey { key = 'b', mods = 'ALT' },
  },
  {
    key = 'RightArrow',
    mods = 'OPT',
    action = act.SendKey { key = 'f', mods = 'ALT' },
  },
  {
    key = 'Backspace',
    mods = 'OPT',
    action = act.SendKey { key = 'Backspace', mods = 'ALT' },
  },
  {
    key = 'Delete',
    mods = 'OPT',
    action = act.SendKey { key = 'd', mods = 'ALT' },
  },
  {
    key = 'z',
    mods = 'OPT',
    action = act.SendString '\x1bz',
  },
  {
    key = 'g',
    mods = 'OPT',
    action = act.SendString '\x1bg',
  },
}

return config
