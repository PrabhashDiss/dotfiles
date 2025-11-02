#!/usr/bin/env bash

quick_edit() {
    local tmp
    tmp=$(mktemp)
    [ "$#" -gt 0 ] && printf "%s\n" "$@" >"$tmp" || cat >"$tmp"

    old_mtime=$(stat -c %Y "$tmp")
    "$EDITOR" "$tmp" < /dev/tty > /dev/tty

    new_mtime=$(stat -c %Y "$tmp")
    if [ "$old_mtime" -eq "$new_mtime" ]; then
        rm -f "$tmp"
        return 1
    fi

    cat "$tmp"
    rm -f "$tmp"
}
