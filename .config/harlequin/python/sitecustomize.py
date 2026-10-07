"""HarlequinへRetro Hacker Blue配色を適用する。"""

from pathlib import Path

from textual.theme import Theme

import harlequin.colors as harlequin_colors


# emacs-retro-hacker-blue-themeの主要色をTextual Themeへ対応付ける。
# 背景は描画せず、WezTerm側の背景色や透過設定をそのまま使う。
RETRO_HACKER_BLUE_THEME = Theme(
    name="harlequin",
    primary="#5EAFFF",
    secondary="#87CEEB",
    warning="#FFD700",
    error="#FF4DE1",
    success="#6CB8F0",
    accent="#FF4DE1",
    foreground="#5EAFFF",
    background="transparent",
    surface="transparent",
    panel="#001E4A",
    boost="transparent",
    dark=True,
    variables={
        # 一覧や入力欄のカーソル・選択範囲。
        "block-cursor-background": "#FF4DE1",
        "block-cursor-foreground": "#010111",
        "block-cursor-blurred-background": "#061536",
        "block-cursor-blurred-foreground": "#A6CAFF",
        "input-cursor-background": "#FF4DE1",
        "input-cursor-foreground": "#010111",
        "input-selection-background": "#13264B",
        # スクロールバー。
        "scrollbar": "#153A75",
        "scrollbar-hover": "#316CBD",
        "scrollbar-active": "#5EAFFF",
        "scrollbar-background": "transparent",
        "scrollbar-corner-color": "transparent",
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

# Harlequin本体のCSSは変更せず、dotfiles側の微調整を最後に読み込む。
from harlequin.app import Harlequin

THEME_CSS = Path(__file__).resolve().parents[1] / "retro-hacker-blue.tcss"
Harlequin.CSS_PATH = [*Harlequin.CSS_PATH, THEME_CSS]
