#!/bin/bash
set -uo pipefail
LABEL=com.baestheorem.supernote-print
launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null
rm -f "$HOME/Library/LaunchAgents/$LABEL.plist"
lpadmin -x Supernote 2>/dev/null
echo "Removed the Supernote queue and LaunchAgent. Config left in ~/.config/supernote-print."
