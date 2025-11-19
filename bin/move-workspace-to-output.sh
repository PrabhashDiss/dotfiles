#!/usr/bin/env bash
set -euo pipefail

# Detect connected outputs using xrandr
mapfile -t outputs < <(xrandr --query | awk '/ connected/ {print $1}')

if [ ${#outputs[@]} -eq 0 ]; then
    echo "No outputs detected" >&2
    exit 1
fi

if [ "$#" -ge 1 ]; then # If first arg present and matches an output, use it
    target="$1"
    ok=0
    for o in "${outputs[@]}"; do
        if [ "$o" = "$target" ]; then
            ok=1
            break
        fi
    done
    if [ $ok -ne 1 ]; then
        echo "Specified output '$target' not found among: ${outputs[*]}" >&2
        exit 1
    fi
else # Prompt the user to choose an output
    if command -v rofi >/dev/null 2>&1; then
        target=$(printf "%s\n" "${outputs[@]}" | rofi -dmenu -p "Move workspace to output:")
    elif command -v fzf >/dev/null 2>&1; then
        target=$(printf "%s\n" "${outputs[@]}" | fzf --prompt="Move workspace to output: ")
    else
        echo "Available outputs: ${outputs[*]}"
        read -rp "Choose output: " target
    fi
    if [ -z "$target" ]; then
        echo "No output chosen" >&2
        exit 1
    fi
fi

# Get the currently focused workspace number using i3-msg
orig_ws_json=$(i3-msg -t get_workspaces 2>/dev/null) || {
    echo "Failed to get workspace list" >&2
    exit 1
}
orig_ws=$(printf '%s' "$orig_ws_json" | jq -r '.[] | select(.focused==true) | .num')
if [ -z "$orig_ws" ] || [ "$orig_ws" = "null" ]; then
    echo "Could not determine focused workspace" >&2
    exit 1
fi

# Move the workspace to the chosen output
if i3-msg "workspace number ${orig_ws}; move workspace to output ${target}" >/dev/null 2>&1; then
    echo "Moved workspace ${orig_ws} to output ${target}"
    exit 0
else
    echo "Failed to move workspace ${orig_ws} to output ${target}" >&2
    exit 1
fi
