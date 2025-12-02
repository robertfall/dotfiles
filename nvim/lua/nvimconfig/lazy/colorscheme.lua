return {
	{
		"gbprod/nord.nvim",
		lazy = false,
		priority = 1000,
		config = function()
			require("nord").setup({
				styles = {
					comments = { italic = false },
					keywords = { italic = false },
					functions = { italic = false },
					variables = { italic = false },
				},
			})
			vim.cmd([[colorscheme nord]])
		end,
	}
}
