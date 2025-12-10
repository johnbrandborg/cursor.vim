-- Chat feature implementation for cursor.vim
local M = {}

local cli = require('cursor.cli')
local ui = require('cursor.ui')
local config = require('cursor.config')

-- Chat state
M.state = {
  active_chat = nil,
  history = {},
  chat_buf = nil,
  chat_win = nil,
}

-- Format chat history for display
local function format_chat_display(history)
  local lines = {}

  table.insert(lines, '# Cursor Chat')
  table.insert(lines, '')
  table.insert(lines, 'Type your message below and press <CR> to send')
  table.insert(lines, 'Commands: :CursorChatClear (clear) | :CursorChatSave (save) | q (quit)')
  table.insert(lines, string.rep('=', 60))
  table.insert(lines, '')

  for i, msg in ipairs(history) do
    if msg.role == 'user' then
      table.insert(lines, '## You:')
      table.insert(lines, '')
      table.insert(lines, msg.content)
    elseif msg.role == 'assistant' then
      table.insert(lines, '## Cursor:')
      table.insert(lines, '')
      -- Split content into lines
      local content_lines = vim.split(msg.content, '\n', { plain = true })
      for _, line in ipairs(content_lines) do
        table.insert(lines, line)
      end
    end
    table.insert(lines, '')
    table.insert(lines, string.rep('-', 60))
    table.insert(lines, '')
  end

  table.insert(lines, '## Your message:')
  table.insert(lines, '')

  return lines
end

