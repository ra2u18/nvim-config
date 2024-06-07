return {
  {
    'kwkarlwang/bufresize.nvim',
    config = function()
      local opts = { noremap = true, silent = true }
      require('bufresize').setup {
        register = {
          keys = {
            { 'n', '<C-Left>', '30<C-w><', opts },
            { 'n', '<C-Right>', '30<C-w>>', opts },
            { 'n', '<C-Up>', '10<C-w>+', opts },
            { 'n', '<C-Down>', '10<C-w>-', opts },
            { 'n', '<leader>w_', '<C-w>_', opts },
            { 'n', '<leader>w=', '<C-w>=', opts },
            { 'n', '<leader>w|', '<C-w>|', opts },
            { 'n', '<leader>wo', '<C-w>|<C-w>_', opts },
          },
          trigger_events = { 'BufWinEnter', 'WinEnter' },
        },
        resize = {
          keys = {},
          trigger_events = { 'VimResized' },
          increment = 5,
        },
      }
    end,
  },
}
