"""HarlequinへRetro Hacker Blue配色を適用する。"""

from textual.theme import Theme

import harlequin.colors as harlequin_colors


# emacs-retro-hacker-blue-themeの主要色をTextual Themeへ対応付ける。
RETRO_HACKER_BLUE_THEME = Theme(
    name="harlequin",
    primary="#5EAFFF",
    secondary="#87CEEB",
    warning="#FFD700",
    error="#FF4DE1",
    success="#6CB8F0",
    accent="#FF4DE1",
    foreground="#5EAFFF",
    background="#010111",
    surface="#010114",
    panel="#001E4A",
    dark=True,
    variables={
        # フォーカス中と非フォーカス時の枠線。
        "border": "#153A75",
        "border-blurred": "#0E264C",
        # 一覧や入力欄のカーソル・選択範囲。
        "block-cursor-background": "#FF4DE1",
        "block-cursor-foreground": "#010111",
        "block-cursor-blurred-background": "#052A59",
        "block-cursor-blurred-foreground": "#E6F2FF",
        "input-cursor-background": "#FF4DE1",
        "input-cursor-foreground": "#010111",
        "input-selection-background": "#13264B",
        # スクロールバー。
        "scrollbar": "#153A75",
        "scrollbar-hover": "#316CBD",
        "scrollbar-active": "#5EAFFF",
        "scrollbar-background": "#010111",
        # 画面下部のキーバインド表示。
        "footer-background": "#000E2F",
        "footer-foreground": "#316CBD",
        "footer-key-foreground": "#5EAFFF",
        "footer-description-foreground": "#316CBD",
    },
)

# Harlequinが標準で登録する "harlequin" テーマを起動時だけ差し替える。
harlequin_colors.HARLEQUIN_TEXTUAL_THEME = RETRO_HACKER_BLUE_THEME
harlequin_colors.VALID_THEMES["harlequin"] = RETRO_HACKER_BLUE_THEME
