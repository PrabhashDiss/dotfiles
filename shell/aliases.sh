if command -v lsd >/dev/null 2>&1; then
    alias ls="lsd"
    alias ll="lsd -l"
    alias la="lsd -la"
    alias lt="lsd --tree"
fi
