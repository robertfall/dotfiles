 return {
	{
		"nvim-telescope/telescope.nvim",
		tag = "v0.2.1",
		dependencies = {
			"nvim-lua/plenary.nvim",
			{
				"nvim-telescope/telescope-fzf-native.nvim",
				build = "make",
			},
		},
		config = function()
			local telescope = require("telescope")
			local builtin = require("telescope.builtin")

			telescope.setup({
				defaults = {
					file_ignore_patterns = { "node_modules", ".git/" },
				},
				extensions = {
					fzf = {
						fuzzy = true,
						override_generic_sorter = true,
						override_file_sorter = true,
						case_mode = "smart_case",
					},
				},
			})

			-- Load fzf extension
			telescope.load_extension("fzf")

			-- Keymaps (leader is ,)
			vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Find files" })
			vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Live grep" })
			vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Buffers" })
			vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Help tags" })
			vim.keymap.set("n", "<leader>fr", builtin.oldfiles, { desc = "Recent files" })
			vim.keymap.set("n", "<leader>fs", builtin.grep_string, { desc = "Grep word under cursor" })
      vim.keymap.set("n", '<leader>gd', '<cmd>Telescope lsp_definitions<cr>')
      vim.keymap.set("n", '<leader>gr', '<cmd>Telescope lsp_references<cr>')
      vim.keymap.set("n", '<leader>gi', '<cmd>Telescope lsp_implementations<cr>')
      vim.keymap.set("n", '<leader>ds', '<cmd>Telescope lsp_document_symbols<cr>')
      vim.keymap.set("n", '<leader>ws', '<cmd>Telescope lsp_workspace_symbols<cr>')

		end,
	},
}
