-- WezTerm の配色。キーは Emacs と共有するテーマ名。
-- Retro Hacker Blue は従来の設定値をそのまま移したもの。
-- One Dark Blue は Emacs テーマの背景・モードライン・構文色に合わせる。
return {
  ["retro-hacker-blue"] = {
    foreground = "#5EAFFF",
    background = "#010111",
    cursor_bg = "#FF4DE1",
    cursor_fg = "#010111",
    cursor_border = "#FF4DE1",
    selection_fg = "#FFFFFF",
    selection_bg = "rgba(23, 51, 102, 0.70)",
    scrollbar_thumb = "#2759AA",
    split = "#153A75",
    ansi = {
      "#000000", "#FF4DE1", "#4682B4", "#FFD700",
      "#3B85D8", "#8A5EC0", "#00CED1", "#E0EEFF",
    },
    brights = {
      "#1A1A1A", "#FF4DE1", "#6CB8F0", "#FFFF00",
      "#5EAFFF", "#B07CFF", "#00FFFF", "#FFFFFF",
    },
    tab_bar = {
      background = "rgba(0, 0, 0, 0)",
      active_tab = {
        bg_color = "#000E2F",
        fg_color = "#316CBD",
        intensity = "Bold",
      },
      inactive_tab = {
        bg_color = "#00091F",
        fg_color = "#20467B",
      },
      inactive_tab_hover = {
        bg_color = "#00091F",
        fg_color = "#20467B",
      },
      inactive_tab_edge = "rgba(0, 0, 0, 0)",
    },
  },
  ["one-dark-blue"] = {
    foreground = "#61AFEF",
    background = "#151D2A",
    cursor_bg = "#C678DD",
    cursor_fg = "#151D2A",
    cursor_border = "#C678DD",
    selection_fg = "#E6E8ED",
    selection_bg = "#314B6A",
    scrollbar_thumb = "#365579",
    split = "#365579",
    ansi = {
      "#151D2A", "#E06C75", "#98C379", "#E5C07B",
      "#61AFEF", "#C678DD", "#56B6C2", "#ABB2BF",
    },
    brights = {
      "#5C6370", "#E06C75", "#98C379", "#E5C07B",
      "#81BFF2", "#C678DD", "#56B6C2", "#E6E8ED",
    },
    tab_bar = {
      background = "rgba(0, 0, 0, 0)",
      active_tab = {
        bg_color = "#202D40",
        fg_color = "#4A7FA8",
        intensity = "Bold",
      },
      inactive_tab = {
        bg_color = "#192332",
        fg_color = "#35566D",
      },
      inactive_tab_hover = {
        bg_color = "#192332",
        fg_color = "#35566D",
      },
      inactive_tab_edge = "rgba(0, 0, 0, 0)",
    },
  },
}
