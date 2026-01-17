#!/bin/sh

SAVE_DIR="${HOME}/Pictures/screenshots"

save_and_copy() {
    mode="$1"
    ts=$(date +%Y%m%d-%H%M%S)
    mkdir -p "$SAVE_DIR"
    filepath="$SAVE_DIR/${ts}-${mode}.png"

    if tee "$filepath" | xclip -t 'image/png' -selection clipboard; then
        dunstify -a screenshot -t 4000 "Screenshot" "Saved screenshot: $filepath"
        return 0
    else
        [ -f "$filepath" ] && rm -f "$filepath"
        dunstify -a screenshot -t 4000 "Screenshot" "Failed to take screenshot"
        return 1
    fi
}

cmd_full() {
    shotgun - | save_and_copy full
}

cmd_selection() {
    selection=$(hacksaw)
    if [ -z "$selection" ]; then
        dunstify -a screenshot -t 4000 "Screenshot" "No selection made."
        return 1
    fi
    shotgun -g "$selection" - | save_and_copy selection
}

cmd_window() {
    id=$(xdotool getactivewindow 2>/dev/null)
    if [ -z "$id" ]; then
        dunstify -a screenshot -t 4000 "Screenshot" "No active window id."
        return 1
    fi
    shotgun -i "$id" - | save_and_copy window
}

case "${1:-}" in
"") cmd_full ;;
selection) cmd_selection ;;
window) cmd_window ;;
esac
