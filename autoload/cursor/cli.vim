" Cursor CLI interface for cursor.vim (Vim implementation)
" Maintainer: John Brandborg

" Active jobs
let s:jobs = {}
let s:request_id_counter = 0

" Resolved CLI command (cached after first resolution)
let s:resolved_cli_cmd = v:null

" Generate unique request ID
function! s:GenRequestId() abort
  let s:request_id_counter += 1
  return 'req_' . localtime() . '_' . s:request_id_counter
endfunction

" Resolve cursor-agent to the actual node binary
" This is needed because the bash wrapper doesn't work properly with job_start
function! s:ResolveCursorAgentCommand(cli_path) abort
  " Return cached result if available
  if s:resolved_cli_cmd isnot v:null
    return s:resolved_cli_cmd
  endif

  " Check if cli_path is the cursor-agent wrapper
  if executable(a:cli_path)
    " Try to resolve symlink and find the actual node binary
    let l:resolved = resolve(a:cli_path)
    let l:dir = fnamemodify(l:resolved, ':h')
    let l:node_bin = l:dir . '/node'
    let l:index_js = l:dir . '/index.js'

    " Check if node binary and index.js exist
    if executable(l:node_bin) && filereadable(l:index_js)
      let s:resolved_cli_cmd = [l:node_bin, '--use-system-ca', l:index_js]
      return s:resolved_cli_cmd
    endif
  endif

  " Fallback to original cli_path
  let s:resolved_cli_cmd = [a:cli_path]
  return s:resolved_cli_cmd
endfunction

" Execute Cursor CLI command
function! cursor#cli#Execute(args, Callback) abort
  let l:config = cursor#config#Get()
  let l:request_id = s:GenRequestId()

  let l:stdout_data = []
  let l:stderr_data = []

  " Build command - resolve cursor-agent to node binary for better job_start compatibility
  let l:cli_cmd = s:ResolveCursorAgentCommand(l:config.cli_path)
  let l:cmd = l:cli_cmd + a:args

  " Debug logging
  if l:config.debug
    echom 'cursor.vim CLI: Executing command: ' . string(l:cmd)
  endif

  " Define callbacks
  let l:options = {
    \ 'out_cb': function('s:OutCallback', [l:stdout_data]),
    \ 'err_cb': function('s:ErrCallback', [l:stderr_data]),
    \ 'exit_cb': function('s:ExitCallback', [l:request_id, l:stdout_data, l:stderr_data, a:Callback]),
    \ 'mode': 'nl',
    \ 'noblock': 1,
    \ 'in_io': 'null',
    \ }

  " Start job
  let l:job = job_start(l:cmd, l:options)

  let l:status = job_status(l:job)
  if l:status ==# 'fail'
    call a:Callback(v:null, 'Failed to start Cursor CLI')
    return l:request_id
  endif

  if l:config.debug
    echom 'cursor.vim CLI: Job started with status: ' . l:status
    echom 'cursor.vim CLI: Job info: ' . string(job_info(l:job))
  endif

  " Store job info
  let s:jobs[l:request_id] = {
    \ 'job': l:job,
    \ 'started_at': localtime(),
    \ 'timer': v:null,
    \ }

  " Setup timeout (only if > 0, set to 0 to disable)
  if l:config.timeout > 0
    let s:jobs[l:request_id].timer = timer_start(
      \ l:config.timeout,
      \ function('s:TimeoutCallback', [l:request_id, a:Callback])
      \ )
  else
    if l:config.debug
      echom 'cursor.vim CLI: Timeout disabled'
    endif
  endif

  return l:request_id
endfunction

" Stdout callback
function! s:OutCallback(data_list, channel, msg) abort
  call add(a:data_list, a:msg)
  " Debug output (don't call config here as it might cause issues)
  echom 'cursor.vim CLI: stdout chunk: ' . len(a:msg) . ' bytes'
endfunction

" Stderr callback
function! s:ErrCallback(data_list, channel, msg) abort
  call add(a:data_list, a:msg)
  " Debug output
  echom 'cursor.vim CLI: stderr chunk: ' . len(a:msg) . ' bytes'
  if len(a:msg) < 200
    echom 'cursor.vim CLI: stderr: ' . a:msg
  endif
