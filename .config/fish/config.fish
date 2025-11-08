function fish_greeting
    # disable default fish welcome/greeting message
end

function fish_prompt
    printf '\n%s\n› ' (pwd)
end

starship init fish | source
