call_llm_and_handle() {
    local input=$1
    local tempfile=$2  # Add tempfile as second parameter
    local system_prompt_override=$3
    local direct_stream=$4  # New parameter for direct streaming mode

    local prompt
    read -r -d '' prompt << 'EOF'
You are a helpful assistant. Please follow these guidelines:
- Use markdown formatting when appropriate - when adding code blocks please always tag the language name after the backticks
- Stay focused on the user's question - Don't create additional user prompts
EOF

    # Append system prompt override if provided
    if [ -n "$system_prompt_override" ]; then
        prompt="$prompt
$system_prompt_override"
    fi

    local temp_output
    
    if [ "$direct_stream" = "true" ]; then
        # Stream directly to terminal
        temp_output=$(echo "$input" | llm "$prompt" -u | tee /dev/tty)
    else
        # Save screen and switch to alternate screen
        echo -en "\033[?1049h"

        # Stream output and capture it
        temp_output=$(echo "$input" | llm "$prompt" -u | tee /dev/tty)

        # Switch back to main screen
        echo -en "\033[?1049l"

        # Display formatted output
        echo "$temp_output" | bat --paging=never --theme="OneHalfDark" --color always -p -l md
    fi

    # If we need to append to tempfile (for thread/persist mode)
    if [ -n "$tempfile" ]; then
        echo "$temp_output" >> "$tempfile"
    fi
}

function openLLMinEditor {
    local extension=""
    local tempfile
    local thread=false
    local persist=false
    local reset=false
    local direct_stream=false
    local user_request_count=0
    local thread_name="temp"  # Default name
    local cache_dir="$HOME/.cache/llmc-chatbot"
    local system_prompt_override=""

    # Parse options
    while getopts ":t:p:f:r:s:d" opt; do
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
            s)
                system_prompt_override="$OPTARG"
                ;;
            d)
                direct_stream=true
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
                echo -e "\n=======response========" >> "$tempfile"
                call_llm_and_handle "$(cat "$tempfile")" "$tempfile" "$system_prompt_override" "$direct_stream"
            else
                echo "No input detected. Skipping LLM processing."
            fi
        else
            call_llm_and_handle "$(cat "$tempfile")" "" "$system_prompt_override" "$direct_stream"
        fi
    else
        echo "No input detected. Skipping LLM processing."
    fi

    # If not thread or persist, remove the tempfile
    if ! $thread && ! $persist; then
        rm -f "$tempfile"
    fi
}
