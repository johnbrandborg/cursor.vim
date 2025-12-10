-- Code application logic for cursor.vim
local M = {}

local ask = require('cursor.ask')
local chat = require('cursor.chat')
local ui = require('cursor.ui')

-- Parse code blocks from markdown response
local function parse_code_blocks(text)
  if not text then
    return {}
  end

  local blocks = {}
  local in_block = false
  local current_block = nil

  for line in text:gmatch('[^\r\n]+') do
    -- Check for code block start
    local lang = line:match('^```(%w*)')
    if lang then
      if not in_block then
        -- Start of code block
        in_block = true
        current_block = {
          language = lang ~= '' and lang or 'text',
          lines = {},
        }
      else
        -- End of code block
        in_block = false
        if current_block then
          table.insert(blocks, current_block)
          current_block = nil
        end
      end
    elseif in_block and current_block then
      -- Inside code block, collect lines
      table.insert(current_block.lines, line)
    end
  end

  return blocks
end

-- Detect file type from current buffer or block language
local function detect_filetype(block, current_buf)
  if block.language and block.language ~= 'text' then
    return block.language
  end

  if current_buf and vim.api.nvim_buf_is_valid(current_buf) then
    return vim.api.nvim_buf_get_option(current_buf, 'filetype')
  end

  return 'text'
end

-- Apply code block to buffer
local function apply_to_buffer(buf, lines, opts)
  opts = opts or {}

  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    return false, 'Invalid buffer'
  end

  -- Check if buffer is modifiable
  if not vim.api.nvim_buf_get_option(buf, 'modifiable') then
    return false, 'Buffer is not modifiable'
  end

  if opts.mode == 'replace' then
    -- Replace entire buffer
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  elseif opts.mode == 'append' then
    -- Append to buffer
    local line_count = vim.api.nvim_buf_line_count(buf)
    vim.api.nvim_buf_set_lines(buf, line_count, -1, false, lines)
  elseif opts.mode == 'insert' then
    -- Insert at cursor position
    local cursor = vim.api.nvim_win_get_cursor(0)
    local row = cursor[1]
    vim.api.nvim_buf_set_lines(buf, row, row, false, lines)
  else
    return false, 'Unknown mode: ' .. tostring(opts.mode)
  end

  return true, 'Applied successfully'
end

-- Preview code changes
local function preview_code(blocks)
  if #blocks == 0 then
    vim.notify('No code blocks found in response', vim.log.levels.WARN)
    return
  end

  local preview_lines = {}

  table.insert(preview_lines, '# Code Blocks Preview')
  table.insert(preview_lines, '')
  table.insert(preview_lines, 'Found ' .. #blocks .. ' code block(s)')
  table.insert(preview_lines, '')

  for i, block in ipairs(blocks) do
    table.insert(preview_lines, '## Block ' .. i .. ' (' .. block.language .. ')')
    table.insert(preview_lines, '')
    table.insert(preview_lines, '```' .. block.language)
    for _, line in ipairs(block.lines) do
      table.insert(preview_lines, line)
    end
    table.insert(preview_lines, '```')
    table.insert(preview_lines, '')
  end

  ui.show_response(preview_lines, {
    title = 'Code Preview',
    readonly = true,
    filetype = 'markdown',
  })
end

-- Apply last response from ask or chat
function M.apply_last(opts)
  opts = opts or {}

  -- Get last response
  local response, prompt = ask.get_last_response()

  if not response then
    -- Try to get from chat
    local history = chat.get_history()
    if #history > 0 and history[#history].role == 'assistant' then
      response = history[#history].content
    end
  end

  if not response then
    vim.notify('No response to apply', vim.log.levels.WARN)
    return
  end

  -- Parse code blocks
  local blocks = parse_code_blocks(response)

  if #blocks == 0 then
    vim.notify('No code blocks found in response', vim.log.levels.WARN)
    return
  end

  -- Show preview first
  if opts.preview ~= false then
    preview_code(blocks)
  end

  -- Ask user which block to apply (if multiple)
  local block_to_apply = blocks[1]
  if #blocks > 1 then
    vim.ui.select(
      vim.tbl_map(function(b)
        return 'Block (' .. b.language .. ') - ' .. #b.lines .. ' lines'
      end, blocks),
      {
        prompt = 'Select code block to apply:',
      },
      function(choice, idx)
        if idx then
          block_to_apply = blocks[idx]
          M.apply_block(block_to_apply, opts)
        end
      end
    )
    return
  end

  M.apply_block(block_to_apply, opts)
end

-- Apply a specific code block
function M.apply_block(block, opts)
  opts = opts or {}

  -- Determine target buffer
  local target_buf = opts.buffer or vim.api.nvim_get_current_buf()

  -- Ask user for application mode
  local modes = {
    { label = 'Replace entire buffer', value = 'replace' },
    { label = 'Append to end', value = 'append' },
    { label = 'Insert at cursor', value = 'insert' },
  }

  if opts.mode then
    -- Mode specified, apply directly
    local ok, err = apply_to_buffer(target_buf, block.lines, opts)
    if ok then
      vim.notify('Code applied successfully', vim.log.levels.INFO)
    else
      vim.notify('Failed to apply: ' .. err, vim.log.levels.ERROR)
    end
    return
  end

  -- Ask user for mode
  vim.ui.select(
    vim.tbl_map(function(m)
      return m.label
    end, modes),
    {
      prompt = 'How to apply code?',
    },
    function(choice, idx)
      if idx then
        local mode = modes[idx].value
        local ok, err = apply_to_buffer(target_buf, block.lines, { mode = mode })
        if ok then
          vim.notify('Code applied successfully (' .. mode .. ')', vim.log.levels.INFO)
        else
          vim.notify('Failed to apply: ' .. err, vim.log.levels.ERROR)
        end
      end
    end
  )
end

-- Apply code to new buffer
function M.apply_to_new_buffer(block)
  block = block or {}

  -- Parse from last response if not provided
  if not block.lines then
    local response, _ = ask.get_last_response()
    if response then
      local blocks = parse_code_blocks(response)
      if #blocks > 0 then
        block = blocks[1]
      end
    end
  end

  if not block.lines or #block.lines == 0 then
    vim.notify('No code to apply', vim.log.levels.WARN)
    return
  end

  -- Create new buffer
  vim.cmd('enew')
  local buf = vim.api.nvim_get_current_buf()

  -- Set filetype
  local ft = detect_filetype(block, nil)
  vim.api.nvim_buf_set_option(buf, 'filetype', ft)

  -- Apply code
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, block.lines)

  vim.notify('Code applied to new buffer', vim.log.levels.INFO)
end

-- Preview last response
function M.preview_last()
  local response, _ = ask.get_last_response()

  if not response then
    local history = chat.get_history()
    if #history > 0 and history[#history].role == 'assistant' then
      response = history[#history].content
    end
  end

  if not response then
    vim.notify('No response to preview', vim.log.levels.WARN)
    return
  end

  local blocks = parse_code_blocks(response)
  preview_code(blocks)
end

return M

