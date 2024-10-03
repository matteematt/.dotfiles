function openLLMinEditor {
    local extension=""
    local tempfile
    local persistent=false
    local reset=false
    local user_request_count=0

    # Parse options
    while getopts "f:pr" opt; do
        case $opt in
            f)
                extension=".$OPTARG"
                ;;
            p)
                persistent=true
                ;;
            r)
                reset=true
                ;;
            \?)
                echo "Invalid option: -$OPTARG" >&2
                return 1
                ;;
        esac
    done

    # Reset OPTIND to parse remaining arguments
    shift $((OPTIND-1))
    OPTIND=1

    editor="${EDITOR:-nvim}"

    if $persistent; then
        tempfile="/tmp/llm_temp$extension"
        if [ ! -f "$tempfile" ] || $reset; then
            > "$tempfile"  # Create or clear the file
        else
            # Get the current user request count
            user_request_count=$(grep -c "=======user " "$tempfile")
        fi
    else
        if [ -n "$extension" ]; then
            tempfile="$(mktemp)$extension"
        else
            tempfile=$(mktemp)
        fi
        trap "rm -f $tempfile" EXIT
    fi

    # Append the user section if in persistent mode
    if $persistent; then
        user_request_count=$((user_request_count + 1))
        echo -e "
=======user $user_request_count========
" >> "$tempfile"

			# Store the initial md5sum if in persistent mode
        initial_md5sum=$(md5sum "$tempfile" | awk '{print $1}')
    fi

    # Open the editor with specific commands for Neovim in persistent mode
    if $persistent && [[ "$editor" == *"nvim"* ]]; then
        nvim -c "normal G" -c "normal zt" "$tempfile"
    else
        $editor "$tempfile"
    fi

    # Check if tempfile exists and is non-empty
    if [ -s "$tempfile" ]; then
        if $persistent; then
            # Compare the md5sum after editing with the initial md5sum
            current_md5sum=$(md5sum "$tempfile" | awk '{print $1}')
            if [ "$initial_md5sum" != "$current_md5sum" ]; then
                local llm_response
                llm_response=$(cat "$tempfile" | llm)
                echo "$llm_response"

                echo -e "
=======response========
" >> "$tempfile"
                echo "$llm_response" >> "$tempfile"
            else
                echo "No input detected. Skipping LLM processing."
            fi
        else
            local llm_response
            llm_response=$(cat "$tempfile" | llm)
            echo "$llm_response"
        fi
    else
        echo "No input detected"
    fi

    # If not persistent, remove the tempfile
    if ! $persistent; then
        rm -f "$tempfile"
    fi
}
