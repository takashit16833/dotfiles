return function(wezterm)
  return {
    {
      name = "Default",
      cwd = wezterm.home_dir .. "/",

      shortcut = {
        key = "t",
        mods = "CMD|ALT",
      },

      background = {
        landscape = {
          file = wezterm.home_dir .. "/Desktop/warehouse/wall/11.png",

          hsb = {
            brightness = 0.02,
          },
        },

        portrait = {
          file = wezterm.home_dir .. "/Desktop/warehouse/wall/10.png",

          hsb = {
            brightness = 0.02,
          },
        },
      },
    },

    {
      name = "RAGScope",
      cwd = wezterm.home_dir .. "/RAGScope/RS-0024",

      shortcut = {
        key = "n",
        mods = "CMD|ALT",
      },

      background = {
        landscape = {
          file = wezterm.home_dir .. "/Desktop/warehouse/wall/1.jpg",

          hsb = {
            brightness = 0.02,
          },
        },

        portrait = {
          file = wezterm.home_dir .. "/Desktop/warehouse/wall/1.jpg",

          hsb = {
            brightness = 0.02,
          },
        },
      },
    },

    -- {
    --   name = "Workbench",
    --   cwd = wezterm.home_dir .. "/Workbench",

    --   shortcut = {
    --     key = "s",
    --     mods = "CMD|ALT",
    --   },

    --   background = {
    --     landscape = {
    --       file = wezterm.home_dir .. "/Desktop/warehouse/wall/8.png",

    --       hsb = {
    --         brightness = 0.02,
    --       },
    --     },

    --     portrait = {
    --       file = wezterm.home_dir .. "/Desktop/warehouse/wall/9.png",

    --       hsb = {
    --         brightness = 0.02,
    --       },
    --     },
    --   },
    -- },
  }
end
