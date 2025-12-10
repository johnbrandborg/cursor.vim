" Main module initialization for cursor.vim (Vim implementation)
" Maintainer: John Brandborg

" Module state
let s:state = {
  \ 'initialized': v:false,
  \ 'cli_available': v:false,
  \ 'active_chat': v:null,
  \ 'last_response': v:null,
  \ }

" Setup function
function! cursor#init#Setup() abort
  if s:state.initialized
    call cursor#ui#ShowProgress('cursor.vim already initialized')
    return v:false
  endif

  " Initialize configuration
  call cursor#config#Init()

  " Validate CLI availability
  let [l:available, l:result] = cursor#config#ValidateCli()
  let s:state.cli_available = l:available

  if !l:available
    call cursor#ui#ShowError(l:result, 'cursor.vim Error')
    return v:false
  endif

  let s:state.initialized = v:true

  let l:config = cursor#config#Get()
  if l:config.debug
    call cursor#ui#ShowProgress('cursor.vim initialized successfully')
  endif

  " Trigger setup complete event
  doautocmd User CursorSetupComplete

  return v:true
endfunction

" Get plugin status
function! cursor#init#Status() abort
  let l:config = cursor#config#Get()

  let l:lines = [
    \ 'cursor.vim Status',
    \ '==================',
    \ '',
    \ 'Initialized: ' . string(s:state.initialized),
    \ 'CLI Available: ' . string(s:state.cli_available),
    \ 'CLI Path: ' . l:config.cli_path,
    \ 'Model: ' . l:config.model,
    \ 'Timeout: ' . l:config.timeout . 'ms',
    \ '',
    \ 'UI Settings:',
    \ '  Window Type: ' . l:config.ui.window_type,
    \ '  Border: ' . l:config.ui.border,
    \ '',
    \ 'Chat Settings:',
    \ '  Save History: ' . string(l:config.chat.save_history),
    \ '  Max Context: ' . l:config.chat.max_context,
    \ '',
    \ 'Active Jobs: ' . len(cursor#cli#GetActiveJobs()),
    \ ]

  call cursor#ui#ShowInfo(l:lines, 'Cursor Status')
endfunction

" Get state
function! cursor#init#GetState() abort
  return s:state
endfunction

" Set last response (for apply feature)
function! cursor#init#SetLastResponse(response) abort
  let s:state.last_response = a:response
endfunction

" Get last response
function! cursor#init#GetLastResponse() abort
  return s:state.last_response
endfunction

