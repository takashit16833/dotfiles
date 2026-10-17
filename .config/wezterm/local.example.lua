return function(wezterm, config)
  -- wezterm-local配下のLuaファイルをrequireできるようにする。
  local local_dir = wezterm.home_dir .. "/.config/wezterm-local"

  package.path = local_dir .. "/?.lua;" .. local_dir .. "/?/init.lua;" .. package.path

  local workspaces = require("modules.workspaces")(wezterm)
  local background = require("modules.background")

  -- 背景画像を有効にする。
  local enable_background = true

  config.text_background_opacity = 0.5

  -- 背景画像を設定する。
  background.setup(wezterm, config, workspaces, enable_background)

  -- 起動時に各Workspaceを作成する。
  wezterm.on("gui-startup", function()
    for _, workspace in ipairs(workspaces) do
      wezterm.mux.spawn_window({
        workspace = workspace.name,
        cwd = workspace.cwd,
      })
    end

    -- 起動直後に先頭のWorkspaceを表示する。
    wezterm.mux.set_active_workspace(workspaces[1].name)
  end)

  config.keys = config.keys or {}

  -- プロジェクトを選び、既存のWorkspaceに切り替える。
  -- Workspaceが存在しない場合は指定ディレクトリで作成する。
  table.insert(config.keys, {
    key = "p",
    mods = "CMD|SHIFT",
    action = wezterm.action.InputSelector({
      title = "Workspace",
      fuzzy = true,

      choices = (function()
        local choices = {}

        for _, workspace in ipairs(workspaces) do
          table.insert(choices, {
            label = workspace.name,
            id = workspace.name,
          })
        end

        return choices
      end)(),

      action = wezterm.action_callback(function(window, pane, workspace_name)
        if not workspace_name then
          return
        end

        for _, workspace in ipairs(workspaces) do
          if workspace.name == workspace_name then
            window:perform_action(
              wezterm.action.SwitchToWorkspace({
                name = workspace.name,
                spawn = {
                  cwd = workspace.cwd,
                },
              }),
              pane
            )

            return
          end
        end
      end),
    }),
  })

  -- Workspaceごとのショートカットを登録する。
  for _, workspace in ipairs(workspaces) do
    if workspace.shortcut then
      table.insert(config.keys, {
        key = workspace.shortcut.key,
        mods = workspace.shortcut.mods,

        action = wezterm.action.SwitchToWorkspace({
          name = workspace.name,
          spawn = {
            cwd = workspace.cwd,
          },
        }),
      })
    end
  end
end
