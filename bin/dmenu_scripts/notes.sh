#!/usr/bin/env bash

# Set terminal
TERMINAL="st"

folder="$HOME/notes"
mkdir -p "$folder"

newnote () {
  dir="$(command ls -d "$folder" "$folder"*/ 2>/dev/null | dmenu -c -l 5 -i -p 'Choose directory: ')" || exit 0
  : "${dir:=$folder}"
  dir="${dir%/}"  # Remove trailing slash if present
  name="$(echo "" | dmenu -c -sb "#a3be8c" -nf "#d8dee9" -p "Enter a name: " )" || exit 0
  : "${name:=$(date +%F_%H-%M-%S)}"
  setsid -f "${TERMINAL}" -e nvim "${dir}/${name}.md" > /dev/null 2>&1
}

selected () {
  choice=$(
    {
      printf '%s\n' "New"
      find "${folder}" -type f -printf '%T@ %P\n' | sort -nr | cut -d' ' -f2-
    } | dmenu -c -l 5 -i -p "Choose note or create new: "
  )
  case $choice in
    New) newnote ;;
    *.md) setsid -f "${TERMINAL}" -e nvim "${folder}/${choice}" > /dev/null 2>&1 ;;
    *) exit ;;
  esac
}

selected
