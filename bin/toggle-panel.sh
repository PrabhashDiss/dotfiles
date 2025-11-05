#!/bin/bash

# Ensure GSETTINGS_SCHEMA_DIR is defined
if [ -z "$GSETTINGS_SCHEMA_DIR" ]; then
    export GSETTINGS_SCHEMA_DIR="$HOME/.local/share/gnome-shell/extensions/just-perfection-desktop@just-perfection/schemas"
fi

schema="org.gnome.shell.extensions.just-perfection"
key="panel"
value=$(gsettings get $schema $key)

if [ "$value" = "true" ]; then
    gsettings set $schema $key false
else
    gsettings set $schema $key true
fi
