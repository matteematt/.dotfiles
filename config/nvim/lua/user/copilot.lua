local copilot_setup = function()
	require("copilot").setup({
		suggestion = { enabled = false },
		panel = { enabled = false },
	})
end


local copilot_cmp_setup = function()
	require("copilot_cmp").setup({
		method = "getCompletionsCycling",
		formatters = {
			label = require("copilot_cmp.format").format_label_text,
			insert_text = require("copilot_cmp.format").format_insert_text,
			preview = require("copilot_cmp.format").deindent,
		},
	})
end

return {
	copilot_setup = copilot_setup,
	copilot_cmp_setup = copilot_cmp_setup,
}
