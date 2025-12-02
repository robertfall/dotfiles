vim.g.mapleader = ","

-- Enable filetype detection and indentation
vim.cmd([[
filetype plugin indent on
]])

vim.opt.autoindent = true

require('nvimconfig/lazy_init')
require('nvimconfig/set')
require('nvimconfig/remap')
require('nvimconfig/lsp')