endfunction

" Exit callback
function! s:ExitCallback(request_id, stdout_data, stderr_data, Callback, job, status) abort
  let l:config = cursor#config#Get()

  " Debug logging
  if l:config.debug
    echom 'cursor.vim CLI: Exit callback - status: ' . a:status
    echom 'cursor.vim CLI: stdout chunks: ' . len(a:stdout_data)
    echom 'cursor.vim CLI: stderr chunks: ' . len(a:stderr_data)
  endif

  " Cancel timeout timer
  if has_key(s:jobs, a:request_id) && s:jobs[a:request_id].timer isnot v:null
    call timer_stop(s:jobs[a:request_id].timer)
  endif

  " Remove job from tracking
  if has_key(s:jobs, a:request_id)
    unlet s:jobs[a:request_id]
  endif

  " Check exit status
  if a:status != 0
    let l:error_msg = join(a:stderr_data, '')
    if empty(l:error_msg)
      let l:error_msg = 'Process exited with code ' . a:status
    endif
    if l:config.debug
      echom 'cursor.vim CLI: Error: ' . l:error_msg
    endif
    call a:Callback(v:null, l:error_msg)
    return
  endif

  " Return stdout data
  let l:output = join(a:stdout_data, '')
  if l:config.debug
    echom 'cursor.vim CLI: Output length: ' . len(l:output)
    if len(l:output) > 0
      echom 'cursor.vim CLI: First 100 chars: ' . l:output[:100]
    endif
  endif
  call a:Callback(l:output, v:null)
endfunction

" Timeout callback
function! s:TimeoutCallback(request_id, Callback, timer_id) abort
  if !has_key(s:jobs, a:request_id)
    return
  endif

  let l:config = cursor#config#Get()
  let l:job = s:jobs[a:request_id].job

  " Debug logging
  if l:config.debug
    echom 'cursor.vim CLI: Request timed out after ' . l:config.timeout . 'ms'
  endif

  " Stop the job
  call job_stop(l:job, 'term')

  " Remove from tracking
  unlet s:jobs[a:request_id]

  " Call callback with timeout error
  call a:Callback(v:null, 'Request timed out after ' . l:config.timeout . 'ms')
endfunction

" Ask command - simple question/answer
function! cursor#cli#Ask(prompt, context, Callback) abort
  " Build full prompt with context
  let l:full_prompt = a:prompt
  if !empty(a:context)
    let l:full_prompt = a:prompt . "\n\nContext:\n```\n" . a:context . "\n```"
  endif

  let l:args = ['--print', l:full_prompt]

  return cursor#cli#Execute(l:args, a:Callback)
endfunction

" Chat command - conversational interface
function! cursor#cli#Chat(message, history, Callback) abort
  " Build message with history context
  let l:full_message = a:message
  if !empty(a:history)
    let l:full_message = "Previous conversation:\n" . json_encode(a:history) . "\n\n" . a:message
  endif

  let l:args = ['--print', l:full_message]

  return cursor#cli#Execute(l:args, a:Callback)
endfunction

" Cancel a request
function! cursor#cli#Cancel(request_id) abort
  if !has_key(s:jobs, a:request_id)
    return [v:false, 'Request not found']
  endif

  let l:job = s:jobs[a:request_id].job

  " Stop timer if exists
  if s:jobs[a:request_id].timer isnot v:null
    call timer_stop(s:jobs[a:request_id].timer)
  endif

  " Stop job
  call job_stop(l:job, 'term')

  " Remove from tracking
  unlet s:jobs[a:request_id]

  return [v:true, 'Request cancelled']
endfunction

" Get active jobs
function! cursor#cli#GetActiveJobs() abort
  let l:active = []

  for [l:id, l:job_info] in items(s:jobs)
    call add(l:active, {
      \ 'id': l:id,
      \ 'started_at': l:job_info.started_at,
      \ 'status': job_status(l:job_info.job),
      \ })
  endfor

  return l:active
endfunction

