#!/bin/sh

DMENU=$(command -v dmenu 2>/dev/null || true)
if [ -z "$DMENU" ]; then
    echo "dmenu not found in PATH. This script requires dmenu." >&2
    exit 1
fi

NMCLI=$(command -v nmcli 2>/dev/null || true)
if [ -z "$NMCLI" ]; then
    echo "nmcli not found in PATH. This script requires NetworkManager." >&2
    exit 1
fi

# Cleanup helper for temporary files used by select_scan_ssid/connect
cleanup_tmpf() {
    [ -n "$tmpf" ] && [ -f "$tmpf" ] && rm -f "$tmpf"
}
trap cleanup_tmpf EXIT INT TERM

dmenu_with_opts() {
    "$DMENU" -c -i "$@"
}

dmenu_with_list_opts() {
    "$DMENU" -c -i -l 10 "$@"
}

main_menu() {
    printf "%s\n" "Connect (Scan)" "Connect (Saved)" "Disconnect" "Toggle Wi-Fi" "Status" "Forget (Saved)" "Rescan" "Quit" |
        dmenu_with_list_opts -p "Wi-Fi"
}

notify() {
    body=$1
    if command -v dunstify >/dev/null 2>&1; then
        dunstify -a wifi -t 8000 "Wi-Fi" "$body"
    elif command -v notify-send >/dev/null 2>&1; then
        notify-send -t 8000 "Wi-Fi" "$body"
    else
        printf '%s\n' "$body"
    fi
}

select_scan_ssid() {
    tmpf=$(mktemp) || return

    "$NMCLI" -t -f SSID,RATE,SIGNAL,BARS,SECURITY device wifi list --rescan yes 2>/dev/null |
        awk -F: 'BEGIN{fmt="%-32s %3s %-8s %4s %s"} NF{printf fmt "\t%s\n", $1, $2, $3, $4, $5, $1}' >"$tmpf"

    # Show the formatted display columns in dmenu
    display=$(cut -f1 "$tmpf" | dmenu_with_list_opts -p "Connect to network:") || display=""
    if [ -z "$display" ]; then
        rm -f "$tmpf"
        tmpf=
        return
    fi

    # Map the selected formatted display back to its SSID
    ssid=$(awk -F"\t" -v sel="$display" '$1==sel{print $2; exit}' "$tmpf")
    rm -f "$tmpf"
    tmpf=
    printf '%s' "$ssid"
}

connect() {
    ssid=$1
    if [ -z "$ssid" ]; then
        return
    fi

    sec=$("$NMCLI" -t -f SSID,SECURITY device wifi list --rescan no 2>/dev/null | awk -F: -v s="$ssid" '$1==s{print $2; exit}' || true)
    if echo "$sec" | grep -qiE "WPA|WEP|PSK|EAP"; then
        pass=$(dmenu_with_opts -p "Password for $ssid:") || pass=""
        if [ -z "$pass" ]; then
            notify "No password provided, aborting"
            return
        fi
        if ! "$NMCLI" device wifi connect "$ssid" password "$pass"; then
            notify "Failed to connect to $ssid"
            return
        fi
    else
        if ! "$NMCLI" device wifi connect "$ssid"; then
            notify "Failed to connect to $ssid"
            return
        fi
    fi
}

list_saved() {
    "$NMCLI" -t -f NAME,TYPE connection show | awk -F: '$2=="802-11-wireless"{print $1}'
}

disconnect() {
    dev=$("$NMCLI" -t -f DEVICE,TYPE,STATE device | awk -F: '$2=="wifi" && $3=="connected"{print $1; exit}' || true)
    if [ -n "$dev" ]; then
        "$NMCLI" device disconnect "$dev" || notify "Failed to disconnect device $dev"
    else
        conn=$("$NMCLI" -t -f NAME,TYPE connection show --active | awk -F: '$2=="802-11-wireless"{print $1; exit}' || true)
        if [ -n "$conn" ]; then
            "$NMCLI" connection down "$conn" || notify "Failed to bring down connection $conn"
        fi
    fi
}

toggle_wifi() {
    state=$("$NMCLI" radio wifi)
    if [ "$state" = "enabled" ]; then
        "$NMCLI" radio wifi off
    else
        "$NMCLI" radio wifi on
    fi
}

status() {
    "$NMCLI" -p device status
}

forget_saved() {
    name=$(list_saved | dmenu_with_list_opts -p "Forget which saved network?") || name=""
    if [ -z "$name" ]; then
        return
    fi
    if "$NMCLI" connection delete id "$name"; then
        notify "Forgot saved network: $name"
    else
        notify "Failed to forget network: $name"
    fi
}

rescan() {
    # Rescan quietly, then list results
    "$NMCLI" device wifi rescan >/dev/null 2>&1 || true
    "$NMCLI" device wifi list
}

# Main loop
while true; do
    choice=$(main_menu)
    case "$choice" in
    "Connect (Scan)")
        ssid=$(select_scan_ssid)
        connect "$ssid"
        ;;
    "Connect (Saved)")
        saved=$(list_saved | dmenu_with_list_opts -p "Saved networks:")
        if [ -n "$saved" ]; then
            "$NMCLI" connection up "$saved"
        fi
        ;;
    "Disconnect")
        disconnect
        ;;
    "Toggle Wi-Fi")
        toggle_wifi
        ;;
    "Status")
        status_out=$(status)
        notify "$status_out"
        ;;
    "Forget (Saved)")
        forget_saved
        ;;
    "Rescan")
        rescan_out=$(rescan)
        notify "$rescan_out"
        ;;
    "Quit" | "")
        exit 0
        ;;
    *)
        # If user typed an SSID directly, attempt connect
        if [ -n "$choice" ]; then
            connect "$choice"
        fi
        ;;
    esac
done
