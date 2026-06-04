return {
	{
		"nvim-treesitter/nvim-treesitter",
		branch = "main", -- master is frozen/legacy; main is the supported branch for Neovim 0.11+
		lazy = false, -- main branch does not support lazy-loading
		build = ":TSUpdate",
		config = function()
			local parsers = {
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
				"query",
			}

			-- main branch installs parsers explicitly (no more `ensure_installed`).
			-- install() is async and a no-op for parsers already present.
			require("nvim-treesitter").install(parsers)

			-- Treat RBI (Sorbet) files as Ruby
			vim.treesitter.language.register("ruby", "rbi")

			-- main branch does not auto-enable highlighting; start it per-buffer.
			local function start(buf)
				local lang = vim.treesitter.language.get_lang(vim.bo[buf].filetype)
				if not lang then
					return
				end
				-- pcall: silently skip buffers whose parser isn't installed yet
				if not pcall(vim.treesitter.start, buf, lang) then
					return
				end
				-- Keep legacy vim regex highlighting alongside treesitter for ruby
				-- (replaces the old `additional_vim_regex_highlighting = { "ruby" }`)
				if lang == "ruby" then
					vim.bo[buf].syntax = "ON"
				end
			end

			vim.api.nvim_create_autocmd("FileType", {
				group = vim.api.nvim_create_augroup("treesitter_highlight", { clear = true }),
				callback = function(ev)
					start(ev.buf)
				end,
			})

			-- Catch buffers already loaded before this autocmd was registered
			-- (e.g. a file passed on the command line).
			for _, buf in ipairs(vim.api.nvim_list_bufs()) do
				if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].filetype ~= "" then
					start(buf)
				end
			end
		end,
	},
}
