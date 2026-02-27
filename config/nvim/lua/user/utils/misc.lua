-- Function which saves the vim session, reloads all buffers, and then sources the session file
local _ReloadSession = function()
	local session_file = vim.fn.expand(vim.fn.stdpath("config") .. "/session.vim")
	vim.cmd("mksession! " .. session_file)
	vim.cmd("bufdo e!")
	vim.cmd("source " .. session_file)
	-- Delete the session file
	vim.cmd("silent! !rm " .. session_file)
end

local _CopyLineDiagnostics = function()
	local diagnostics = vim.diagnostic.get(0, { lnum = vim.fn.line('.') - 1 })
	if vim.tbl_isempty(diagnostics) then
		print("No diagnostics on current line")
		return
	end
	local messages = {}
	for _, d in ipairs(diagnostics) do
		table.insert(messages, d.message)
	end
	local text = table.concat(messages, '\n')
	vim.fn.setreg('+', text)
	print("Copied: " .. text)
end

return {
	reload_session = _ReloadSession,
	copy_line_diagnostics = _CopyLineDiagnostics,
}
