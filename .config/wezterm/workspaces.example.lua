-- このPCで使用するWorkspaceを設定する。
return function(wezterm, config)
  -- 起動時に各プロジェクトのWorkspaceを作成する。
  wezterm.on("gui-startup", function()
    local workspaces = {
      { name = "dotfiles", cwd = wezterm.home_dir .. "/dotfiles" },
      { name = "RAGScope", cwd = wezterm.home_dir .. "/RAGScope/main" },
      { name = "Emacs", cwd = wezterm.home_dir .. "/.emacs.d" },
    }

    for _, workspace in ipairs(workspaces) do
      wezterm.mux.spawn_window {
        workspace = workspace.name,
        cwd = workspace.cwd,
      }
    end

    -- 起動直後はdotfilesを表示する。
    wezterm.mux.set_active_workspace("dotfiles")
  end)

  -- プロジェクトを選び、既存のWorkspaceに切り替える。初回は指定ディレクトリで起動する。
  table.insert(config.keys, {
    key = "p",
    mods = "CMD|SHIFT",
    action = wezterm.action.InputSelector {
      title = "Workspace",
      fuzzy = true,
      choices = {
        { label = "dotfiles", id = wezterm.home_dir .. "/dotfiles" },
        { label = "RAGScope", id = wezterm.home_dir .. "/RAGScope/main" },
        { label = "Emacs", id = wezterm.home_dir .. "/.emacs.d" },
      },
      action = wezterm.action_callback(function(window, pane, cwd, name)
        if not cwd then
          return
        end
        window:perform_action(
          wezterm.action.SwitchToWorkspace {
            name = name,
            spawn = { cwd = cwd },
          },
          pane
        )
      end),
    },
  })

  -- Cmd+Option+q: dotfiles Workspaceに切り替える。
  table.insert(config.keys, {
    key = "q",
    mods = "CMD|ALT",
    action = wezterm.action.SwitchToWorkspace {
      name = "dotfiles",
      spawn = {
        cwd = wezterm.home_dir .. "/dotfiles",
      },
    },
  })
  table.insert(config.keys, {
    key = "l",
    mods = "CMD|ALT",
    action = wezterm.action.SwitchToWorkspace {
      name = "RAGScope",
      spawn = {
        cwd = wezterm.home_dir .. "/RAGScope/main",
      },
    },
  })
  table.insert(config.keys, {
    key = "u",
    mods = "CMD|ALT",
    action = wezterm.action.SwitchToWorkspace {
      name = "Emacs",
      spawn = { cwd = wezterm.home_dir .. "/.emacs.d" },
    },
  })
end
