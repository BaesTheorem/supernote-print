#!/bin/bash
# Install the Supernote printer: LaunchAgent for the IPP server, a CUPS queue
# named "Supernote" that points at it, and a starter config.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LABEL=com.baestheorem.supernote-print
PORT="${SUPERNOTE_PRINT_PORT:-8641}"
AGENT="$HOME/Library/LaunchAgents/$LABEL.plist"
CONFIG_DIR="$HOME/.config/supernote-print"

mkdir -p "$HOME/Library/LaunchAgents" "$HOME/Library/Logs/supernote-print" "$CONFIG_DIR"

if [ ! -f "$CONFIG_DIR/config.json" ]; then
    cp "$HERE/config.example.json" "$CONFIG_DIR/config.json"
    echo "Wrote $CONFIG_DIR/config.json; edit drive_folder to match your sync setup."
fi

# launchd wants a real file, not a symlink into the repo.
sed -e "s|__REPO__|$HERE|g" -e "s|__HOME__|$HOME|g" \
    "$HERE/launchd/$LABEL.plist" > "$AGENT"
launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$AGENT"

for _ in $(seq 1 20); do
    if nc -z localhost "$PORT" >/dev/null 2>&1; then break; fi
    sleep 0.5
done
nc -z localhost "$PORT" >/dev/null 2>&1 || { echo "IPP server did not come up on :$PORT; see ~/Library/Logs/supernote-print/server.log" >&2; exit 1; }

lpadmin -p Supernote -E \
    -v "ipp://localhost:$PORT/ipp/print" \
    -P "$HERE/ppd/supernote.ppd" \
    -D "Supernote" \
    -o printer-is-shared=false 2>&1 | grep -v 'drivers are deprecated' || true
lpstat -p Supernote
echo "Installed. Pick \"Supernote\" in any print dialog."
