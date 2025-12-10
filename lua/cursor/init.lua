-- Main module initialization for cursor.vim
local M = {}

-- Module state
M.state = {
  initialized = false,
  cli_available = false,
  active_chat = nil,
  last_response = nil,
}

-- Load submodules
M.config = require('cursor.config')
M.cli = nil     -- Lazy load
M.ui = nil      -- Lazy load
M.ask = nil     -- Lazy load
M.chat = nil    -- Lazy load
M.apply = nil   -- Lazy load

-- Setup function called by user
function M.setup(user_config)
  if M.state.initialized then
    vim.notify('cursor.vim already initialized', vim.log.levels.WARN)
    return
  end

  -- Setup configuration
  M.config.setup(user_config or {})

  -- Validate CLI availability
  local available, result = M.config.validate_cli()
  M.state.cli_available = available

  if not available then
    vim.notify('cursor.vim: ' .. result, vim.log.levels.ERROR)
    return false
  end

  -- Lazy load other modules
  M.cli = require('cursor.cli')
  M.ui = require('cursor.ui')
  M.ask = require('cursor.ask')
  M.chat = require('cursor.chat')
  M.apply = require('cursor.apply')

  M.state.initialized = true

  if M.config.get().debug then
    vim.notify('cursor.vim initialized successfully', vim.log.levels.INFO)
  end

  return true
end

-- Get plugin status
function M.status()
  local status = {
    initialized = M.state.initialized,
    cli_available = M.state.cli_available,
    config = M.config.get(),
  }

  -- Display status in a floating window
  if M.ui then
    local lines = {
      'cursor.vim Status',
      '==================',
      '',
      'Initialized: ' .. tostring(status.initialized),
      'CLI Available: ' .. tostring(status.cli_available),
      'CLI Path: ' .. status.config.cli_path,
      'Model: ' .. status.config.model,
      'Timeout: ' .. status.config.timeout .. 'ms',
      '',
      'UI Settings:',
      '  Window Type: ' .. status.config.ui.window_type,
      '  Border: ' .. status.config.ui.border,
      '',
      'Chat Settings:',
      '  Save History: ' .. tostring(status.config.chat.save_history),
      '  Max Context: ' .. status.config.chat.max_context,
    }

    M.ui.show_info(lines, 'Cursor Status')
  else
    print(vim.inspect(status))
  end

  return status
end

return M

