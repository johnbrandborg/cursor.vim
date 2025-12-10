-- Configuration management for cursor.vim
local M = {}

-- Default configuration
M.defaults = {
  -- Path to cursor CLI executable
  cli_path = 'cursor-agent',

  -- Default model to use
  model = 'claude-sonnet-4',

  -- Timeout for CLI operations (milliseconds)
  timeout = 60000,

  -- UI preferences
  ui = {
    -- Window type for responses: 'float', 'split', 'vsplit'
    window_type = 'float',

    -- Floating window dimensions (if float)
    float_width = 0.8,  -- Percentage of screen width
    float_height = 0.8, -- Percentage of screen height

    -- Split size (if split/vsplit)
    split_size = 15,

    -- Border style: 'none', 'single', 'double', 'rounded', 'solid', 'shadow'
    border = 'rounded',
  },

  -- Chat preferences
  chat = {
    -- Save chat history
    save_history = true,

    -- Maximum context messages to keep
    max_context = 20,

    -- History file location
    history_dir = vim.fn.stdpath('data') .. '/cursor_chat_history',
  },

  -- Key mappings (set to false to disable)
  mappings = {
    ask = '<leader>ca',
    chat = '<leader>cc',
    apply = '<leader>cy',
    status = '<leader>cs',
  },

  -- Debug mode
  debug = false,
}

-- Current configuration (will be merged with user config)
M.config = vim.deepcopy(M.defaults)

-- Setup function to merge user configuration
function M.setup(user_config)
  M.config = vim.tbl_deep_extend('force', M.config, user_config or {})

  -- Create history directory if it doesn't exist
  if M.config.chat.save_history then
    vim.fn.mkdir(M.config.chat.history_dir, 'p')
  end

  return M.config
end

-- Validate that Cursor CLI is available
function M.validate_cli()
  local cli_path = M.config.cli_path

  -- Try to find cursor CLI
  local handle = io.popen('which ' .. cli_path .. ' 2>/dev/null')
  if not handle then
    return false, 'Could not execute which command'
  end

  local result = handle:read('*a')
  handle:close()

  if result and result ~= '' then
    return true, vim.trim(result)
  end

  return false, 'Cursor CLI not found. Please install Cursor CLI or set cli_path in config.'
end

-- Get current configuration
function M.get()
  return M.config
end

return M

