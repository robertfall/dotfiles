-- LSP configuration using Neovim 0.11+ native vim.lsp.config

vim.diagnostic.config({
  signs = false,
  underline = true,
  virtual_text = {
    spacing = 4,
    prefix = "        ",  -- 8 spaces
  },
})

-- Dimmed italic virtual text for diagnostics
vim.api.nvim_set_hl(0, "DiagnosticVirtualTextError", { fg = "#805050", italic = true, bg = "NONE" })
vim.api.nvim_set_hl(0, "DiagnosticVirtualTextWarn", { fg = "#806040", italic = true, bg = "NONE" })
vim.api.nvim_set_hl(0, "DiagnosticVirtualTextInfo", { fg = "#506080", italic = true, bg = "NONE" })
vim.api.nvim_set_hl(0, "DiagnosticVirtualTextHint", { fg = "#505080", italic = true, bg = "NONE" })
vim.api.nvim_set_hl(0, "DiagnosticVirtualTextOk", { fg = "#508050", italic = true, bg = "NONE" })

vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float)
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev)
vim.keymap.set('n', ']d', vim.diagnostic.goto_next)

vim.lsp.config('ruby_lsp', {
  cmd = { 'ruby-lsp' },
  filetypes = { 'ruby', 'eruby' },
  root_markers = { 'Gemfile', '.git' },
})

vim.lsp.config('rust_analyzer', {
  cmd = { 'rust-analyzer' },
  filetypes = { 'rust' },
  root_markers = { 'Cargo.toml', '.git' },
})

vim.lsp.config('vtsls', {
  cmd = { 'vtsls', '--stdio' },
  filetypes = { 'javascript', 'javascriptreact', 'typescript', 'typescriptreact' },
  root_markers = { 'tsconfig.json', 'package.json', '.git' },
})

vim.lsp.enable('ruby_lsp')
vim.lsp.enable('rust_analyzer')
vim.lsp.enable('vtsls')
