#!/bin/bash
# Runs the DuoDemo UI tests with the fold-state bridge running.
# Usage: ./run-ui-tests.sh [simulator-udid]   (default: first booted/available "iPhone Duo")
set -euo pipefail
cd "$(dirname "$0")"
TOOLS="$(cd ../tools && pwd)"

UDID="${1:-$(xcrun simctl list devices available | grep -m1 'iPhone Duo (' | grep -oE '[0-9A-F-]{36}')}"
xcrun simctl bootstatus "$UDID" -b >/dev/null      # boot (headless is fine) and wait

[ -x "$TOOLS/duo-hinge" ] || clang -fobjc-arc -framework Foundation -o "$TOOLS/duo-hinge" "$TOOLS/duo-hinge.m"

/usr/bin/python3 "$TOOLS/duo-hinge-server.py" --port 8765 &
SERVER_PID=$!
trap 'kill $SERVER_PID 2>/dev/null' EXIT
until curl -sf http://127.0.0.1:8765/ping >/dev/null; do sleep 0.2; done

xcodebuild test -project DuoDemo.xcodeproj -scheme DuoDemo \
  -destination "platform=iOS Simulator,id=$UDID" "${@:2}"
