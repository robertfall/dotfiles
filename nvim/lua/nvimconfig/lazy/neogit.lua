return {
  "NeogitOrg/neogit",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "sindrets/diffview.nvim",
    "nvim-telescope/telescope.nvim",
  },
  cmd = "Neogit",
  opts = {
    integrations = {
      diffview = true,
      telescope = true,
    },
  },
  keys = {
    { "<leader>gs", "<cmd>Neogit<cr>", desc = "Neogit Status" },
    { "<leader>gc", "<cmd>Neogit commit<cr>", desc = "Neogit Commit" },
    { "<leader>gp", "<cmd>Neogit push<cr>", desc = "Neogit Push" },
    { "<leader>gl", "<cmd>Neogit pull<cr>", desc = "Neogit Pull" },
  },
}
