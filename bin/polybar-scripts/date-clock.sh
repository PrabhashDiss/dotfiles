#!/bin/sh
STATE_FILE="/tmp/polybar_date_mode_$USER"
[ -f "$STATE_FILE" ] || echo 0 >"$STATE_FILE"

while :; do
    mode=$(cat "$STATE_FILE" | tr -d '\n')
    if [ "$mode" = "1" ]; then
        printf " %s  %s\n" "$(date +"%Y-%m-%d")" "$(date +"%H:%M:%S")"
    else
        printf " %s\n" "$(date +"%H:%M")"
    fi
    sleep 1
done
