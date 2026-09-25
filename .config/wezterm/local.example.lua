-- このPCで使用するWorkspaceを設定する。
return function(wezterm, config)
  -- 背景の透過率（1.0 = 不透明、0.0 = 完全透明）
  -- config.window_background_opacity = 0.9
  -- config.macos_window_background_blur = 30

  -- 背景画像を有効にする。
  local enable_background = true

  -- 背景画像の共通設定。
  local background_defaults = {
    horizontal_align = "Center",
    vertical_align = "Middle",
    repeat_x = "NoRepeat",
    repeat_y = "NoRepeat",
    hsb = {
      brightness = 0.012,
    },
  }

  -- Workspaceごとに背景画像と個別設定を指定する。
  local workspace_backgrounds = {
    Default = {
      common = {},
      landscape = {
        file = wezterm.home_dir .. "/path/to/file1.png",
        hsb = {
          brightness = 0.025,
        },
      },
      portrait = {
        file = wezterm.home_dir .. "/path/to/file2.png",
        hsb = {
          brightness = 0.025,
        },
      },
    },
    RAGScope = {
      common = {},
      landscape = {
        file = wezterm.home_dir .. "/path/to/file3.png",
        hsb = {
          brightness = 0.025,
        },
      },
      portrait = {
        file = wezterm.home_dir .. "/path/to/file4.png",
        hsb = {
          brightness = 0.025,
        },
      },
    },
  }

  -- 共通設定をコピーし、個別設定で上書きする。
  local function merge(defaults, custom)
    local result = {}

    for key, value in pairs(defaults or {}) do
      result[key] = value
    end

    for key, value in pairs(custom or {}) do
      result[key] = value
    end

    return result
  end

  -- Workspaceとウィンドウ比率に対応した背景を作成する。
  local function make_background(workspace, portrait)
    local settings = workspace_backgrounds[workspace] or workspace_backgrounds.Default

    local common = settings.common or {}
    local variant = (portrait and settings.portrait) or settings.landscape or {}

    local image = merge(background_defaults, common)
    image = merge(image, variant)

    -- hsbも共通設定から個別設定へ順番に上書きする。
    image.hsb = merge(background_defaults.hsb, common.hsb)
    image.hsb = merge(image.hsb, variant.hsb)

    image.source = { File = variant.file }

    -- 縦横比を保って画面全体を覆い、はみ出した部分を切り取る。
    image.width = "Cover"
    image.height = "Cover"

    -- 背景レイヤーに不要な項目を取り除く。
    image.file = nil

    return {
      {
        source = { Color = "#010111" },
        width = "100%",
        height = "100%",
      },
      image,
    }
  end

  -- 設定内容が同じか確認する。
  local function same(a, b)
    if type(a) ~= type(b) then
      return false
    end

    if type(a) ~= "table" then
      return a == b
    end

    for key, value in pairs(a) do
      if not same(value, b[key]) then
        return false
      end
    end

    for key in pairs(b) do
      if a[key] == nil then
        return false
      end
    end

    return true
  end

  -- 起動時はDefaultの横長用背景を使用する。
  config.background = enable_background and make_background("Default", false) or nil

  -- Workspaceとウィンドウ比率に合わせて背景を更新する。
  local function update_background(window)
    local overrides = window:get_config_overrides() or {}

    -- 無効時はウィンドウに残っている背景設定も解除する。
    if not enable_background then
      if overrides.background ~= nil then
        overrides.background = nil
        window:set_config_overrides(overrides)
      end
      return
    end

    local dimensions = window:get_dimensions()

    -- 正方形も縦長用画像として扱う。
    local portrait = dimensions.pixel_width <= dimensions.pixel_height

    local background = make_background(window:active_workspace(), portrait)

    local current = overrides.background or config.background

    if same(current, background) then
      return
    end

    overrides.background = background
    window:set_config_overrides(overrides)
  end

  -- Workspaceの変更とウィンドウのリサイズに対応する。
  wezterm.on("update-status", update_background)
  wezterm.on("window-resized", update_background)

  local default_dir = "/"
  local ragscope_dir = "/RAGScope/RS-0024"

  -- 起動時に各プロジェクトのWorkspaceを作成する。
  wezterm.on("gui-startup", function()
    local workspaces = {
      { name = "Default", cwd = wezterm.home_dir .. default_dir },
      { name = "RAGScope", cwd = wezterm.home_dir .. ragscope_dir },
    }

    for _, workspace in ipairs(workspaces) do
      wezterm.mux.spawn_window({
        workspace = workspace.name,
        cwd = workspace.cwd,
      })
    end

    -- 起動直後の表示。
    wezterm.mux.set_active_workspace("Default")
  end)

  -- プロジェクトを選び、既存のWorkspaceに切り替える。
  -- 初回は指定ディレクトリで起動する。
  table.insert(config.keys, {
    key = "p",
    mods = "CMD|SHIFT",
    action = wezterm.action.InputSelector({
      title = "Workspace",
      fuzzy = true,
      choices = {
        { label = "Default", id = wezterm.home_dir .. default_dir },
        { label = "RAGScope", id = wezterm.home_dir .. ragscope_dir },
      },
      action = wezterm.action_callback(function(window, pane, cwd, name)
        if not cwd then
          return
        end

        window:perform_action(
          wezterm.action.SwitchToWorkspace({
            name = name,
            spawn = { cwd = cwd },
          }),
          pane
        )
      end),
    }),
  })

  -- Workspaceを切り替える。
  table.insert(config.keys, {
    key = "t",
    mods = "CMD|ALT",
    action = wezterm.action.SwitchToWorkspace({
      name = "Default",
      spawn = {
        cwd = wezterm.home_dir .. default_dir,
      },
    }),
  })

  table.insert(config.keys, {
    key = "n",
    mods = "CMD|ALT",
    action = wezterm.action.SwitchToWorkspace({
      name = "RAGScope",
      spawn = {
        cwd = wezterm.home_dir .. ragscope_dir,
      },
    }),
  })
end
