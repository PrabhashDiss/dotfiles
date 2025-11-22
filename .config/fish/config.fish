function fish_greeting
    # disable default fish welcome/greeting message
end

function fish_prompt
    printf '\n%s\n› ' (pwd)
end

function fish_user_key_bindings
    # Execute this once per mode that emacs bindings should be used in
    fish_default_key_bindings -M insert

    # Then execute the vi-bindings so they take precedence when there's a conflict.
    # Without --no-erase fish_vi_key_bindings will default to
    # resetting all bindings.
    # The argument specifies the initial mode (insert, "default" or visual).
    fish_vi_key_bindings --no-erase insert
end

starship init fish | source

set -gx PATH "$HOME/.tmuxifier/bin" $PATH
eval (tmuxifier init - fish)
