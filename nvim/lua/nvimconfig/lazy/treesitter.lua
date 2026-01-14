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
					"markdown",
					"markdown_inline",
					"diff",
					-- The five parsers below should always be installed
					"lua",
					"vim",
					"vimdoc",
					"c",
					"query"
				},
			})

			-- Enable syntax highlighting for octo buffers
			vim.treesitter.language.register('markdown', 'octo')
		end,
	}
}
