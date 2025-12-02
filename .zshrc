setopt histignorealldups sharehistory

setopt autocd
setopt interactive_comments

# vi mode
bindkey -v
KEYTIMEOUT=20

# Use lf to switch directories and bind it to ctrl-o
lfcd () {
  tmp="$(mktemp)" || return 1
  lf -last-dir-path="$tmp" "$@"
  if [ -f "$tmp" ]; then
    dir="$(< "$tmp")"
    [ -d "$dir" ] && [ "$dir" != "$PWD" ] && cd "$dir"
    rm -f "$tmp"
  fi
}
bindkey -s '^o' 'lfcd\n'
 
# Edit line in vim with ctrl-e
autoload -Uz edit-command-line; zle -N edit-command-line
bindkey '^e' edit-command-line
bindkey -M vicmd '^e' edit-command-line
if [[ -n ${terminfo[kdch1]} ]]; then
  bindkey -M vicmd  "$terminfo[kdch1]"  vi-delete-char
  bindkey -M visual "$terminfo[kdch1]"  vi-delete
else
  echo "Warning: 'kdch1' not found in terminfo. 'Delete' key binding for vi mode not set."
fi

# Change cursor shape for different vi modes
autoload -Uz add-zsh-hook
_set_block_cursor() { print -n -- $'\e[1 q' }   # block cursor
_set_beam_cursor()  { print -n -- $'\e[5 q' }   # beam cursor
function zle-keymap-select () {
  case $KEYMAP in
    vicmd) _set_block_cursor;;
    viins|main) _set_beam_cursor;;
  esac
}
zle -N zle-keymap-select
zle-line-init() {
  zle -K viins # Initiate `vi insert` keymap (can be removed if `bindkey -v` has been set elsewhere)
  _set_beam_cursor
}
zle -N zle-line-init
_set_beam_cursor # Use beam cursor on startup
add-zsh-hook precmd _set_beam_cursor # Use beam cursor before each prompt

# History configuration
HISTSIZE=1000000
SAVEHIST=1000000
# Ensure history directory exists and migrate legacy history
mkdir -p "${HOME}/.cache/zsh"
if [[ -f "${HOME}/.zsh_history" ]]; then
  cat "${HOME}/.zsh_history" >> "${HOME}/.cache/zsh/history"
  mv "${HOME}/.zsh_history" "${HOME}/.zsh_history.bak"
fi
HISTFILE="${HOME}/.cache/zsh/history"

# Use modern completion system
autoload -Uz compinit
compinit

zmodload zsh/complist
_comp_options+=(globdots)		# Include hidden files

zstyle ':completion:*' auto-description 'specify: %d'
zstyle ':completion:*' completer _expand _complete _correct _approximate
zstyle ':completion:*' format 'Completing %d'
zstyle ':completion:*' group-name ''
zstyle ':completion:*' menu select=2
eval "$(dircolors -b)"
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' list-colors ''
zstyle ':completion:*' list-prompt %SAt %p: Hit TAB for more, or the character to insert%s
zstyle ':completion:*' matcher-list '' 'm:{a-z}={A-Z}' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=* l:|=*'
zstyle ':completion:*' menu select=long
zstyle ':completion:*' select-prompt %SScrolling active: current selection at %p%s
zstyle ':completion:*' use-compctl false
zstyle ':completion:*' verbose true

zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
zstyle ':completion:*:kill:*' command 'ps -u $USER -o pid,%cpu,tty,cputime,cmd'

if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
else
  echo "Starship is not installed. Please install it to see the prompt."
fi

# Extract archives into a directory named after the file
ex() {
  if [ $# -eq 0 ]; then
    echo "Usage: ex <path/file_name>.<zip|rar|bz2|gz|tar|tbz2|tgz|Z|7z|xz|exe|tar.bz2|tar.gz|tar.xz>"
    echo "       extract <path/file_name_1.ext> [path/file_name_2.ext] [...]"
    return 1
  fi

  for n in "$@"; do
    if [ -f "$n" ]; then
      # Derive directory name
      base="$(basename "$n")"
      case "$base" in
        *.tar.gz|*.tar.bz2|*.tar.xz)
          dir_name="${base%.*.*}"
          ;;
        *)
          dir_name="${base%.*}"
          ;;
      esac

      [ -d "$dir_name" ] || mkdir -p "$dir_name"

      # Use absolute path for some commands that read from stdin
      path="$(realpath "$n" 2>/dev/null || printf '%s' "$n")"

      case "$n" in
        *.cbt|*.tar.bz2|*.tar.gz|*.tar.xz|*.tbz2|*.tgz|*.txz|*.tar)
          tar xvf "$n" -C "$dir_name"
          ;;
        *.lzma)
          unlzma -c "$n" > "$dir_name/$(basename "$n" .lzma)"
          ;;
        *.bz2)
          bunzip2 -c "$n" > "$dir_name/$(basename "$n" .bz2)"
          ;;
        *.cbr|*.rar)
          unrar x "$n" "$dir_name/"
          ;;
        *.gz)
          gunzip -c "$n" > "$dir_name/$(basename "$n" .gz)"
          ;;
        *.cbz|*.epub|*.zip)
          unzip -d "$dir_name" "$n"
          ;;
        *.z)
          uncompress -c "$n" > "$dir_name/$(basename "$n" .z)"
          ;;
        *.7z|*.arj|*.cab|*.cb7|*.chm|*.deb|*.dmg|*.iso|*.lzh|*.msi|*.pkg|*.rpm|*.udf|*.wim|*.xar)
          7z x "$n" -o"$dir_name"
          ;;
        *.xz)
          unxz -c "$n" > "$dir_name/$(basename "$n" .xz)"
          ;;
        *.exe)
          cabextract -d "$dir_name" "$n"
          ;;
        *.cpio)
          # Use realpath so cpio can read the file when changing directory
          (cd "$dir_name" && cpio -id < "$path")
          ;;
        *.cba|*.ace)
          unace x -y -o"$dir_name" "$n"
          ;;
        *)
          echo "ex: '$n' - unknown archive method"
          return 1
          ;;
      esac

      echo "Extracted '$n' to '$dir_name/'"
    else
      echo "'$n' - file does not exist"
      return 1
    fi
  done
}
extract() { ex "$@"; }

# Syntax highlighting
if [[ -f ~/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
  source ~/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi
