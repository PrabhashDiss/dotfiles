setopt histignorealldups sharehistory

setopt autocd
setopt interactive_comments

# Use emacs keybindings even if our EDITOR is set to vi
bindkey -e

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

# Syntax highlighting
if [[ -f ~/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
  source ~/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi
