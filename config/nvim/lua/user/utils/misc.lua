-- Function which saves the vim session, reloads all buffers, and then sources the session file
local _ReloadSession = function()
	local session_file = vim.fn.expand(vim.fn.stdpath("config") .. "/session.vim")
	vim.cmd("mksession! " .. session_file)
	vim.cmd("bufdo e!")
	vim.cmd("source " .. session_file)
	-- Delete the session file
	vim.cmd("silent! !rm " .. session_file)
end

return {
	reload_session = _ReloadSession,
}
