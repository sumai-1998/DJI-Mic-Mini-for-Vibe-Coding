#!/bin/zsh
set -eu
cd "${0:A:h:h}"
app="$PWD/build/DJI Doubao Controller.app"
mkdir -p "$app/Contents/MacOS"
cp Info.plist "$app/Contents/Info.plist"
MACOSX_DEPLOYMENT_TARGET=13.0 xcrun swiftc Sources/main.swift -framework AppKit -framework ApplicationServices -o "$app/Contents/MacOS/Controller"
"$app/Contents/MacOS/Controller" --self-test
codesign --force --sign - "$app"
codesign --verify --strict "$app"
printf 'Built: %s\n' "$app"
