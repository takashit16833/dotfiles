local M = {}

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

-- テーブルをコピーし、後から指定された値で上書きする。
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

-- 二つの設定内容が同じか確認する。
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

-- Workspace名から設定を取得する。
-- 見つからない場合は先頭のWorkspaceを使用する。
local function find_workspace(workspaces, name)
  for _, workspace in ipairs(workspaces) do
    if workspace.name == name then
      return workspace
    end
  end

  return workspaces[1]
end

-- Workspaceとウィンドウ比率に対応した背景を作成する。
local function make_background(workspaces, workspace_name, portrait)
  local workspace = find_workspace(workspaces, workspace_name)

  local settings = workspace.background

  if not settings then
    return nil
  end

  local common = settings.common or {}

  local variant

  if portrait then
    variant = settings.portrait
  else
    variant = settings.landscape
  end

  if not variant then
    return nil
  end

  local image = merge(background_defaults, common)

  image = merge(image, variant)

  -- hsbは別途マージする。
  image.hsb = merge(background_defaults.hsb, common.hsb)

  image.hsb = merge(image.hsb, variant.hsb)

  image.source = {
    File = variant.file,
  }

  -- 縦横比を保って画面全体を覆い、
  -- はみ出した部分を切り取る。
  image.width = "Cover"
  image.height = "Cover"

  -- WezTermのbackground設定には不要。
  image.file = nil

  return {
    {
      source = {
        Color = "#010111",
      },

      width = "100%",
      height = "100%",
    },

    image,
  }
end

function M.setup(wezterm, config, workspaces, enabled)
  -- 起動時は先頭Workspaceの横長用背景を使用する。
  config.background = enabled and make_background(workspaces, workspaces[1].name, false) or nil

  -- Workspaceとウィンドウ比率に合わせて背景を更新する。
  local function update_background(window)
    local overrides = window:get_config_overrides() or {}

    -- 背景無効時は、
    -- ウィンドウに残っている背景設定も解除する。
    if not enabled then
      if overrides.background ~= nil then
        overrides.background = nil
        window:set_config_overrides(overrides)
      end

      return
    end

    local dimensions = window:get_dimensions()

    -- 正方形も縦長用画像として扱う。
    local portrait = dimensions.pixel_width <= dimensions.pixel_height

    local background = make_background(workspaces, window:active_workspace(), portrait)

    local current = overrides.background or config.background

    if same(current, background) then
      return
    end

    overrides.background = background
    window:set_config_overrides(overrides)
  end

  -- Workspace変更に対応する。
  wezterm.on("update-status", update_background)

  -- ウィンドウのリサイズに対応する。
  wezterm.on("window-resized", update_background)
end

return M
