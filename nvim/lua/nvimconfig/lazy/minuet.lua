return {
  'milanglacier/minuet-ai.nvim',
  dependencies = { 'nvim-lua/plenary.nvim' },
  config = function()
    require('minuet').setup({
      provider = 'claude',
      notify = 'warn',
      provider_options = {
        claude = {
          model = 'claude-haiku-4-5-20251001',
          max_tokens = 512,
          api_key = 'ANTHROPIC_API_KEY',
        },
      },
      virtualtext = {
        auto_trigger_ft = {},
        keymap = {
          accept = '<A-a>',
          accept_line = '<A-l>',
          next = '<A-]>',
          prev = '<A-[>',
          dismiss = '<A-e>',
        },
      },
    })
  end,
}
