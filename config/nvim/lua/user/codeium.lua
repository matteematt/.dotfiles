local status_ok, codeium = pcall(require, "codeium")
if not status_ok then
	print("Unable to load plugin : codeium")
	return
end

-- if the working directory contains tmp or genesis then use the genesis copilot
if vim.fn.getcwd():find("tmp") or vim.fn.getcwd():find("genesis") then
	print("Codeium using genesis server")
	codeium.setup({
		enable_chat = true,
		config_path = "/Users/matt.walker/.codeium.genesis.json",
		api = {
			portal_url = "copilot.genesislcap.com",
			host = "copilot.genesislcap.com",
			path = "/_route/api_server",
		},
	})
else
	print("Codeium using public server")
	codeium.setup({
		enable_chat = true,
	})
end
