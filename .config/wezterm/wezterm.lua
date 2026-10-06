local wezterm = require "wezterm"
local config = wezterm.config_builder()

-- Kitty Keyboard Protocolを利用可能にする。
-- Lem側がKKPを有効化すると、Cmd/Option/Shiftなどの修飾キーを区別して受け取れる。
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
local tab_inactive_background = "#00091F"
local tab_inactive_foreground = "#20467B"

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

  if not title or title == "" then
    local process_name = tab.active_pane.foreground_process_name

    if process_name and process_name ~= "" then
      title = process_name:match("([^/]+)$") or process_name
    else
      title = "shell"
    end
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
--
-- LemではKitty Keyboard Protocolを使うため、通常の修飾キーはWezTerm側で
-- 個別に変換しない。以下はWezTerm自身のデフォルト操作と衝突するキー、
-- または実機確認でWezTermが修飾情報を失うことを確認したキーだけを扱う。
-- 2026-10-04にWezTerm + Lem(ncurses)で一つずつ外して確認済み。
config.keys = {
  -- Deleteはこの指定を外すとLemでBackspaceとして認識されるため明示的に送る。
  { key = "Delete", action = wezterm.action.SendKey { key = "Delete" } },

  -- WezTermのデフォルト割り当てを無効化してLemへ渡す。
  -- これらは指定を外すとLem側でキー入力を検出できなかった。
  {
    key = "Tab",
    mods = "CTRL",
    action = wezterm.action.DisableDefaultAssignment,
  },
  {
    key = "Tab",
    mods = "CTRL|SHIFT",
    action = wezterm.action.DisableDefaultAssignment,
  },
  {
    key = "PageUp",
    mods = "CTRL",
    action = wezterm.action.DisableDefaultAssignment,
  },
  {
    key = "PageDown",
    mods = "CTRL",
    action = wezterm.action.DisableDefaultAssignment,
  },
  {
    key = "PageUp",
    mods = "CTRL|SHIFT",
    action = wezterm.action.DisableDefaultAssignment,
  },
  {
    key = "PageDown",
    mods = "CTRL|SHIFT",
    action = wezterm.action.DisableDefaultAssignment,
  },
  {
    key = "r",
    mods = "CMD",
    action = wezterm.action.DisableDefaultAssignment,
  },

  -- Cmd+FはWezTermの検索に割り当てられているため、無効化してLemへ渡す。
  {
    key = "f",
    mods = "CMD",
    action = wezterm.action.DisableDefaultAssignment,
  },

  -- Cmd+CはWezTermの選択範囲があるときだけOSクリップボードへコピーする。
  -- 未選択時はLemへCmd+Cを渡したいが、このcallback内でSendKey(CMD+c)を使うと
  -- Cmd修飾が失われて単なる"c"になることを実機確認済み。
  -- そのため未選択時だけKKPのCmd+C (CSI 99;9u) を直接送る。
  {
    key = "c",
    mods = "CMD",
    action = wezterm.action_callback(function(window, pane)
      local selection = window:get_selection_text_for_pane(pane)

      if selection ~= "" then
        window:perform_action(wezterm.action.CopyTo "Clipboard", pane)
        window:perform_action(wezterm.action.ClearSelection, pane)
      else
        window:perform_action(wezterm.action.SendString "\x1b[99;9u", pane)
      end
    end),
  },

  -- zsh/ZLE向けのCmdキー互換処理。
  -- zsh/ZLEはKKPを解釈しないため、KKPを有効化せずに使う。
  -- その状態ではCmd+左右は通常の左右キーと同じ入力になり、Cmd修飾を区別できない。
  -- そこでCmd+左右とCmd+Backspaceだけ、Cmd修飾を保持できるシーケンスへ変換する。
  -- zsh側の対応するbindkeyとセットで使用するため、片側だけ削除しないこと。
  -- Lemはこれらのシーケンスも正しく解釈できるため、Lem利用時にもそのまま使える。
  {
    key = "LeftArrow",
    mods = "CMD",
    action = wezterm.action.SendString "\x1b[1;9D",
  },
  {
    key = "RightArrow",
    mods = "CMD",
    action = wezterm.action.SendString "\x1b[1;9C",
  },
  {
    key = "Backspace",
    mods = "CMD",
    action = wezterm.action.SendString "\x1b[127;9u",
  },

  -- Cmd+Option+左右はLemへ渡さず、WezTermのタブ移動として使う。
  {
    key = "LeftArrow",
    mods = "CMD|ALT",
    action = wezterm.action.ActivateTabRelative(-1),
  },
  {
    key = "RightArrow",
    mods = "CMD|ALT",
    action = wezterm.action.ActivateTabRelative(1),
  },

  -- WezTerm互換処理。
  -- KKP flag 1を有効にした状態でも、Cmd+Shift+K/Z/F/Mは実機で
  -- それぞれ bare "k"/"z"/"f"/"m" として出力され、Cmd/Shiftが失われた。
  -- そのためこの3キーだけ正しいKKP CSI-uシーケンスを直接送る。
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
  {
    key = "phys:F",
    mods = "CMD|SHIFT",
    action = wezterm.action.SendString "\x1b[102;10u",
  },
  {
    key = "phys:M",
    mods = "CMD|SHIFT",
    action = wezterm.action.SendString "\x1b[109;10u",
  },

  -- Cmd+TはLemへ渡さず、WezTermのタブ操作メニューとして使う。
  {
    key = "t",
    mods = "CMD",
    action = wezterm.action.ActivateKeyTable {
      name = "tab_actions",
      one_shot = false,
      until_unknown = true,
    },
  },

  -- Cmd+VでOSのクリップボードを前面の端末アプリへ貼り付ける。
  -- bracketed pasteに対応したEmacsなどでは、通常のペーストとして処理される。
  {
    key = "v",
    mods = "CMD",
    action = wezterm.action.PasteFrom "Clipboard",
  },
}

