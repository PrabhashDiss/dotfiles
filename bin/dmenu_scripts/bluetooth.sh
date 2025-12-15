#!/bin/sh

DMENU=$(command -v dmenu 2>/dev/null || true)
if [ -z "$DMENU" ]; then
    echo "dmenu not found in PATH. This script requires dmenu." >&2
    exit 1
fi

BTCTL=$(command -v bluetoothctl 2>/dev/null || true)
if [ -z "$BTCTL" ]; then
    echo "bluetoothctl not found in PATH. This script requires bluetoothctl." >&2
    exit 1
fi

# dmenu wrappers
_dmenu() { $DMENU -c -i "$@"; }
_dmenu_list() { $DMENU -c -i -l 10 "$@"; }

_notify() {
    body="$1"
    if command -v dunstify >/dev/null 2>&1; then
        dunstify -a bluetooth -t 6000 "Bluetooth" "$body"
    elif command -v notify-send >/dev/null 2>&1; then
        notify-send -t 6000 "Bluetooth" "$body"
    else
        printf '%s\n' "$body"
    fi
}

toggle_power() {
    if $BTCTL show | grep -q "Powered: no"; then
        $BTCTL power on >/dev/null 2>&1 && sleep 1 && _notify "Bluetooth powered on"
        for mac in $($BTCTL devices Paired | awk '{print $2}'); do
            $BTCTL connect "$mac" >/dev/null 2>&1 || true
        done
    else
        # Disconnect paired devices then power off
        for mac in $($BTCTL devices Paired | awk '{print $2}'); do
            $BTCTL disconnect "$mac" >/dev/null 2>&1 || true
        done
        $BTCTL power off >/dev/null 2>&1 && _notify "Bluetooth powered off"
    fi
}

list_devices_menu() {
    tmpf=$(mktemp) || return

    # Produce lines: Alias<TAB>MAC<TAB>[Paired][Connected]\n
    $BTCTL devices 2>/dev/null | awk '{ $1=""; mac=$2; $2=""; sub(/^ /,""); alias=$0; print mac "\t" alias }' |
        while IFS="$(printf '\t')" read -r mac alias; do
            [ -z "$mac" ] && continue
            info=$($BTCTL info "$mac" 2>/dev/null || true)
            if printf '%s' "$info" | grep -q 'Paired: yes'; then
                paired='Paired'
            else
                paired='Not paired'
            fi
            if printf '%s' "$info" | grep -q 'Connected: yes'; then
                connected='Connected'
            else
                connected='Disconnected'
            fi
            printf '%s\t%s\t[%s][%s]\n' "$alias" "$mac" "$paired" "$connected"
        done >"$tmpf"

    # Let user pick; then return the MAC
    selected=$(_dmenu_list -p "Bluetooth devices:" <"$tmpf" | awk -F"\t" '{print $2}') || selected=""
    rm -f "$tmpf"
    printf '%s' "$selected"
}

select_scanned() {
    tmpf=$(mktemp) || return

    # Rescan and list available
    $BTCTL scan on >/dev/null 2>&1 &
    sleep 2
    $BTCTL scan off >/dev/null 2>&1

    $BTCTL devices 2>/dev/null | awk '{ $1=""; mac=$2; $2=""; sub(/^ /,""); alias=$0; print mac "\t" alias }' >"$tmpf"

    selected=$(_dmenu_list -p "Select device to pair/connect:" <"$tmpf" | awk -F"\t" '{print $1}') || selected=""
    rm -f "$tmpf"
    printf '%s' "$selected"
}

connect_device() {
    mac=$1
    if [ -z "$mac" ]; then
        return
    fi
    if $BTCTL connect "$mac" >/dev/null 2>&1; then
        _notify "Connected $mac"
    else
        _notify "Connect failed: $mac"
    fi
}

disconnect_device() {
    mac=$1
    if [ -z "$mac" ]; then
        return
    fi
    if $BTCTL disconnect "$mac" >/dev/null 2>&1; then
        _notify "Disconnected $mac"
    else
        _notify "Disconnect failed: $mac"
    fi
}

pair_device() {
    mac=$1
    if [ -z "$mac" ]; then
        return
    fi
    $BTCTL pair "$mac" >/dev/null 2>&1 && $BTCTL trust "$mac" >/dev/null 2>&1 && $BTCTL connect "$mac" >/dev/null 2>&1 && _notify "Pairing initiated: $mac" || _notify "Pairing failed: $mac"
}

remove_device() {
    mac=$1
    if [ -z "$mac" ]; then
        return
    fi
    if $BTCTL remove "$mac" >/dev/null 2>&1; then
        _notify "Removed $mac"
    else
        _notify "Remove failed: $mac"
    fi
}

status_summary() {
    out=$($BTCTL show 2>/dev/null)
    _notify "$out"
}

main_menu() {
    printf '%s\n' "Toggle Power" "List Devices" "Scan & Pair/Connect" "Connect (Choose)" "Disconnect (Choose)" "Remove Device" "Status" "Quit" | _dmenu_list -p "Bluetooth"
}

# Main loop
while true; do
    choice=$(main_menu)
    case "$choice" in
    "Toggle Power")
        toggle_power
        ;;
    "List Devices")
        mac=$(list_devices_menu)
        [ -z "$mac" ] && continue
        # show info
        info=$($BTCTL info "$mac" 2>/dev/null)
        _notify "$info"
        ;;
    "Scan & Pair/Connect")
        mac=$(select_scanned)
        [ -z "$mac" ] && continue
        action=$(
            printf '%s\n' Pair Connect Remove |
                _dmenu_list -p "Action:"
        ) || action=""
        case "$action" in
        Pair) pair_device "$mac" ;;
        Connect) connect_device "$mac" ;;
        Remove) remove_device "$mac" ;;
        esac
        ;;
    "Connect (Choose)")
        mac=$(list_devices_menu)
        [ -z "$mac" ] && continue
        connect_device "$mac"
        ;;
    "Disconnect (Choose)")
        mac=$(list_devices_menu)
        [ -z "$mac" ] && continue
        disconnect_device "$mac"
        ;;
    "Remove Device")
        mac=$(list_devices_menu)
        [ -z "$mac" ] && continue
        remove_device "$mac"
        ;;
    "Status")
        status_summary
        ;;
    "Quit" | "")
        exit 0
        ;;
    *)
        # If user typed something, try to treat it as a MAC and connect
        if printf '%s' "$choice" | grep -Eq '([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}'; then
            connect_device "$choice"
        fi
        ;;
    esac
done
