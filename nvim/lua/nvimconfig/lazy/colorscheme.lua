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

			-- Fix diff highlights to only set background, preserving syntax highlighting
			local bg_only = function(group, bg)
				vim.api.nvim_set_hl(0, group, { bg = bg })
			end
			bg_only("DiffAdd", "#394634")
			bg_only("DiffDelete", "#59394a")
			bg_only("DiffChange", "#2e3b4c")
			bg_only("DiffText", "#405d7e")
		end,
	}
}
