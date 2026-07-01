return {
  'saghen/blink.cmp',
  -- use a release tag to download pre-built binaries
  version = '1.*',

  config = function()
    require('blink.cmp').setup({
      keymap = {
        preset = 'default',
      },

      appearance = {
        nerd_font_variant = 'mono'
      },

      completion = {
        documentation = { auto_show = false },
        ghost_text = { enabled = true },
      },

      sources = {
        default = { 'lsp', 'path', 'snippets', 'buffer' },
      },

      fuzzy = { implementation = "prefer_rust_with_warning" }
    })
  end,
}
