-- 初回インストール時に ~/.config/wezterm-local/workspaces.lua へコピーされる。
-- 以後はコピー先を編集する。ワークスペースは選択時に作成される。
return {
  {
    name = "default",
    cwd = os.getenv("HOME"),
    shortcut = { key = "t", mods = "CMD|ALT" },
  },

  -- 必要なワークスペースをここに追加する。
  -- {
  --   name = "Project",
  --   cwd = os.getenv("HOME") .. "/workspace/project",
  --   shortcut = { key = "n", mods = "CMD|ALT" },
  --   background = {
  --     landscape = {
  --       file = os.getenv("HOME") .. "/Pictures/wallpaper-wide.jpg",
  --       hsb = { brightness = 0.02 },
  --     },
  --     portrait = {
  --       file = os.getenv("HOME") .. "/Pictures/wallpaper-tall.jpg",
  --       hsb = { brightness = 0.02 },
  --     },
  --   },
  -- },
}
