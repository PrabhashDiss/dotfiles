#!/usr/bin/env bash

set -euo pipefail

MENU_CMD="rofi -dmenu -i -p Power"

CHOICES="Shutdown\nReboot\nSuspend\nLogout\nLock"

CHOSEN=$(echo -e "$CHOICES" | eval $MENU_CMD)

case "$CHOSEN" in
Shutdown)
    systemctl poweroff
    ;;
Reboot)
    systemctl reboot
    ;;
Suspend)
    systemctl suspend
    ;;
Logout)
    i3-msg exit
    ;;
Lock)
    i3lock -c 000000
    ;;
*)
    # no choice or cancelled
    exit 0
    ;;
esac
