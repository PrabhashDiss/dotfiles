zsh-history-fuzzy-search() {
  command -v fzf >/dev/null 2>&1 || { zle -M "fzf not found"; return 1; }

  # Reload history from file to pick up commands from other sessions
  fc -R 2>/dev/null

  local selected
  selected=$(fc -l -r 1 | awk '{ s = substr($0, index($0, $2)); if (!seen[s]++) print }' | fzf \
    --height=40% \
    --layout=reverse \
    --border \
    --no-sort \
    +s +m -e \
    --tiebreak=index \
    --with-nth=2.. \
    -q "$LBUFFER")

  [[ -z "$selected" ]] && { zle redisplay; return 0; }

  # Extract event number and fetch exact command via fc
  local event_num=${${(s: :)selected}[1]}
  local cmd
  cmd=$(fc -ln "$event_num" "$event_num" 2>/dev/null)
  cmd=${cmd#${cmd%%[^[:space:]]*}}  # Trim leading whitespace

  if [[ -n "$cmd" ]]; then
    BUFFER="$cmd"
    CURSOR=${#BUFFER}
  fi

  zle redisplay
}

zle -N zsh-history-fuzzy-search

bindkey "^r" zsh-history-fuzzy-search
