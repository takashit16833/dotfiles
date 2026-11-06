#!/usr/bin/env bash
# @raycast.schemaVersion 1
# @raycast.title Gmail
# @raycast.mode silent
# @raycast.icon ✉️
# @raycast.packageName Websites
# @raycast.description Focus a Gmail tab in Chrome, or open Gmail.

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
result="$(osascript "$script_dir/../lib/focus-chrome-tab.applescript" 'mail.google.com')"

case "$result" in
  FOUND) ;;
  NOT_FOUND) open -a 'Google Chrome' 'https://mail.google.com/mail/u/0/?tab=rm&ogbl#inbox' ;;
  *) printf 'Unexpected Chrome tab lookup result: %s\n' "$result" >&2; exit 1 ;;
esac
