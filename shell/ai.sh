# Helper function for streaming output and bat display
function stream_and_display() {
    local input_text="$1"
    local append_file="$2"  # Optional: file to append to

    # Stream to terminal
    echo "$input_text" | tee /dev/tty > /dev/null

    # Clear the streamed output
    local lines=$(echo "$input_text" | wc -l)
    for ((i=0; i<$lines; i++)); do
        echo -en "\033[1A\033[2K"
    done

    # Display with bat
    echo "$input_text" | bat --paging=never

    # If a file was specified, append the output to it
    if [ -n "$append_file" ]; then
        echo "$input_text" >> "$append_file"
    fi
}

function openLLMinEditor {
    local extension=""
    local tempfile
    local thread=false
    local persist=false
    local reset=false
    local user_request_count=0
    local thread_name="temp"  # Default name
    local cache_dir="$HOME/.cache/llmc-chatbot"

    # Parse options
    while getopts ":t:p:f:r:" opt; do
        case $opt in
            t)
                thread=true
                if [ -z "$OPTARG" ]; then
                    echo "Error: -t requires a name argument" >&2
                    return 1
                fi
                thread_name="$OPTARG"
                ;;
            p)
                persist=true
                if [ -z "$OPTARG" ]; then
                    echo "Error: -p requires a name argument" >&2
                    return 1
                fi
                thread_name="$OPTARG"
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
                thread_name="$OPTARG"
                thread=true
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

			if $thread || $persist; then
        # Create cache directory if it doesn't exist
        if $persist; then
            mkdir -p "$cache_dir"
            tempfile="$cache_dir/${thread_name}$extension"
        else
            tempfile="/tmp/llm_${thread_name}$extension"
        fi

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

        # Store the initial md5sum if in thread or persist mode
        initial_md5sum=$(md5sum "$tempfile" | awk '{print $1}')
    else
        if [ -n "$extension" ]; then
            tempfile="$(mktemp)$extension"
        else
            tempfile=$(mktemp)
        fi
        trap "rm -f $tempfile" EXIT
    fi

    # Open the editor with specific commands for Neovim in thread/persist mode
    if ($thread || $persist) && [[ "$editor" == *"nvim"* ]]; then
        nvim -c "normal G" -c "normal zt" "$tempfile"
    else
        $editor "$tempfile"
    fi

		# Check if tempfile exists and is non-empty
    if [ -s "$tempfile" ]; then
        if $thread || $persist; then
            # Compare the md5sum after editing with the initial md5sum
            current_md5sum=$(md5sum "$tempfile" | awk '{print $1}')
            if [ "$initial_md5sum" != "$current_md5sum" ]; then
                # First append just the response marker to the file
                echo -e "\n=======response========" >> "$tempfile"

                # Get the LLM response and handle the output
                temp_output=$(cat "$tempfile" | llm "Don't ever create additional user inputs")
                stream_and_display "$temp_output" "$tempfile"
            else
                echo "No input detected. Skipping LLM processing."
            fi
        else
            # Use same streaming + bat functionality for non-persistent mode
            temp_output=$(cat "$tempfile" | llm)
            stream_and_display "$temp_output"
        fi
    else
        echo "No input detected. Skipping LLM processing."
    fi

    # If not thread or persist, remove the tempfile
    if ! $thread && ! $persist; then
        rm -f "$tempfile"
    fi
}
