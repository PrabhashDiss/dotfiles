#!/usr/bin/env bash
set -euo pipefail

for cmd in xrandr i3-msg jq; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "Error: Required command '$cmd' not found" >&2
        exit 1
    fi
done

# Get the primary output
primary_output=$(xrandr --query | awk '/^[^ ]+ connected primary/ {print $1; exit}')

if [ -z "$primary_output" ]; then
    echo "No primary output detected" >&2
    exit 1
fi

echo "Moving all workspaces to primary output: $primary_output"

# Get all workspaces
workspaces_json=$(i3-msg -t get_workspaces 2>/dev/null) || {
    echo "Failed to get workspace list" >&2
    exit 1
}

# Extract workspace numbers and move each to primary output
echo "$workspaces_json" | jq -r '.[] | .num' | while read -r ws_num; do
    if [ -n "$ws_num" ] && [ "$ws_num" != "null" ]; then
        echo "Moving workspace $ws_num to $primary_output"
        i3-msg "workspace number $ws_num; move workspace to output $primary_output" >/dev/null 2>&1 || {
            echo "Failed to move workspace $ws_num to $primary_output" >&2
        }
    fi
done

echo "All workspaces moved to primary output"
