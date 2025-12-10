" Configuration management for cursor.vim (Vim implementation)
" Maintainer: John Brandborg

" Default configuration
let s:defaults = {
  \ 'cli_path': 'cursor-agent',
  \ 'model': 'claude-sonnet-4',
  \ 'timeout': 60000,
  \ 'ui': {
  \   'window_type': 'float',
  \   'float_width': 0.8,
  \   'float_height': 0.8,
  \   'split_size': 15,
  \   'border': 'rounded',
  \ },
  \ 'chat': {
  \   'save_history': v:true,
  \   'max_context': 20,
  \   'history_dir': '',
  \ },
  \ 'mappings': {
  \   'ask': '<leader>ca',
  \   'chat': '<leader>cc',
  \   'apply': '<leader>cy',
  \   'status': '<leader>cs',
  \ },
  \ 'debug': v:false,
  \ }

" Current configuration
let s:config = {}

" Initialize configuration with defaults
function! cursor#config#Init() abort
  " Set default history directory
  let l:data_dir = has('win32') ? expand('~/vimfiles') : expand('~/.vim')
  let s:defaults.chat.history_dir = l:data_dir . '/cursor_chat_history'

  " Deep copy defaults
  let s:config = s:DeepCopy(s:defaults)

  " Merge with user config if exists
  if exists('g:cursor_config')
    let s:config = s:DeepExtend(s:config, g:cursor_config)
  endif

  " Create history directory if needed
  if s:config.chat.save_history && !isdirectory(s:config.chat.history_dir)
    call mkdir(s:config.chat.history_dir, 'p')
  endif

  return s:config
endfunction

" Get current configuration
function! cursor#config#Get() abort
  if empty(s:config)
    call cursor#config#Init()
  endif
  return s:config
endfunction

" Validate that Cursor CLI is available
function! cursor#config#ValidateCli() abort
  let l:config = cursor#config#Get()
  let l:cli_path = l:config.cli_path

  if !executable(l:cli_path)
    return [v:false, 'Cursor CLI not found. Please install Cursor CLI or set cli_path in config.']
  endif

  return [v:true, l:cli_path]
endfunction

" Deep copy a dictionary/list
function! s:DeepCopy(value) abort
  if type(a:value) == v:t_dict
    let l:result = {}
    for [l:key, l:val] in items(a:value)
      let l:result[l:key] = s:DeepCopy(l:val)
    endfor
    return l:result
  elseif type(a:value) == v:t_list
    return map(copy(a:value), 's:DeepCopy(v:val)')
  else
    return a:value
  endif
endfunction

" Deep extend dict1 with dict2
function! s:DeepExtend(dict1, dict2) abort
  let l:result = s:DeepCopy(a:dict1)

  for [l:key, l:val] in items(a:dict2)
    if type(l:val) == v:t_dict && has_key(l:result, l:key) && type(l:result[l:key]) == v:t_dict
      let l:result[l:key] = s:DeepExtend(l:result[l:key], l:val)
    else
      let l:result[l:key] = s:DeepCopy(l:val)
    endif
  endfor

  return l:result
endfunction

