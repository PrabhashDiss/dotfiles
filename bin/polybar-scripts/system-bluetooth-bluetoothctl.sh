#!/bin/sh

bluetooth_print() {
    bluetoothctl | grep --line-buffered 'Device\|#' | while read -r REPLY; do
        if [ "$(systemctl is-active "bluetooth.service")" = "active" ]; then
            printf '#1'

            devices_paired=$(bluetoothctl devices Paired | grep Device | cut -d ' ' -f 2)
            counter=0

            for device in $devices_paired; do
                device_info=$(bluetoothctl info "$device")

                if echo "$device_info" | grep -q "Connected: yes"; then
                    device_output=$(echo "$device_info" | grep "Alias" | cut -d ' ' -f 2-)
                    device_battery_percent=$(echo "$device_info" | grep "Battery Percentage" | awk -F'[()]' '{print $2}')

                    if [ -n "$device_battery_percent" ]; then
                        if [ "$device_battery_percent" -gt 90 ]; then
                            device_battery_icon="#25"
                        elif [ "$device_battery_percent" -gt 60 ]; then
                            device_battery_icon="#24"
                        elif [ "$device_battery_percent" -gt 35 ]; then
                            device_battery_icon="#23"
                        elif [ "$device_battery_percent" -gt 10 ]; then
                            device_battery_icon="#22"
                        else
                            device_battery_icon="#21"
                        fi

                        device_output="$device_output $device_battery_icon $device_battery_percent%"
                    fi

                    if [ $counter -gt 0 ]; then
                        printf ", %s" "$device_output"
                    else
                        printf " %s" "$device_output"
                    fi

                    counter=$((counter + 1))
                fi
            done

            printf '\n'
        else
            echo "#2"
        fi
    done
}

bluetooth_toggle() {
    if bluetoothctl show | grep -q "Powered: no"; then
        bluetoothctl power on >> /dev/null
        sleep 1

        devices_paired=$(bluetoothctl devices Paired | grep Device | cut -d ' ' -f 2)
        echo "$devices_paired" | while read -r line; do
            bluetoothctl connect "$line" >> /dev/null
        done
    else
        devices_paired=$(bluetoothctl devices Paired | grep Device | cut -d ' ' -f 2)
        echo "$devices_paired" | while read -r line; do
            bluetoothctl disconnect "$line" >> /dev/null
        done

        bluetoothctl power off >> /dev/null
    fi
}

bluetooth_menu() {
    # Ensure bluetooth powered
    if bluetoothctl show | grep -q "Powered: no"; then
        bluetoothctl power on >/dev/null 2>&1
        sleep 1
    fi

    # Gather devices: "MAC<TAB>Alias..."
    devices=$(bluetoothctl devices | awk '{ $1=""; mac=$2; $2=""; sub(/^ /,""); alias=$0; print mac "\t" alias }')

    if [ -z "$devices" ]; then
        notify-send "No devices found"
        return 0
    fi

    menu_items=""

    while IFS=$'\t' read -r mac alias; do
        [[ -z $mac && -z $alias ]] && continue

        info="$(bluetoothctl info "$mac" 2>/dev/null)"

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

        menu_items="${menu_items}${alias}\t${mac}\t[${paired}][${connected}]\n"
    done <<<"$devices"

    selected=$(printf "%b" "$menu_items" | rofi -dmenu | awk -F$'\t' '{print $2}')
    [ -z "$selected" ] && return 0
    mac="$selected"

    # Refresh device info
    info=$(bluetoothctl info "$mac" 2>/dev/null)
    paired=$(printf "%s" "$info" | grep -q "Paired: yes" && echo "yes" || echo "no")
    connected=$(printf "%s" "$info" | grep -q "Connected: yes" && echo "yes" || echo "no")

    # Present actions based on state
    if [ "$paired" = "yes" ]; then
        if [ "$connected" = "yes" ]; then
            action=$(printf "Disconnect\nRemove" | rofi -dmenu)
        else
            action=$(printf "Connect\nRemove" | rofi -dmenu)
        fi
    else
        action=$(printf "Pair\nConnect" | rofi -dmenu)
    fi

    [ -z "$action" ] && return 0

    case "$action" in
    Pair)
        bluetoothctl pair "$mac" >/dev/null 2>&1
        bluetoothctl trust "$mac" >/dev/null 2>&1
        bluetoothctl connect "$mac" >/dev/null 2>&1
        notify-send "Pairing initiated: $mac"
        ;;
    Connect)
        if bluetoothctl connect "$mac" >/dev/null 2>&1; then
            notify-send "Connected $mac"
        else
            notify-send "Connect failed: $mac"
        fi
        ;;
    Disconnect)
        if bluetoothctl disconnect "$mac" >/dev/null 2>&1; then
            notify-send "Disconnected $mac"
        else
            notify-send "Disconnect failed: $mac"
        fi
        ;;
    Remove)
        if bluetoothctl remove "$mac" >/dev/null 2>&1; then
            notify-send "Removed $mac"
        else
            notify-send "Remove failed: $mac"
        fi
        ;;
    *)
        notify-send "Unknown action"
        ;;
    esac
}

case "$1" in
    --toggle)
        bluetooth_toggle
        ;;
    --menu)
        bluetooth_menu
        ;;
    *)
        bluetooth_print
        ;;
esac
