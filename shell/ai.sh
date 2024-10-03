function openLLMinEditor {
	(editor="${EDITOR:-nvim}"; tempfile=$(mktemp); trap "rm -f $tempfile" EXIT; $editor "$tempfile" && cat "$tempfile" | llm)
}
