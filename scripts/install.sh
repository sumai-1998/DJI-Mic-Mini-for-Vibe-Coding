#!/bin/zsh
set -eu
cd "${0:A:h:h}"
./scripts/build.sh
app="$HOME/Applications/DJI Doubao Controller.app"
agent="$HOME/Library/LaunchAgents/local.dji-doubao-controller.plist"
# Stop only this installed application before replacing its executable.
for pid in ${(f)"$(pgrep -x Controller || true)"}; do
    [[ -n "$pid" ]] || continue
    if [[ "$(ps -p "$pid" -o comm=)" == "$app/Contents/MacOS/Controller" ]]; then
        kill -TERM "$pid"
    fi
done
launchctl bootout "gui/$UID/local.dji-doubao-controller" 2>/dev/null || true
launchctl bootout "gui/$UID/local.dji-doubao-remap" 2>/dev/null || true
mkdir -p "$HOME/Applications" "${agent:h}"
ditto "build/DJI Doubao Controller.app" "$app"
codesign --verify --strict "$app"
# Only remove legacy helpers from this project's earlier prototypes.
rm -f "$HOME/Library/LaunchAgents/local.dji-doubao-remap.plist" "$HOME/.local/bin/dji-doubao-remap"
rm -f "$agent"
/usr/libexec/PlistBuddy -c 'Add :Label string local.dji-doubao-controller' "$agent" >/dev/null
/usr/libexec/PlistBuddy -c 'Add :RunAtLoad bool true' "$agent"
/usr/libexec/PlistBuddy -c 'Add :ProcessType string Background' "$agent"
/usr/libexec/PlistBuddy -c 'Add :ProgramArguments array' "$agent"
/usr/libexec/PlistBuddy -c 'Add :ProgramArguments:0 string /usr/bin/open' "$agent"
/usr/libexec/PlistBuddy -c "Add :ProgramArguments:1 string $app" "$agent"
launchctl bootstrap "gui/$UID" "$agent"
printf 'Installed: %s\nEnable Accessibility permission if the menu says Mic·待授权.\n' "$app"
