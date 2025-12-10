-- Example configuration for cursor.vim
-- Place this in your Neovim init.lua or as a separate plugin config

-- Using lazy.nvim
return {
  'johnbrandborg/cursor.vim',
  config = function()
    require('cursor').setup({
      -- Path to cursor CLI (auto-detected if in PATH)
      cli_path = 'cursor',

      -- AI model selection
      model = 'claude-sonnet-4',

      -- Increase timeout for complex queries
      timeout = 45000, -- 45 seconds

      -- UI customization
      ui = {
        -- Use floating windows for responses
        window_type = 'float', -- 'float', 'split', or 'vsplit'

        -- Floating window size (percentage of screen)
        float_width = 0.85,
        float_height = 0.85,

        -- Split size (if using split)
        split_size = 20,

        -- Window border style
        border = 'rounded', -- 'none', 'single', 'double', 'rounded', 'solid', 'shadow'
      },

      -- Chat configuration
      chat = {
        -- Enable chat history saving
        save_history = true,

        -- Keep last 30 messages in context
        max_context = 30,

        -- Custom history directory
        history_dir = vim.fn.stdpath('data') .. '/cursor_chats',
      },

      -- Custom key mappings
      mappings = {
        ask = '<leader>ca',      -- Ask question
        chat = '<leader>cc',     -- Open chat
        apply = '<leader>cy',    -- Apply code
        status = '<leader>cs',   -- Show status
      },

      -- Enable debug output
      debug = false,
    })

    -- Additional custom keymaps
    vim.keymap.set('n', '<leader>cab', ':CursorAskBuffer<CR>', {
      silent = true,
      desc = 'Ask Cursor about current buffer'
    })

    vim.keymap.set('n', '<leader>cp', ':CursorPreview<CR>', {
      silent = true,
      desc = 'Preview last Cursor response'
    })
  end
}

-- Alternative: Using packer.nvim
--[[
use {
  'johnbrandborg/cursor.vim',
  config = function()
    require('cursor').setup({
      -- Your configuration here
    })
  end
}
]]

-- Alternative: Using vim-plug
-- Add to your init.vim:
--[[
Plug 'johnbrandborg/cursor.vim'

" In your vimrc or after/plugin:
lua << EOF
  require('cursor').setup({
    -- Your configuration here
  })
EOF
]]

