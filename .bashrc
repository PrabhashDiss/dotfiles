# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# Disable software flow control (XON/XOFF)
stty -ixon

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
#force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	# We have color support; assume it's compliant with Ecma-48
	# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
	# a case would tend to support setf rather than setaf.)
	color_prompt=yes
    else
	color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# colored GCC warnings and errors
#export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

if [ -f "$HOME/.config/bash/completions" ]; then
    . "$HOME/.config/bash/completions"
fi

if [ -f "$HOME/.config/bash/exports" ]; then
    . "$HOME/.config/bash/exports"
fi

if [ -f "$HOME/.config/bash/functions" ]; then
    . "$HOME/.config/bash/functions"
fi

if [ -f "$HOME/.config/bash/path" ]; then
    . "$HOME/.config/bash/path"
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

eval "$(starship init bash)"

export PATH="$HOME/.tmuxifier/bin:$PATH"
eval "$(tmuxifier init -)"

# Extract archives into a directory named after the file
ex() {
    if [ $# -eq 0 ]; then
        echo "Usage: ex|extract <archive> [archive2] [...]"
        echo "  Supported: .zip .rar .tar .tar.gz .tar.bz2 .tar.xz .7z .gz .bz2 .xz and more"
        return 1
    fi

    failed=0
    for n in "$@"; do
        if [ -f "$n" ]; then
            # Derive directory name
            base="$(basename "$n")"
            case "$base" in
            *.tar.gz | *.tar.bz2 | *.tar.xz)
                dir_name="${base%.*.*}"
                ;;
            *)
                dir_name="${base%.*}"
                ;;
            esac

            # Sanitize directory name to prevent path traversal
            case "$dir_name" in
                */* | *.* | *..*)
                    echo "ex: '$n' - unsafe directory name '$dir_name'"
                    failed=1
                    continue
                    ;;
            esac

            [ -d "$dir_name" ] || mkdir -p "$dir_name"

            [ -d "$dir_name" ] || mkdir -p "$dir_name"

            # Use absolute path for some commands that read from stdin
            if ! archive_path="$(realpath "$n" 2>/dev/null)"; then
                # Fallback if realpath is not available
                if [[ "$n" = /* ]]; then
                    archive_path="$n"
                else
                    archive_path="$PWD/$n"
                fi
            fi

            extraction_status=1
            case "$n" in
            *.cbt | *.tar.bz2 | *.tar.gz | *.tar.xz | *.tbz2 | *.tgz | *.txz | *.tar)
                tar xvf "$n" -C "$dir_name"
                extraction_status=$?
                ;;
            *.lzma)
                unlzma -c "$n" >"$dir_name/$(basename "$n" .lzma)"
                extraction_status=$?
                ;;
            *.bz2)
                bunzip2 -c "$n" >"$dir_name/$(basename "$n" .bz2)"
                extraction_status=$?
                ;;
            *.cbr | *.rar)
                unrar x "$n" "$dir_name/"
                extraction_status=$?
                ;;
            *.gz)
                gunzip -c "$n" >"$dir_name/$(basename "$n" .gz)"
                extraction_status=$?
                ;;
            *.cbz | *.epub | *.zip)
                unzip -d "$dir_name" "$n"
                extraction_status=$?
                ;;
            *.z)
                uncompress -c "$n" >"$dir_name/$(basename "$n" .z)"
                extraction_status=$?
                ;;
            *.7z | *.arj | *.cab | *.cb7 | *.chm | *.deb | *.dmg | *.iso | *.lzh | *.msi | *.pkg | *.rpm | *.udf | *.wim | *.xar)
                7z x "$n" -o"$dir_name"
                extraction_status=$?
                ;;
            *.xz)
                unxz -c "$n" >"$dir_name/$(basename "$n" .xz)"
                extraction_status=$?
                ;;
            *.exe)
                cabextract -d "$dir_name" "$n"
                extraction_status=$?
                ;;
            *.cpio)
                # Use realpath so cpio can read the file when changing directory
                (cd "$dir_name" && cpio -id <"$archive_path")
                extraction_status=$?
                ;;
            *.cba | *.ace)
                unace x -y -o"$dir_name" "$n"
                extraction_status=$?
                ;;
            *)
                echo "ex: '$n' - unknown archive method"
                failed=1
                continue
                ;;
            esac

            if [ "$extraction_status" -eq 0 ]; then
                echo "Extracted '$n' to '$dir_name/'"
            else
                echo "Failed to extract '$n'"
                failed=1
                continue
            fi
        else
            echo "'$n' - file does not exist"
            failed=1
            continue
        fi
    done

    return $failed
}
extract() { ex "$@"; }

# Directory to store command outputs
OUTPUT_DIR="$HOME/.bash_output_cache"
LAST_OUTPUT_FILE="$OUTPUT_DIR/last_output.txt"

# Function to search through last captured command output
search_last_output() {
    if [ -f "$LAST_OUTPUT_FILE" ] && [ -s "$LAST_OUTPUT_FILE" ]; then
        less -R -i "$LAST_OUTPUT_FILE"
    else
        echo "No captured output found. Use 'cap <command>' to capture output."
        return 1
    fi
}

# Function to run a command and capture its output with colors
cap() {
    if [ $# -eq 0 ]; then
        echo "Usage: cap <command>"
        echo "Example: cap ls --color=always"
        echo "Then use 'slo' to search through the output"
        return 1
    fi

    mkdir -p "$OUTPUT_DIR"

    # Run the command with script to preserve colors
    if ! script -q -c "$*" -f "$LAST_OUTPUT_FILE"; then
        echo "Failed to capture output" >&2
        return 1
    fi

    # Clean up script artifacts
    sed -i 's/\r$//' "$LAST_OUTPUT_FILE" 2>/dev/null || true
}

# Alias to search the last captured output
alias slo=search_last_output

# Bind Ctrl+X Ctrl+G to launch lazygit and Ctrl+X Ctrl+J to launch lazyjj
bind -x '"\C-x\C-g":"lazygit"'
bind -x '"\C-x\C-j":"lazyjj"'

# Add ~/.local/bin to PATH
export PATH="$HOME/.local/bin:$PATH"
# Bind Ctrl+X Ctrl+B to open bluetui
bind -x '"\C-x\C-b":"bluetui"'
# Bind Ctrl+X Ctrl+N to open nmtui
bind -x '"\C-x\C-n":"nmtui"'
# Bind Ctrl+X Ctrl+P to open pulsemixer
bind -x '"\C-x\C-p":"pulsemixer"'
