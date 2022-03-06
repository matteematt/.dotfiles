local parser_config = require("nvim-treesitter.parsers").get_parser_configs()
parser_config.haskell = {
	install_info = {
		url = "~/.local/share/nvim/site/pack/packer/start/tree-sitter-haskell/",
		files = { "src/parser.c", "src/scanner.c" },
	},
}
