#!/bin/sh

# /etc/X11/xinit/xinitrc
#
# global xinitrc file, used by all X sessions started by xinit (startx)

# invoke global X session script
. /etc/X11/Xsession

# Start sxhkd if available
if [ -x /usr/bin/sxhkd ]; then
	/usr/bin/sxhkd &
fi

# Start dwm as the window manager for this X session
exec dwm
