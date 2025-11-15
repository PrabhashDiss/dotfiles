#!/usr/bin/env bash

# Terminate already running bar instances
# If all your bars have ipc enabled, you can use
polybar-msg cmd quit
# Otherwise you can use the nuclear option:
# killall -q polybar

# Launch bar(s)
# Logs go to /tmp so you can inspect failures
echo "---" | tee -a /tmp/polybar.log
# Launch a bar on every connected monitor and write per-monitor logs
for m in $(xrandr --query | grep " connected" | cut -d" " -f1); do
    MONITOR=$m polybar topbar 2>&1 | tee -a /tmp/polybar-${m}.log &
done

disown

echo "Bars launched..."