-- タブ操作。
config.key_tables = {
  tab_actions = {
    -- Shift+左右でタブの並び順を変更する。
    {
      key = "LeftArrow",
      mods = "SHIFT",
      action = wezterm.action.MoveTabRelative(-1),
    },
    {
      key = "RightArrow",
      mods = "SHIFT",
      action = wezterm.action.MoveTabRelative(1),
    },
    -- 現在のペインの縦横比に合わせて、長い辺を分ける方向へ分割する。
    {
      key = "s",
      action = wezterm.action_callback(function(window, pane)
        local pane_width
        local pane_height

        for _, pane_info in ipairs(window:active_tab():panes_with_info()) do
          if pane_info.is_active then
            pane_width = pane_info.pixel_width
            pane_height = pane_info.pixel_height
            break
          end
        end

        window:perform_action(wezterm.action.PopKeyTable, pane)

        if not pane_width or not pane_height then
          wezterm.log_error "Could not determine active pane dimensions"
          return
        end

        local direction = pane_height > pane_width and "Down" or "Right"
        window:perform_action(
          wezterm.action.SplitPane {
            direction = direction,
            size = { Percent = 50 },
          },
          pane
        )
      end),
    },
    -- 新しいタブを開いて終了する。
    {
      key = "t",
      action = wezterm.action.Multiple {
        wezterm.action.PopKeyTable,
        wezterm.action.SpawnTab "CurrentPaneDomain",
      },
    },
    -- 現在のタブの名前を変更して終了する。
    {
      key = "r",
      action = wezterm.action.Multiple {
        wezterm.action.PopKeyTable,
        wezterm.action.PromptInputLine {
          description = "新しいタブ名:",
          action = wezterm.action_callback(function(window, pane, line)
            if line and line ~= "" then
              window:active_tab():set_title(line)
            end
          end),
        },
      },
    },
    -- 操作をキャンセルする。
    {
      key = "Escape",
      action = wezterm.action.PopKeyTable,
    },
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

-- コピーモードの移動キー。
local act = wezterm.action

config.key_tables = config.key_tables or {}
config.key_tables.copy_mode = config.key_tables.copy_mode or wezterm.gui.default_key_tables().copy_mode

local copy_mode_keys = {
  { key = "LeftArrow", mods = "SUPER", action = act.CopyMode "MoveToStartOfLine" },
  { key = "RightArrow", mods = "SUPER", action = act.CopyMode "MoveToEndOfLineContent" },
  { key = "UpArrow", mods = "SUPER", action = act.CopyMode "MoveToViewportTop" },
  { key = "DownArrow", mods = "SUPER", action = act.CopyMode "MoveToViewportBottom" },
}

for _, binding in ipairs(copy_mode_keys) do
  table.insert(config.key_tables.copy_mode, binding)
end

-- ターミナルの文字サイズは13.5を維持する。
config.font_size = 13.5

-- フォント設定。
config.font = wezterm.font_with_fallback {
  "Menlo",
  "BIZ UDGothic",
}

-- カーソルスタイル
config.default_cursor_style = "BlinkingBar"
config.cursor_thickness = "2px"

-- 画面のチラつき（一瞬消えたりする）対策
-- 【候補1】描画を「Software」に変更（一番安定します）
-- config.front_end = "Software"

-- 【候補2】Softwareで直らない、または重い場合は「OpenGL」を試す
-- config.front_end = "OpenGL"

-- 【候補3】最新の描画エンジン「WebGpu」を試す
config.front_end = "WebGpu"

return config
