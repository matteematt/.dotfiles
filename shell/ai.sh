function openLLMinEditor {
    local extension=""
    local tempfile
    local persistent=false
    local reset=false

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
        fi
    else
        if [ -n "$extension" ]; then
            tempfile="$(mktemp)$extension"
        else
            tempfile=$(mktemp)
        fi
        trap "rm -f $tempfile" EXIT
    fi

    $editor "$tempfile"

    # Check if tempfile exists and is non-empty
    if [ -s "$tempfile" ]; then
        cat "$tempfile" | llm
    else
        echo "No input detected"
    fi

    # If not persistent, remove the tempfile
    if ! $persistent; then
        rm -f "$tempfile"
    fi
}
