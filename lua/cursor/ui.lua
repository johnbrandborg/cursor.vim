-- UI components for cursor.vim
local M = {}

local config = require('cursor.config')

-- Store floating window state
M.float_state = {
  buf = nil,
  win = nil,
}

-- Calculate centered floating window dimensions
local function calc_float_dims()
  local cfg = config.get()
  local width = math.floor(vim.o.columns * cfg.ui.float_width)
  local height = math.floor(vim.o.lines * cfg.ui.float_height)

  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  return {
    relative = 'editor',
    width = width,
    height = height,
    row = row,
    col = col,
    style = 'minimal',
    border = cfg.ui.border,
  }
end

-- Create a floating window
function M.create_float(lines, opts)
  opts = opts or {}
  local cfg = config.get()

  -- Create buffer
  local buf = vim.api.nvim_create_buf(false, true)

  -- Set buffer options
  vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
  vim.api.nvim_buf_set_option(buf, 'filetype', opts.filetype or 'markdown')

  -- Set content
  if lines then
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  end

  -- Make buffer read-only if specified
  if opts.readonly ~= false then
    vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  end

  -- Calculate window options
  local win_opts = calc_float_dims()
  if opts.title then
    win_opts.title = opts.title
    win_opts.title_pos = 'center'
  end

  -- Create window
  local win = vim.api.nvim_open_win(buf, true, win_opts)

  -- Set window options
  vim.api.nvim_win_set_option(win, 'wrap', true)
  vim.api.nvim_win_set_option(win, 'linebreak', true)

  -- Add close keymap
  vim.api.nvim_buf_set_keymap(
    buf,
    'n',
    'q',
    ':close<CR>',
    { noremap = true, silent = true }
  )

  vim.api.nvim_buf_set_keymap(
    buf,
    'n',
    '<Esc>',
    ':close<CR>',
    { noremap = true, silent = true }
  )

  return buf, win
end

-- Create a split window
function M.create_split(lines, opts)
  opts = opts or {}
  local cfg = config.get()

  -- Determine split command
  local split_cmd
  if cfg.ui.window_type == 'vsplit' then
    split_cmd = 'vsplit'
  else
    split_cmd = 'split'
  end

  -- Create split
  vim.cmd(split_cmd)

  -- Resize
  if cfg.ui.window_type == 'vsplit' then
    vim.cmd('vertical resize ' .. cfg.ui.split_size)
  else
    vim.cmd('resize ' .. cfg.ui.split_size)
  end

  -- Get buffer and window
  local buf = vim.api.nvim_get_current_buf()
  local win = vim.api.nvim_get_current_win()

  -- Set buffer options
  vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
  vim.api.nvim_buf_set_option(buf, 'filetype', opts.filetype or 'markdown')

  -- Set content
  if lines then
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  end

  -- Make buffer read-only if specified
  if opts.readonly ~= false then
    vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  end

  return buf, win
end

-- Show response in appropriate window type
function M.show_response(lines, opts)
  opts = opts or {}
  local cfg = config.get()

  if cfg.ui.window_type == 'float' then
    return M.create_float(lines, opts)
  else
    return M.create_split(lines, opts)
  end
end

-- Show info message (always floating)
function M.show_info(lines, title)
  return M.create_float(lines, {
    title = title or 'Info',
    readonly = true,
  })
end

-- Show error message
function M.show_error(message, title)
  local lines = vim.split(message, '\n')
  return M.create_float(lines, {
    title = title or 'Error',
    readonly = true,
    filetype = 'text',
  })
end

-- Show loading indicator
function M.show_loading(message)
  message = message or 'Loading...'

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { message })
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)

  local width = #message + 4
  local height = 3

  local win_opts = {
    relative = 'editor',
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    style = 'minimal',
    border = 'rounded',
  }

  local win = vim.api.nvim_open_win(buf, false, win_opts)

  return buf, win
end

-- Close window
function M.close_window(win)
  if win and vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_win_close(win, true)
  end
end

-- Append lines to buffer
function M.append_to_buffer(buf, lines)
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    return false
  end

  -- Make buffer modifiable temporarily
  vim.api.nvim_buf_set_option(buf, 'modifiable', true)

  -- Get current line count
  local line_count = vim.api.nvim_buf_line_count(buf)

  -- Append lines
  vim.api.nvim_buf_set_lines(buf, line_count, -1, false, lines)

  -- Make buffer read-only again
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)

  return true
end

-- Update buffer content
function M.update_buffer(buf, lines)
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    return false
  end

  -- Make buffer modifiable temporarily
  vim.api.nvim_buf_set_option(buf, 'modifiable', true)

  -- Set lines
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  -- Make buffer read-only again
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)

  return true
end

-- Create progress notification
function M.show_progress(message)
  vim.notify(message, vim.log.levels.INFO)
end

return M

