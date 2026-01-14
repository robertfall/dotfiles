return {
  "sindrets/diffview.nvim",
  cmd = { "DiffviewOpen", "DiffviewFileHistory", "DiffviewClose" },
  dependencies = { "nvim-tree/nvim-web-devicons" },
  opts = {},
  keys = {
    { "<leader>dv", "<cmd>DiffviewOpen<cr>", desc = "Diffview Open" },
    { "<leader>dh", "<cmd>DiffviewFileHistory %<cr>", desc = "File History" },
    { "<leader>dc", "<cmd>DiffviewClose<cr>", desc = "Diffview Close" },
    -- PR review: compare current branch with origin/main
    { "<leader>dp", "<cmd>DiffviewFileHistory --range=origin/main...HEAD --right-only --no-merges<cr>", desc = "PR Diff" },
  },
}
