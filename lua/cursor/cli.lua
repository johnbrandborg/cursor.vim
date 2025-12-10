-- Cursor CLI interface for cursor.vim
local M = {}

local config = require('cursor.config')
local uv = vim.loop

-- Active processes
M.processes = {}

-- Resolved CLI command (cached after first resolution)
local resolved_cli_cmd = nil

-- Generate unique request ID
local function gen_request_id()
  return tostring(os.time()) .. '_' .. tostring(math.random(10000, 99999))
end

-- Resolve cursor-agent to the actual node binary
-- This improves compatibility with job/process spawning
local function resolve_cursor_agent_command(cli_path)
  -- Return cached result if available
  if resolved_cli_cmd then
    return resolved_cli_cmd.path, resolved_cli_cmd.args
  end

  -- Check if cli_path exists and is executable
  if vim.fn.executable(cli_path) == 1 then
    -- Try to resolve symlink
    local resolved = vim.fn.resolve(cli_path)
    local dir = vim.fn.fnamemodify(resolved, ':h')
    local node_bin = dir .. '/node'
    local index_js = dir .. '/index.js'

    -- Check if node binary and index.js exist
    if vim.fn.executable(node_bin) == 1 and vim.fn.filereadable(index_js) == 1 then
      resolved_cli_cmd = {
        path = node_bin,
        args = { '--use-system-ca', index_js }
      }
      return resolved_cli_cmd.path, resolved_cli_cmd.args
    end
  end

  -- Fallback to original cli_path
  resolved_cli_cmd = {
    path = cli_path,
    args = {}
  }
  return resolved_cli_cmd.path, resolved_cli_cmd.args
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

  -- Resolve cursor-agent to node binary for better process spawning
  local cli_path, cli_base_args = resolve_cursor_agent_command(cfg.cli_path)
  local full_args = vim.list_extend(vim.list_extend({}, cli_base_args), args)

  local handle, pid
  handle, pid = uv.spawn(cli_path, {
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
  -- Build full prompt with context
  local full_prompt = prompt
  if context and context ~= '' then
    full_prompt = prompt .. "\n\nContext:\n```\n" .. context .. "\n```"
  end

  local args = {
    '--print',
    full_prompt,
  }

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
  -- Build message with history context
  local full_message = message
  if history and #history > 0 then
    full_message = "Previous conversation:\n" .. vim.json.encode(history) .. "\n\n" .. message
  end

  local args = {
    '--print',
    full_message,
  }

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

