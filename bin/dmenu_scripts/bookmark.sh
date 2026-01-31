#!/bin/sh

BOOKMARK_FILE="$HOME/.local/share/bookmarks"
mkdir -p "$(dirname "$BOOKMARK_FILE")"
touch "$BOOKMARK_FILE"

_dmenu_list() { dmenu -c -i -l 10 "$@"; }

_notify() {
    body="$1"
    if command -v dunstify >/dev/null 2>&1; then
        dunstify -a bookmarks -t 4000 "Bookmarks" "$body"
    elif command -v notify-send >/dev/null 2>&1; then
        notify-send -t 4000 "Bookmarks" "$body"
    else
        printf '%s\n' "$body"
    fi
}

do_add() {
    TERM_CMD=st
    EDIT_CMD=nvim
    if command -v "$TERM_CMD" >/dev/null 2>&1 && command -v "$EDIT_CMD" >/dev/null 2>&1; then
        "$TERM_CMD" -e "$EDIT_CMD" "$BOOKMARK_FILE"
        _notify "Bookmark file opened in $EDIT_CMD!"
    else
        _notify "Terminal or editor not found: $TERM_CMD / $EDIT_CMD"
    fi
}

do_select() {
    selection=$(sort -u "$BOOKMARK_FILE" | _dmenu_list -p "Bookmarks") || selection=""
    if [ -z "$selection" ]; then
        return 0
    fi

    action=$(printf "%s\n" "Copy" "Open" | _dmenu_list -p "Action") || action=""
    case "$action" in
    Copy)
        printf '%s' "$selection" | xclip -selection clipboard -i
        _notify "Copied bookmark to clipboard: $selection"
        ;;
    Open)
        BROWSER_CMD=librewolf
        if command -v "$BROWSER_CMD" >/dev/null 2>&1; then
            "$BROWSER_CMD" "$selection" &
            _notify "Opened bookmark in $BROWSER_CMD: $selection"
        else
            _notify "Browser not found: $BROWSER_CMD"
        fi
        ;;
    *)
        return 0
        ;;
    esac
}

if [ $# -eq 0 ]; then
    while true; do
        choice=$(printf "%s\n" "Add" "Select" | _dmenu_list -p "Bookmarks") || choice=""
        case "$choice" in
        Add) do_add ;;
        Select) do_select ;;
        "") exit 0 ;;
        esac
    done
    exit 0
fi
