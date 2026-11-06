#!/usr/bin/env bash
# @raycast.schemaVersion 1
# @raycast.title Google Calendar
# @raycast.mode silent
# @raycast.icon 📅
# @raycast.packageName Websites
# @raycast.description Focus a Google Calendar tab in Chrome, or open Calendar.

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
result="$(osascript "$script_dir/../lib/focus-chrome-tab.applescript" 'calendar.google.com')"

case "$result" in
  FOUND) ;;
  NOT_FOUND) open -a 'Google Chrome' 'https://calendar.google.com/calendar/u/0/r' ;;
  *) printf 'Unexpected Chrome tab lookup result: %s\n' "$result" >&2; exit 1 ;;
esac
