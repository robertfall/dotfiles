return {
	{
		"nvim-treesitter/nvim-treesitter",
		branch = 'master',
		lazy = false,
		build = ":TSUpdate",
		config = function()
			require('nvim-treesitter.configs').setup({
				highlight = {
					enable = true,
					additional_vim_regex_highlighting = { "ruby" },
				},
				indent = {
					enable = false,
				},
				ensure_installed = {
					"javascript",
					"typescript",
					"tsx",
					"ruby",
					"rust",
					-- The five parsers below should always be installed
					"lua",
					"vim",
					"vimdoc",
					"c",
					"query"
				},
			})
		end,
	}
}
