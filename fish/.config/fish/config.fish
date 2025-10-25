function fish_greeting
    # disable default fish welcome/greeting message
end

function fish_prompt
    printf '%s\n\n› ' (pwd)
end
