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

function ex
    if test (count $argv) -eq 0
        echo "Usage: ex <path/file_name>.<zip|rar|bz2|gz|tar|tbz2|tgz|Z|7z|xz|ex|tar.bz2|tar.gz|tar.xz>"
        echo "       ex <path/file_name_1.ext> [path/file_name_2.ext] [path/file_name_3.ext]"
        return 1
    end

    for n in $argv
        if test -f "$n"
            # Get directory name without extension
            set dir_name (basename "$n" | string replace -r '\.[^.]+$' '')
            
            # Create directory if it doesn't exist
            if not test -d "$dir_name"
                mkdir -p "$dir_name"
            end
            
            switch (string replace -r ',$' '' -- $n)
                case '*.cbt' '*.tar.bz2' '*.tar.gz' '*.tar.xz' '*.tbz2' '*.tgz' '*.txz' '*.tar'
                    tar xvf "$n" -C "$dir_name"
                case '*.lzma'
                    unlzma ./"$n" -c > "$dir_name/"(basename "$n" .lzma)
                case '*.bz2'
                    bunzip2 ./"$n" -c > "$dir_name/"(basename "$n" .bz2)
                case '*.cbr' '*.rar'
                    unrar x -ad ./"$n" "$dir_name/"
                case '*.gz'
                    gunzip ./"$n" -c > "$dir_name/"(basename "$n" .gz)
                case '*.cbz' '*.epub' '*.zip'
                    unzip ./"$n" -d "$dir_name"
                case '*.z'
                    uncompress ./"$n" -c > "$dir_name/"(basename "$n" .z)
                case '*.7z' '*.arj' '*.cab' '*.cb7' '*.chm' '*.deb' '*.dmg' '*.iso' '*.lzh' '*.msi' '*.pkg' '*.rpm' '*.udf' '*.wim' '*.xar'
                    7z x ./"$n" -o"$dir_name"
                case '*.xz'
                    unxz ./"$n" -c > "$dir_name/"(basename "$n" .xz)
                case '*.exe'
                    cabextract ./"$n" -d "$dir_name"
                case '*.cpio'
                    mkdir -p "$dir_name"
                    cpio -id < ./"$n" -D "$dir_name"
                case '*.cba' '*.ace'
                    unace x ./"$n" -y -o"$dir_name"
                case '*'
                    echo "ex: '$n' - unknown archive method"
                    return 1
            end
            echo "Extracted '$n' to '$dir_name/'"
        else
            echo "'$n' - file does not exist"
            return 1
        end
    end
end

starship init fish | source

set -gx PATH "$HOME/.tmuxifier/bin" $PATH
eval (tmuxifier init - fish)
