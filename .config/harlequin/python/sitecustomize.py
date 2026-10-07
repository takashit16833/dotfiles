"""HarlequinへRetro Hacker Blue配色を適用する。"""

from pathlib import Path

from textual.theme import Theme

import harlequin.colors as harlequin_colors


# Textual 8.2.8のANSI themeを利用し、端末の既定背景をそのまま通す。
# Retro Hacker Blueの前景色はTrueColorのまま維持する。
RETRO_HACKER_BLUE_THEME = Theme(
    name="harlequin",
    primary="#5EAFFF",
    secondary="#87CEEB",
    warning="#FFD700",
    error="#FF4DE1",
    success="#6CB8F0",
    accent="#FF4DE1",
    foreground="#5EAFFF",
    background="ansi_default",
    surface="ansi_default",
    panel="ansi_default",
    boost="ansi_default",
    dark=True,
    ansi=True,
    variables={
        # ANSI theme用。Textualの:ansiルールが参照するため必須。
        "ansi-background": "ansi_default",
        "ansi-foreground": "#5EAFFF",
        # Retro Hacker Blueの通常文字・補助文字。
        "text": "#5EAFFF",
        "text-muted": "#316CBD",
        "text-disabled": "#305888",
        "foreground-muted": "#316CBD",
        # 枠線。
        "border": "#5EAFFF",
        "border-blurred": "#153A75",
        # 一覧や入力欄のカーソル・選択範囲。
        "block-cursor-background": "#061536",
        "block-cursor-foreground": "#A6CAFF",
        "block-cursor-blurred-background": "#061536",
        "block-cursor-blurred-foreground": "#A6CAFF",
        "input-cursor-background": "#FF4DE1",
        "input-cursor-foreground": "#010111",
        "input-cursor-text-style": "none",
        "input-selection-background": "#13264B",
        "input-selection-foreground": "#A6CAFF",
        "screen-selection-background": "#13264B",
        "screen-selection-foreground": "#A6CAFF",
        # スクロールバーの背景は端末既定背景を使う。
        "scrollbar": "#153A75",
        "scrollbar-hover": "#316CBD",
        "scrollbar-active": "#5EAFFF",
        "scrollbar-background": "ansi_default",
        "scrollbar-corner-color": "ansi_default",
        "scrollbar-background-hover": "ansi_default",
        "scrollbar-background-active": "ansi_default",
        # ボタンはHarlequin側の背景色を文字色として使わない。
        "button-color-foreground": "#010111",
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
