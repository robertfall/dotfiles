return {
  'saghen/blink.cmp',
  dependencies = { 'milanglacier/minuet-ai.nvim' },
  -- use a release tag to download pre-built binaries
  version = '1.*',

  config = function()
    require('blink.cmp').setup({
      keymap = {
        preset = 'default',
        ['<A-s>'] = require('minuet').make_blink_map(),
      },

      appearance = {
        nerd_font_variant = 'mono'
      },

      completion = {
        documentation = { auto_show = false },
        ghost_text = { enabled = true },
      },

      sources = {
        default = { 'lsp', 'path', 'snippets', 'buffer', 'minuet' },
        providers = {
          minuet = {
            name = 'minuet',
            module = 'minuet.blink',
            score_offset = 100,
          },
        },
      },

      fuzzy = { implementation = "prefer_rust_with_warning" }
    })
  end,
}
