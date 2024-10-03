function openLLMinEditor {
    local extension=""
    local tempfile

    # Parse options, -f can be used to specify an extension for the tempfile
		# effectively setting syntax highlighting in the editor
    while getopts "f:" opt; do
        case $opt in
            f)
                extension=".$OPTARG"
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

    if [ -n "$extension" ]; then
        tempfile="$(mktemp)$extension"
    else
        tempfile=$(mktemp)
    fi

    trap "rm -f $tempfile" EXIT

    $editor "$tempfile"

    # Check if tempfile exists and is non-empty
    if [ -s "$tempfile" ]; then
        cat "$tempfile" | llm
    else
        echo "No input detected"
    fi
}
