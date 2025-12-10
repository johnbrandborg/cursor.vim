-- Ask feature implementation for cursor.vim
local M = {}

local cli = require('cursor.cli')
local ui = require('cursor.ui')

-- Store last response for potential apply operation
M.last_response = nil
M.last_prompt = nil

-- Get visual selection
local function get_visual_selection()
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")

  local start_line = start_pos[2]
  local end_line = end_pos[2]

  if start_line == 0 or end_line == 0 then
    return nil
  end

  local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)

  if #lines == 0 then
    return nil
  end

  return table.concat(lines, '\n')
end

-- Format response for display
local function format_response(response)
  if not response then
    return { 'No response received' }
  end

  -- Split response into lines
  local lines = vim.split(response, '\n', { plain = true })

  return lines
end

-- Execute ask command
function M.ask(prompt, opts)
  opts = opts or {}

  if not prompt or prompt == '' then
    vim.notify('cursor.vim: No prompt provided', vim.log.levels.ERROR)
    return
  end

  -- Get context if in visual mode or opts.context provided
  local context = opts.context
  if not context and opts.use_selection then
    context = get_visual_selection()
  end

  -- Show loading indicator
  ui.show_progress('Asking Cursor AI...')

  -- Build full prompt with context
  local full_prompt = prompt
  if context then
    full_prompt = prompt .. '\n\nContext:\n```\n' .. context .. '\n```'
  end

  -- Store for reference
  M.last_prompt = full_prompt

  -- Execute CLI command
  cli.ask(prompt, context, function(response, err)
    if err then
      vim.notify('cursor.vim: ' .. err, vim.log.levels.ERROR)
      ui.show_error(err, 'Cursor Ask Error')
      return
    end

    -- Store response
    M.last_response = response

    -- Format and display response
    local lines = format_response(response)

    local title = 'Cursor Ask'
    if opts.title then
      title = opts.title
    end

    ui.show_response(lines, {
      title = title,
      readonly = true,
      filetype = 'markdown',
    })

    -- Optionally copy to clipboard
    if opts.copy_to_clipboard then
      vim.fn.setreg('+', response)
      vim.notify('Response copied to clipboard', vim.log.levels.INFO)
    end
  end)
end

-- Ask with visual selection
function M.ask_visual(prompt)
  local selection = get_visual_selection()

  if not selection then
    vim.notify('cursor.vim: No visual selection', vim.log.levels.WARN)
    return
  end

  -- Get prompt from user if not provided
  if not prompt or prompt == '' then
    vim.ui.input({ prompt = 'Ask about selection: ' }, function(input)
      if input and input ~= '' then
        M.ask(input, { context = selection })
      end
    end)
  else
    M.ask(prompt, { context = selection })
  end
end

-- Ask about current buffer
function M.ask_buffer(prompt)
  local buf_content = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), '\n')
  local filename = vim.fn.expand('%:t')

  if not prompt or prompt == '' then
    vim.ui.input({ prompt = 'Ask about ' .. filename .. ': ' }, function(input)
      if input and input ~= '' then
        M.ask(input, { context = buf_content })
      end
    end)
  else
    M.ask(prompt, { context = buf_content })
  end
end

-- Interactive ask - prompt user for input
function M.ask_interactive()
  vim.ui.input({ prompt = 'Ask Cursor: ' }, function(input)
    if input and input ~= '' then
      M.ask(input)
    end
  end)
end

-- Get last response (for apply feature)
function M.get_last_response()
  return M.last_response, M.last_prompt
end

return M

