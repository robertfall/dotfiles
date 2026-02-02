return {
  "sindrets/diffview.nvim",
  cmd = { "DiffviewOpen", "DiffviewFileHistory", "DiffviewClose" },
  dependencies = { "nvim-tree/nvim-web-devicons" },
  opts = {
    enhanced_diff_hl = true,
    hooks = {
      diff_buf_win_enter = function(bufnr, winid)
        -- Use diff_buf_win_enter instead - fires when window is ready
        if not vim.api.nvim_buf_is_valid(bufnr) then return end
        local bufname = vim.api.nvim_buf_get_name(bufnr)
        if bufname and bufname ~= "" then
          local ft = vim.filetype.match({ filename = bufname, buf = bufnr })
          if ft and ft ~= "" then
            vim.bo[bufnr].filetype = ft
            vim.api.nvim_buf_call(bufnr, function()
              vim.treesitter.start(bufnr, ft)
            end)
          end
        end
      end,
    },
  },
  keys = {
    { "<leader>dv", "<cmd>DiffviewOpen<cr>", desc = "Diffview Open" },
    { "<leader>dh", "<cmd>DiffviewFileHistory %<cr>", desc = "File History" },
    { "<leader>dc", "<cmd>DiffviewClose<cr>", desc = "Diffview Close" },
    -- PR review: compare current branch with origin/main
    { "<leader>dp", "<cmd>DiffviewFileHistory --range=origin/main...HEAD --right-only --no-merges<cr>", desc = "PR Diff" },
  },
}
