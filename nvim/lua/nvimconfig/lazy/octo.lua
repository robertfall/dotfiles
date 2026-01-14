return {
  "pwntester/octo.nvim",
  cmd = "Octo",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope.nvim",
    "nvim-tree/nvim-web-devicons",
  },
  opts = {
    picker = "telescope",
    enable_builtin = true,
  },
  keys = {
    { "<leader>oi", "<cmd>Octo issue list<cr>", desc = "GitHub Issues" },
    { "<leader>op", "<cmd>Octo pr list<cr>", desc = "GitHub PRs" },
    { "<leader>om", "<cmd>Octo search is:open is:pr review-requested:@me<cr>", desc = "My PR Reviews" },
    { "<leader>oM", "<cmd>Octo search is:open is:pr involves:@me<cr>", desc = "PRs Involving Me" },
    { "<leader>on", "<cmd>Octo notification list<cr>", desc = "Notifications" },
    { "<leader>or", "<cmd>Octo review start<cr>", desc = "Start Review" },
    { "<leader>os", "<cmd>Octo review submit<cr>", desc = "Submit Review" },
  },
}
