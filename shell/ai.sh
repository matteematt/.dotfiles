function openLLMinEditor {
    local extension=""
    local tempfile
    local persistent=false
    local reset=false
    local user_request_count=0
    local persistent_name="temp"  # Default name

    # Parse options
    while getopts ":p:f:r:" opt; do
        case $opt in
            p)
                persistent=true
                if [ -z "$OPTARG" ]; then
                    echo "Error: -p requires a name argument" >&2
                    return 1
                fi
                persistent_name="$OPTARG"
                ;;
            f)
                extension=".$OPTARG"
                ;;
            r)
                reset=true
                if [ -z "$OPTARG" ]; then
                    echo "Error: -r requires a filename argument" >&2
                    return 1
                fi
                persistent_name="$OPTARG"
                persistent=true
                ;;
            \?)
                echo "Invalid option: -$OPTARG" >&2
                return 1
                ;;
            :)
                echo "Error: Option -$OPTARG requires an argument." >&2
                return 1
                ;;
        esac
    done

    # Reset OPTIND to parse remaining arguments
    shift $((OPTIND-1))
    OPTIND=1

    editor="${EDITOR:-nvim}"

    if $persistent; then
        tempfile="/tmp/llm_${persistent_name}$extension"

        # Create the file if it doesn't exist or if reset flag is true
        if [ ! -f "$tempfile" ]; then
            touch "$tempfile"
            echo "Created new file: $tempfile"
        elif $reset; then
            echo -n '' > "$tempfile"  # Clear the file
            echo "Reset file: $tempfile"
        fi

        # Check if file exists and has content
        if [ -s "$tempfile" ]; then
            # Get the last section type from the file
            last_section=$(tail -n 20 "$tempfile" | grep -o "=======\(user\|response\) .*========" | tail -n 1)

            # Only increment counter and add new user section if last section was a response
            if [[ "$last_section" == *"response"* ]] || [ -z "$last_section" ]; then
                user_request_count=$(grep -c "=======user " "$tempfile")
                user_request_count=$((user_request_count + 1))
                echo -e "\n=======user $user_request_count========\n\n" >> "$tempfile"
            fi
        else
            # If file is empty, start with user 1
            user_request_count=1
            echo -e "=======user $user_request_count========\n\n" >> "$tempfile"
        fi

        # Store the initial md5sum if in persistent mode
        initial_md5sum=$(md5sum "$tempfile" | awk '{print $1}')
    else
        if [ -n "$extension" ]; then
            tempfile="$(mktemp)$extension"
        else
            tempfile=$(mktemp)
        fi
        trap "rm -f $tempfile" EXIT
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
                echo -e "\n=======response========" >> "$tempfile"
                cat "$tempfile" | llm "Don't ever create additional user inputs" | tee -a "$tempfile"
            else
                echo "No input detected. Skipping LLM processing."
            fi
        else
            cat "$tempfile" | llm
        fi
    else
        echo "No input detected. Skipping LLM processing."
    fi

    # If not persistent, remove the tempfile
    if ! $persistent; then
        rm -f "$tempfile"
    fi
}
