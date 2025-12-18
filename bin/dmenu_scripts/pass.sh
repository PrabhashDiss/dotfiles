#!/bin/sh

PASS_AUTO_NEXT_TIMEOUT=3

_dmenu_with_opts() {
    dmenu -c -i -l 10 "$@"
}

_notify() {
    msg=$1
    if command -v dunstify >/dev/null 2>&1; then
        dunstify -a pass -t 4000 "Pass" "$msg"
    elif command -v notify-send >/dev/null 2>&1; then
        notify-send -t 4000 "Pass" "$msg"
    else
        printf '%s\n' "$msg"
    fi
}

list_entries() {
    pass ls | sed -e 's/^[│├└─ ]*//' | grep -v '^Password Store$'
}

get_entry_flow() {
    entries=$(list_entries)
    if [ -z "$entries" ]; then
        _notify "No pass entries found."
        return
    fi

    entry=$(printf '%s\n' "$entries" | _dmenu_with_opts -p "Choose Entry") || entry=""
    [ -z "$entry" ] && return

    action=$(printf '%s\n' "Copy Password" "Copy Username" "Copy Username then Auto-Copy Password" | _dmenu_with_opts -p "Action") || action=""
    case "$action" in
    "Copy Password")
        pass show -c "$entry" >/dev/null 2>&1
        exit 0
        ;;
    "Copy Username")
        uname=$(pass show "$entry" | sed -n '2p') || uname=""
        if [ -n "$uname" ]; then
            printf '%s' "$uname" | xclip -selection clipboard -i
        else
            _notify "No username found for $entry"
        fi
        exit 0
        ;;
    "Copy Username then Auto-Copy Password")
        uname=$(pass show "$entry" | sed -n '2p') || uname=""
        if [ -n "$uname" ]; then
            printf '%s' "$uname" | xclip -selection clipboard -i

            sleep "$PASS_AUTO_NEXT_TIMEOUT"

            pass show -c "$entry" >/dev/null 2>&1
        else
            _notify "No username found for $entry"
        fi
        exit 0
        ;;
    *) ;;
    esac
}

while true; do
    choice=$(printf "%s\n" "Get" | _dmenu_with_opts -p "Pass") || choice=""
    case "$choice" in
    Get)
        get_entry_flow
        ;;
    *)
        exit 0
        ;;
    esac
done
