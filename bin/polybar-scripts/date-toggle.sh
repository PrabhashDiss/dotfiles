#!/bin/sh
# Toggle date_mode between 0 and 1
STATE_FILE="/tmp/polybar_date_mode_$USER"
[ -f "$STATE_FILE" ] || echo 0 >"$STATE_FILE"
mode=$(cat "$STATE_FILE" | tr -d '\n')
if [ "$mode" = "1" ]; then
    echo 0 >"$STATE_FILE"
else
    echo 1 >"$STATE_FILE"
fi
