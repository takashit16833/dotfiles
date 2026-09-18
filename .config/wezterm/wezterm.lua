local wezterm = require 'wezterm'
local config = wezterm.config_builder()

-- 修飾キーを端末内のアプリへ伝える。
config.enable_kitty_keyboard = true

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
      bg_color = '#287FD9',
      fg_color = background,
    },

    inactive_tab = {
      bg_color = '#174A9C',
      fg_color = '#E0EEFF',
    },

    inactive_tab_hover = {
      bg_color = '#3B85D8',
      fg_color = background,
    },
  },
  -- タブの配色。
  tab_bar = {
    background = background,

    -- アクティブ: 濃紺の背景と明るい文字。
    active_tab = {
      bg_color = '#111D39',
      fg_color = '#E0EEFF',
      intensity = 'Bold',
    },

    -- 非アクティブ: 背景に溶け込ませる。
    inactive_tab = {
      bg_color = background,
      fg_color = '#5B86BC',
    },

    -- マウスを重ねたときだけ少し明るくする。
    inactive_tab_hover = {
      bg_color = '#17264A',
      fg_color = '#E0EEFF',
    },

    -- タブ間の境界線を背景に溶け込ませる。
    inactive_tab_edge = background,
  },
}

-- タブバー全体の背景とフォント。
config.window_frame = {
  active_titlebar_bg = background,
  inactive_titlebar_bg = background,
  font = wezterm.font('Menlo'),
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
config.window_decorations = 'TITLE|RESIZE|MACOS_USE_BACKGROUND_COLOR_AS_TITLEBAR_COLOR'

-- Workspace 名をタイトルバーに表示する。
wezterm.on('format-window-title', function()
  return wezterm.mux.get_active_workspace()
end)

-- 起動時に各プロジェクトの Workspace を作成する。
wezterm.on('gui-startup', function()
  local workspaces = {
    { name = 'dotfiles', cwd = wezterm.home_dir .. '/dotfiles' },
    { name = 'RAGScope', cwd = wezterm.home_dir .. '/RAGScope/main' },
    { name = 'Emacs', cwd = wezterm.home_dir .. '/.emacs.d' },
  }

  for _, workspace in ipairs(workspaces) do
    wezterm.mux.spawn_window {
      workspace = workspace.name,
      cwd = workspace.cwd,
    }
  end

  -- 起動直後は dotfiles を表示する。
  wezterm.mux.set_active_workspace('dotfiles')
end)

-- WezTerm自身のWorkspace操作だけを割り当てる。
config.keys = {
  -- プロジェクトを選び、既存の Workspace に切り替える。初回は指定ディレクトリで起動する。
  {
    key = 'p',
    mods = 'CMD|SHIFT',
    action = wezterm.action.InputSelector {
      title = 'Workspace',
      fuzzy = true,
      choices = {
        { label = 'dotfiles', id = wezterm.home_dir .. '/dotfiles' },
        { label = 'RAGScope', id = wezterm.home_dir .. '/RAGScope/main' },
        { label = 'Emacs', id = wezterm.home_dir .. '/.emacs.d' },
      },
      action = wezterm.action_callback(function(window, pane, cwd, name)
        if not cwd then
          return
        end
        window:perform_action(wezterm.action.SwitchToWorkspace {
          name = name,
          spawn = { cwd = cwd },
        }, pane)
      end),
    },
  },
  -- Cmd+Option+q: dotfiles Workspace に切り替える。
  {
    key = 'q',
    mods = 'CMD|ALT',
    action = wezterm.action.SwitchToWorkspace {
      name = 'dotfiles',
      spawn = {
        cwd = wezterm.home_dir .. '/dotfiles',
      },
    },
  },
  {
    key = 'l',
    mods = 'CMD|ALT',
    action = wezterm.action.SwitchToWorkspace {
      name = 'RAGScope',
      spawn = {
        cwd = wezterm.home_dir .. '/RAGScope/main',
      },
    },
  },
  {
    key = 'u',
    mods = 'CMD|ALT',
    action = wezterm.action.SwitchToWorkspace {
      name = 'Emacs',
      spawn = {
        cwd = wezterm.home_dir .. '/.emacs.d',
      },
    },
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
