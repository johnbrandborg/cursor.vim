" Cursor CLI interface for cursor.vim (Vim implementation)
" Maintainer: John Brandborg

" Active jobs
let s:jobs = {}
let s:request_id_counter = 0

" Generate unique request ID
function! s:GenRequestId() abort
  let s:request_id_counter += 1
  return 'req_' . localtime() . '_' . s:request_id_counter
endfunction

" Execute Cursor CLI command
function! cursor#cli#Execute(args, Callback) abort
  let l:config = cursor#config#Get()
  let l:request_id = s:GenRequestId()

  let l:stdout_data = []
  let l:stderr_data = []

  " Build command
  let l:cmd = [l:config.cli_path] + a:args

  " Define callbacks
  let l:options = {
    \ 'out_cb': function('s:OutCallback', [l:stdout_data]),
    \ 'err_cb': function('s:ErrCallback', [l:stderr_data]),
    \ 'exit_cb': function('s:ExitCallback', [l:request_id, l:stdout_data, l:stderr_data, a:Callback]),
    \ 'mode': 'raw',
    \ }

  " Start job
  let l:job = job_start(l:cmd, l:options)

  if job_status(l:job) ==# 'fail'
    call a:Callback(v:null, 'Failed to start Cursor CLI')
    return l:request_id
  endif

  " Store job info
  let s:jobs[l:request_id] = {
    \ 'job': l:job,
    \ 'started_at': localtime(),
    \ 'timer': v:null,
    \ }

  " Setup timeout
  if l:config.timeout > 0
    let s:jobs[l:request_id].timer = timer_start(
      \ l:config.timeout,
      \ function('s:TimeoutCallback', [l:request_id, a:Callback])
      \ )
  endif

  return l:request_id
endfunction

" Stdout callback
function! s:OutCallback(data_list, channel, msg) abort
  call add(a:data_list, a:msg)
endfunction

" Stderr callback
function! s:ErrCallback(data_list, channel, msg) abort
  call add(a:data_list, a:msg)
endfunction

" Exit callback
function! s:ExitCallback(request_id, stdout_data, stderr_data, Callback, job, status) abort
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
    call a:Callback(v:null, l:error_msg)
    return
  endif

  " Return stdout data
  let l:output = join(a:stdout_data, '')
  call a:Callback(l:output, v:null)
endfunction

" Timeout callback
function! s:TimeoutCallback(request_id, Callback, timer_id) abort
  if !has_key(s:jobs, a:request_id)
    return
  endif

  let l:job = s:jobs[a:request_id].job

  " Stop the job
  call job_stop(l:job, 'term')

  " Remove from tracking
  unlet s:jobs[a:request_id]

  " Call callback with timeout error
  let l:config = cursor#config#Get()
  call a:Callback(v:null, 'Request timed out after ' . l:config.timeout . 'ms')
endfunction

" Ask command - simple question/answer
function! cursor#cli#Ask(prompt, context, Callback) abort
  let l:args = ['ask', a:prompt]

  " Add context if provided
  if !empty(a:context)
    let l:args += ['--context', a:context]
  endif

  return cursor#cli#Execute(l:args, a:Callback)
endfunction

" Chat command - conversational interface
function! cursor#cli#Chat(message, history, Callback) abort
  let l:args = ['chat', a:message]

  " Add conversation history if provided
  if !empty(a:history)
    let l:args += ['--history', json_encode(a:history)]
  endif

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

