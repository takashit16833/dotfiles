#!/usr/bin/env bash
# @raycast.schemaVersion 1
# @raycast.title YouTube
# @raycast.mode silent
# @raycast.icon ▶️
# @raycast.packageName Websites
# @raycast.description Focus a YouTube tab in Chrome, or open YouTube.

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
result="$(osascript "$script_dir/../lib/focus-chrome-tab.applescript" 'youtube.com')"

case "$result" in
  FOUND) ;;
  NOT_FOUND) open -a 'Google Chrome' 'https://www.youtube.com/' ;;
  *) printf 'Unexpected Chrome tab lookup result: %s\n' "$result" >&2; exit 1 ;;
esac
