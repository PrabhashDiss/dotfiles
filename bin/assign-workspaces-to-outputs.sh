#!/usr/bin/env bash
set -euo pipefail

# assign-workspaces-to-outputs.sh
# Detect connected outputs, enable outputs that are connected-but-inactive,
# and assign workspaces across active outputs.
# Default behavior: split 10 workspaces evenly across detected outputs.

workspaces=(1 2 3 4 5 6 7 8 9 10)

# Read xrandr connected lines
mapfile -t xr_lines < <(xrandr --query | grep ' connected')

outputs=()
active_outputs=()
inactive_outputs=()
primary=""

for line in "${xr_lines[@]}"; do
    out=$(awk '{print $1}' <<<"$line")
    outputs+=("$out")
    if [[ "$line" == *" primary "* ]]; then
        primary="$out"
    fi
    # Active outputs usually include a mode+position like 1920x1080+0+0
    if [[ "$line" =~ [0-9]+x[0-9]+\+[0-9]+\+[0-9]+ ]]; then
        active_outputs+=("$out")
    else
        inactive_outputs+=("$out")
    fi
done
# Final outputs to use
final_outputs=("${active_outputs[@]}")
# If no active outputs, fall back to connected-but-inactive outputs
if [ "${#final_outputs[@]}" -eq 0 ] && [ "${#inactive_outputs[@]}" -gt 0 ]; then
    final_outputs=("${inactive_outputs[@]}")
fi

# Distribute workspaces across final_outputs
n=${#final_outputs[@]}
if [ "$n" -eq 0 ]; then
    echo "No outputs detected; nothing to assign" >&2
    exit 0
fi
len=${#workspaces[@]}
chunk=$(((len + n - 1) / n))

# Move each workspace to the appropriate output
i=0
for ws in "${workspaces[@]}"; do
    out_index=$((i / chunk))
    if [ "$out_index" -ge "$n" ]; then out_index=$((n - 1)); fi
    out="${final_outputs[$out_index]}"
    # Move workspace and capture i3-msg result
    if out_json=$(i3-msg "workspace number ${ws}; move workspace to output ${out}" 2>&1); then
        echo "Assigned workspace ${ws} to output ${out}"
    else
        echo "Failed to assign workspace ${ws} to output ${out}: ${out_json}" >&2
    fi
    i=$((i + 1))
done
