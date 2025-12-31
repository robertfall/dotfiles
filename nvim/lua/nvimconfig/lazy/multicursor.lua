return {
	{
		"jake-stewart/multicursor.nvim",
		branch = "1.0",
		config = function()
			local mc = require("multicursor-nvim")
			mc.setup()

			local set = vim.keymap.set

			-- Add or skip cursor above/below
			set({ "n", "x" }, "<up>", function() mc.lineAddCursor(-1) end, { desc = "Add cursor above" })
			set({ "n", "x" }, "<down>", function() mc.lineAddCursor(1) end, { desc = "Add cursor below" })
			set({ "n", "x" }, "<leader><up>", function() mc.lineSkipCursor(-1) end, { desc = "Skip cursor above" })
			set({ "n", "x" }, "<leader><down>", function() mc.lineSkipCursor(1) end, { desc = "Skip cursor below" })

			-- Add cursor by matching word/selection
			set({ "n", "x" }, "<leader>n", function() mc.matchAddCursor(1) end, { desc = "Add cursor at next match" })
			set({ "n", "x" }, "<leader>N", function() mc.matchAddCursor(-1) end, { desc = "Add cursor at prev match" })
			set({ "n", "x" }, "<leader>s", function() mc.matchSkipCursor(1) end, { desc = "Skip next match" })
			set({ "n", "x" }, "<leader>S", function() mc.matchSkipCursor(-1) end, { desc = "Skip prev match" })

			-- Add all matches in file
			set({ "n", "x" }, "<leader>A", mc.matchAllAddCursors, { desc = "Add cursors to all matches" })

			-- Rotate through cursors
			set({ "n", "x" }, "<left>", mc.prevCursor, { desc = "Previous cursor" })
			set({ "n", "x" }, "<right>", mc.nextCursor, { desc = "Next cursor" })

			-- Delete current cursor
			set({ "n", "x" }, "<leader>x", mc.deleteCursor, { desc = "Delete cursor" })

			-- Toggle cursor under mouse
			set("n", "<c-leftmouse>", mc.handleMouse, { desc = "Toggle cursor with mouse" })

			-- Escape clears cursors
			set("n", "<esc>", function()
				if not mc.cursorsEnabled() then
					mc.enableCursors()
				elseif mc.hasCursors() then
					mc.clearCursors()
				else
					-- Default escape behavior
					vim.cmd("nohlsearch")
				end
			end)

			-- Customize highlights to match your colorscheme
			local hl = vim.api.nvim_set_hl
			hl(0, "MultiCursorCursor", { link = "Cursor" })
			hl(0, "MultiCursorVisual", { link = "Visual" })
			hl(0, "MultiCursorSign", { link = "SignColumn" })
			hl(0, "MultiCursorDisabledCursor", { link = "Visual" })
			hl(0, "MultiCursorDisabledVisual", { link = "Visual" })
			hl(0, "MultiCursorDisabledSign", { link = "SignColumn" })
		end,
	},
}
