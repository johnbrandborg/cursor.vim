-- Cursor CLI interface for cursor.vim
local M = {}

local config = require('cursor.config')
local uv = vim.loop

-- Active processes
M.processes = {}

-- Generate unique request ID
local function gen_request_id()
  return tostring(os.time()) .. '_' .. tostring(math.random(10000, 99999))
end

-- Parse JSON response from CLI
local function parse_response(data)
  if not data or data == '' then
    return nil, 'Empty response'
  end

  local ok, result = pcall(vim.json.decode, data)
  if not ok then
    return nil, 'Failed to parse JSON: ' .. tostring(result)
  end

  return result, nil
end

-- Execute Cursor CLI command
function M.execute(args, callback)
  local cfg = config.get()
  local request_id = gen_request_id()

  local stdout_data = {}
  local stderr_data = {}

  local stdout = uv.new_pipe(false)
  local stderr = uv.new_pipe(false)

  local full_args = vim.list_extend({}, args)

  local handle, pid
  handle, pid = uv.spawn(cfg.cli_path, {
    args = full_args,
    stdio = { nil, stdout, stderr },
  }, function(code, signal)
    -- Process exit callback
    stdout:close()
    stderr:close()

    if handle and not handle:is_closing() then
      handle:close()
    end

    M.processes[request_id] = nil

    if code ~= 0 then
      local error_msg = table.concat(stderr_data, '')
      if error_msg == '' then
        error_msg = 'Process exited with code ' .. code
      end
      callback(nil, error_msg)
      return
    end

    local output = table.concat(stdout_data, '')
    callback(output, nil)
  end)

  if not handle then
    callback(nil, 'Failed to spawn process: ' .. tostring(pid))
    return request_id
  end

  -- Store process info
  M.processes[request_id] = {
    handle = handle,
    pid = pid,
    started_at = os.time(),
  }

  -- Read stdout
  stdout:read_start(function(err, data)
    if err then
      vim.schedule(function()
        vim.notify('cursor.vim: stdout error: ' .. err, vim.log.levels.ERROR)
      end)
      return
    end

    if data then
      table.insert(stdout_data, data)
    end
  end)

  -- Read stderr
  stderr:read_start(function(err, data)
    if err then
      vim.schedule(function()
        vim.notify('cursor.vim: stderr error: ' .. err, vim.log.levels.ERROR)
      end)
      return
    end

    if data then
      table.insert(stderr_data, data)
    end
  end)

  -- Setup timeout
  if cfg.timeout > 0 then
    local timer = uv.new_timer()
    timer:start(cfg.timeout, 0, function()
      timer:close()
      if M.processes[request_id] then
        local proc = M.processes[request_id]
        if proc.handle and not proc.handle:is_closing() then
          proc.handle:kill(15) -- SIGTERM
          vim.schedule(function()
            callback(nil, 'Request timed out after ' .. cfg.timeout .. 'ms')
          end)
        end
      end
    end)
  end

  return request_id
end

-- Ask command - simple question/answer
function M.ask(prompt, context, callback)
  local args = {
    'ask',
    prompt,
  }

  -- Add context if provided (e.g., selected code)
  if context and context ~= '' then
    table.insert(args, '--context')
    table.insert(args, context)
  end

  return M.execute(args, function(output, err)
    if err then
      vim.schedule(function()
        callback(nil, err)
      end)
      return
    end

    vim.schedule(function()
      callback(output, nil)
    end)
  end)
end

-- Chat command - conversational interface
function M.chat(message, history, callback)
  local args = {
    'chat',
    message,
  }

  -- Add conversation history if provided
  if history and #history > 0 then
    table.insert(args, '--history')
    table.insert(args, vim.json.encode(history))
  end

  return M.execute(args, function(output, err)
    if err then
      vim.schedule(function()
        callback(nil, err)
      end)
      return
    end

    vim.schedule(function()
      callback(output, nil)
    end)
  end)
end

-- Cancel a request
function M.cancel(request_id)
  local proc = M.processes[request_id]
  if not proc then
    return false, 'Request not found'
  end

  if proc.handle and not proc.handle:is_closing() then
    proc.handle:kill(15)
    M.processes[request_id] = nil
    return true, 'Request cancelled'
  end

  return false, 'Process already terminated'
end

-- Get active processes
function M.get_active_processes()
  local active = {}
  for id, proc in pairs(M.processes) do
    table.insert(active, {
      id = id,
      pid = proc.pid,
      started_at = proc.started_at,
    })
  end
  return active
end

return M

