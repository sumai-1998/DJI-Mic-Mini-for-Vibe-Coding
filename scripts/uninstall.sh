#!/bin/zsh
set -eu
app="$HOME/Applications/DJI Doubao Controller.app"
launchctl bootout "gui/$UID/local.dji-doubao-controller" 2>/dev/null || true
for pid in ${(f)"$(pgrep -x Controller || true)"}; do
    [[ -n "$pid" ]] || continue
    if [[ "$(ps -p "$pid" -o comm=)" == "$app/Contents/MacOS/Controller" ]]; then
        kill -TERM "$pid"
    fi
done
hidutil property --matching '{"VendorID":11427,"ProductID":16401}' --set '{"UserKeyMapping":[]}' >/dev/null
rm -rf "$app"
rm -f "$HOME/Library/LaunchAgents/local.dji-doubao-controller.plist"
printf 'Uninstalled. Local diagnostics remain in ~/.local/share/dji-doubao-controller/.\n'
