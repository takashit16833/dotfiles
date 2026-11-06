local M = {}

-- ワークスペースの切り替え処理は Git 管理し、登録内容はローカル管理する。
function M.setup(wezterm, config, workspaces)
  config.keys = config.keys or {}

  local choices = {}
  for _, workspace in ipairs(workspaces) do
    table.insert(choices, {
      label = workspace.name,
      id = workspace.name,
    })
  end

  -- 登録済みのワークスペースを選択する。選択したときだけ作成する。
  table.insert(config.keys, {
    key = "p",
    mods = "CMD|SHIFT",
    action = wezterm.action.InputSelector({
      title = "Workspace",
      fuzzy = true,
      choices = choices,
      action = wezterm.action_callback(function(window, pane, workspace_name)
        if not workspace_name then
          return
        end

        for _, workspace in ipairs(workspaces) do
          if workspace.name == workspace_name then
            window:perform_action(
              wezterm.action.SwitchToWorkspace({
                name = workspace.name,
                spawn = { cwd = workspace.cwd },
              }),
              pane
            )
            return
          end
        end
      end),
    }),
  })

  -- 個別ショートカットからも同じ方法で切り替える。
  for _, workspace in ipairs(workspaces) do
    if workspace.shortcut then
      table.insert(config.keys, {
        key = workspace.shortcut.key,
        mods = workspace.shortcut.mods,
        action = wezterm.action.SwitchToWorkspace({
          name = workspace.name,
          spawn = { cwd = workspace.cwd },
        }),
      })
    end
  end
end

return M