-- Create chat window
function M.open_chat()
  if M.state.chat_buf and vim.api.nvim_buf_is_valid(M.state.chat_buf) then
    -- Chat window already exists, focus it
    if M.state.chat_win and vim.api.nvim_win_is_valid(M.state.chat_win) then
      vim.api.nvim_set_current_win(M.state.chat_win)
      return
    end
  end

  -- Create new chat buffer
  local buf = vim.api.nvim_create_buf(false, true)
  M.state.chat_buf = buf

  -- Set buffer options
  vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(buf, 'bufhidden', 'hide')
  vim.api.nvim_buf_set_option(buf, 'filetype', 'cursorchat')
  vim.api.nvim_buf_set_option(buf, 'swapfile', false)

  -- Create window (using float by default for chat)
  local cfg = config.get()

  local width = math.floor(vim.o.columns * 0.8)
  local height = math.floor(vim.o.lines * 0.8)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  local win_opts = {
    relative = 'editor',
    width = width,
    height = height,
    row = row,
    col = col,
    style = 'minimal',
    border = cfg.ui.border,
    title = ' Cursor Chat ',
    title_pos = 'center',
  }

  local win = vim.api.nvim_open_win(buf, true, win_opts)
  M.state.chat_win = win

  -- Display current history
  local lines = format_chat_display(M.state.history)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  -- Set up keymaps
  M.setup_chat_keymaps(buf)

  -- Move cursor to end
  vim.api.nvim_win_set_cursor(win, { #lines, 0 })
  vim.cmd('startinsert')
end

-- Setup keymaps for chat buffer
function M.setup_chat_keymaps(buf)
  -- Send message on Enter (in insert mode)
  vim.api.nvim_buf_set_keymap(
    buf,
    'i',
    '<CR>',
    '<Esc>:lua require("cursor.chat").send_message()<CR>',
    { noremap = true, silent = true }
  )

  -- Close on q (in normal mode)
  vim.api.nvim_buf_set_keymap(
    buf,
    'n',
    'q',
    ':lua require("cursor.chat").close_chat()<CR>',
    { noremap = true, silent = true }
  )

  -- Clear chat
  vim.api.nvim_buf_set_keymap(
    buf,
    'n',
    '<leader>cc',
    ':lua require("cursor.chat").clear_history()<CR>',
    { noremap = true, silent = true }
  )
end

-- Send message from chat buffer
function M.send_message()
  if not M.state.chat_buf or not vim.api.nvim_buf_is_valid(M.state.chat_buf) then
    return
  end

  -- Get all lines
  local lines = vim.api.nvim_buf_get_lines(M.state.chat_buf, 0, -1, false)

  -- Find the last "Your message:" section
  local message_start = nil
  for i = #lines, 1, -1 do
    if lines[i]:match('^## Your message:') then
      message_start = i + 1
      break
    end
  end

  if not message_start then
    vim.notify('Could not find message input area', vim.log.levels.ERROR)
    return
  end

  -- Extract message (skip empty line after header)
  local message_lines = {}
  for i = message_start + 1, #lines do
    if lines[i] ~= '' or #message_lines > 0 then
      table.insert(message_lines, lines[i])
    end
  end

  -- Remove trailing empty lines
  while #message_lines > 0 and message_lines[#message_lines] == '' do
    table.remove(message_lines)
  end

  local message = table.concat(message_lines, '\n')

  if message == '' then
    vim.notify('Empty message', vim.log.levels.WARN)
    return
  end

  -- Add user message to history
  table.insert(M.state.history, {
    role = 'user',
    content = message,
  })

  -- Show loading indicator
  ui.show_progress('Sending message to Cursor AI...')

  -- Prepare history for CLI (limit context)
  local cfg = config.get()
  local history_for_cli = {}
  local start_idx = math.max(1, #M.state.history - cfg.chat.max_context)
  for i = start_idx, #M.state.history do
    table.insert(history_for_cli, M.state.history[i])
  end

  -- Send to CLI
  cli.chat(message, history_for_cli, function(response, err)
    if err then
      vim.notify('cursor.vim: ' .. err, vim.log.levels.ERROR)
      -- Remove the user message from history since it failed
      table.remove(M.state.history)
      return
    end

    -- Add assistant response to history
    table.insert(M.state.history, {
      role = 'assistant',
      content = response,
    })

    -- Update display
    M.refresh_display()
  end)
end

-- Refresh chat display
function M.refresh_display()
  if not M.state.chat_buf or not vim.api.nvim_buf_is_valid(M.state.chat_buf) then
    return
  end

  local lines = format_chat_display(M.state.history)

  -- Update buffer
  vim.api.nvim_buf_set_option(M.state.chat_buf, 'modifiable', true)
  vim.api.nvim_buf_set_lines(M.state.chat_buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(M.state.chat_buf, 'modifiable', true)

  -- Move cursor to end
  if M.state.chat_win and vim.api.nvim_win_is_valid(M.state.chat_win) then
    vim.api.nvim_win_set_cursor(M.state.chat_win, { #lines, 0 })
  end

  vim.cmd('startinsert')
end

-- Clear chat history
function M.clear_history()
  M.state.history = {}
  M.refresh_display()
  vim.notify('Chat history cleared', vim.log.levels.INFO)
end

-- Close chat window
function M.close_chat()
  if M.state.chat_win and vim.api.nvim_win_is_valid(M.state.chat_win) then
    vim.api.nvim_win_close(M.state.chat_win, false)
  end
  M.state.chat_win = nil
end

-- Save chat history to file
function M.save_history(filename)
  local cfg = config.get()

  if not cfg.chat.save_history then
    vim.notify('Chat history saving is disabled', vim.log.levels.WARN)
    return
  end

  filename = filename or os.date('%Y%m%d_%H%M%S') .. '_chat.json'
  local filepath = cfg.chat.history_dir .. '/' .. filename

  local json = vim.json.encode(M.state.history)

  local file = io.open(filepath, 'w')
  if not file then
    vim.notify('Failed to save chat history', vim.log.levels.ERROR)
    return
  end

  file:write(json)
  file:close()

  vim.notify('Chat history saved to ' .. filepath, vim.log.levels.INFO)
end

-- Load chat history from file
function M.load_history(filepath)
  local file = io.open(filepath, 'r')
  if not file then
    vim.notify('Failed to load chat history', vim.log.levels.ERROR)
    return
  end

  local content = file:read('*a')
  file:close()

  local ok, history = pcall(vim.json.decode, content)
  if not ok then
    vim.notify('Failed to parse chat history', vim.log.levels.ERROR)
    return
  end

  M.state.history = history
  M.refresh_display()

  vim.notify('Chat history loaded', vim.log.levels.INFO)
end

-- Get current chat history
function M.get_history()
  return M.state.history
end

return M

