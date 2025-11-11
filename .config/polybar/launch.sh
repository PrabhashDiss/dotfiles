#!/usr/bin/env bash

# Terminate already running bar instances
# If all your bars have ipc enabled, you can use
polybar-msg cmd quit
# Otherwise you can use the nuclear option:
# killall -q polybar

# Launch bar(s)
# Logs go to /tmp so you can inspect failures
echo "---" | tee -a /tmp/polybar-topbar.log
polybar topbar 2>&1 | tee -a /tmp/polybar-topbar.log & disown

echo "Bars launched..."
