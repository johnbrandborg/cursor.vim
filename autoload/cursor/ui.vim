" UI components for cursor.vim (Vim implementation)
" Maintainer: John Brandborg

" Show response in appropriate window type
function! cursor#ui#ShowResponse(lines, opts) abort
  let l:config = cursor#config#Get()
  let l:opts = extend({'title': 'Cursor Response', 'readonly': v:true, 'filetype': 'markdown'}, a:opts)

  if l:config.ui.window_type ==# 'float' && exists('*popup_create')
    return cursor#ui#CreateFloat(a:lines, l:opts)
  else
    return cursor#ui#CreateSplit(a:lines, l:opts)
  endif
endfunction

" Create floating window using popup
function! cursor#ui#CreateFloat(lines, opts) abort
  let l:config = cursor#config#Get()
  let l:opts = a:opts

  " Calculate dimensions
  let l:width = float2nr(&columns * l:config.ui.float_width)
  let l:height = float2nr(&lines * l:config.ui.float_height)

  " Create popup options
  let l:popup_opts = {
    \ 'line': 'cursor',
    \ 'col': 'cursor',
    \ 'minwidth': l:width,
    \ 'minheight': l:height,
    \ 'maxwidth': l:width,
    \ 'maxheight': l:height,
    \ 'pos': 'center',
    \ 'drag': v:true,
    \ 'resize': v:true,
    \ 'close': 'button',
    \ 'padding': [1, 1, 1, 1],
    \ 'scrollbar': 1,
    \ 'wrap': v:true,
    \ }

  " Set title if provided
  if has_key(l:opts, 'title')
    let l:popup_opts.title = ' ' . l:opts.title . ' '
  endif

  " Set border style
  if l:config.ui.border ==# 'rounded'
    let l:popup_opts.border = [1, 1, 1, 1]
    let l:popup_opts.borderchars = ['─', '│', '─', '│', '╭', '╮', '╯', '╰']
  elseif l:config.ui.border ==# 'single'
    let l:popup_opts.border = [1, 1, 1, 1]
    let l:popup_opts.borderchars = ['─', '│', '─', '│', '┌', '┐', '┘', '└']
  elseif l:config.ui.border ==# 'double'
    let l:popup_opts.border = [1, 1, 1, 1]
    let l:popup_opts.borderchars = ['═', '║', '═', '║', '╔', '╗', '╝', '╚']
  elseif l:config.ui.border !=# 'none'
    let l:popup_opts.border = [1, 1, 1, 1]
  endif

  " Create popup
  let l:popup_id = popup_create(a:lines, l:popup_opts)

  " Set filetype in popup buffer
  if has_key(l:opts, 'filetype')
    call setbufvar(winbufnr(l:popup_id), '&filetype', l:opts.filetype)
  endif

  " Set readonly if specified
  if get(l:opts, 'readonly', v:true)
    call setbufvar(winbufnr(l:popup_id), '&modifiable', 0)
  endif

  " Add close keymap
  call setbufvar(winbufnr(l:popup_id), '&buftype', 'nofile')

  return [winbufnr(l:popup_id), l:popup_id]
endfunction

" Create split window
function! cursor#ui#CreateSplit(lines, opts) abort
  let l:config = cursor#config#Get()
  let l:opts = a:opts

  " Determine split command
  if l:config.ui.window_type ==# 'vsplit'
    execute 'botright ' . l:config.ui.split_size . ' vsplit'
  else
    execute 'botright ' . l:config.ui.split_size . ' split'
  endif

  " Get buffer and window
  let l:buf = bufnr('%')
  let l:win = win_getid()

  " Set buffer options
  setlocal buftype=nofile
  setlocal bufhidden=wipe
  setlocal noswapfile
  setlocal nowrap
  setlocal linebreak

  " Set filetype
  if has_key(l:opts, 'filetype')
    execute 'setlocal filetype=' . l:opts.filetype
  endif

  " Set content
  call setline(1, a:lines)

  " Make read-only if specified
  if get(l:opts, 'readonly', v:true)
    setlocal nomodifiable
  endif

  " Add close keymaps
  nnoremap <buffer> <silent> q :close<CR>
  nnoremap <buffer> <silent> <Esc> :close<CR>

  return [l:buf, l:win]
endfunction

" Show info message (always floating if available)
function! cursor#ui#ShowInfo(lines, title) abort
  if exists('*popup_create')
    return cursor#ui#CreateFloat(a:lines, {'title': a:title, 'readonly': v:true, 'filetype': 'text'})
  else
    return cursor#ui#CreateSplit(a:lines, {'title': a:title, 'readonly': v:true, 'filetype': 'text'})
  endif
endfunction

" Show error message
function! cursor#ui#ShowError(message, title) abort
  let l:lines = split(a:message, '\n')

  if exists('*popup_notification')
    call popup_notification(l:lines, {
      \ 'title': ' ' . a:title . ' ',
      \ 'highlight': 'ErrorMsg',
      \ 'border': [],
      \ 'time': 5000,
      \ })
    return [v:null, v:null]
  elseif exists('*popup_create')
    return cursor#ui#CreateFloat(l:lines, {'title': a:title, 'readonly': v:true, 'filetype': 'text'})
  else
    echohl ErrorMsg
    for l:line in l:lines
      echomsg l:line
    endfor
    echohl None
    return [v:null, v:null]
  endif
endfunction

" Show loading indicator
function! cursor#ui#ShowLoading(message) abort
  let l:msg = empty(a:message) ? 'Loading...' : a:message

  if exists('*popup_notification')
    return popup_notification([l:msg], {
      \ 'time': 0,
      \ 'highlight': 'Normal',
      \ 'border': [],
      \ })
  else
    echo l:msg
    return v:null
  endif
endfunction

" Close window
function! cursor#ui#CloseWindow(win_or_popup) abort
  if a:win_or_popup is v:null
    return
  endif

  " Try as popup ID first
  if exists('*popup_close')
    try
      call popup_close(a:win_or_popup)
      return
    catch
    endtry
  endif

  " Try as window ID
  if win_id2win(a:win_or_popup) > 0
    call win_execute(a:win_or_popup, 'close')
  endif
endfunction

" Append lines to buffer
function! cursor#ui#AppendToBuffer(buf, lines) abort
  if !bufexists(a:buf)
    return v:false
  endif

  " Make buffer modifiable temporarily
  call setbufvar(a:buf, '&modifiable', 1)

  " Get current line count
  let l:line_count = len(getbufline(a:buf, 1, '$'))

  " Append lines
  call setbufline(a:buf, l:line_count + 1, a:lines)

  " Make buffer read-only again
  call setbufvar(a:buf, '&modifiable', 0)

  return v:true
endfunction

" Update buffer content
function! cursor#ui#UpdateBuffer(buf, lines) abort
  if !bufexists(a:buf)
    return v:false
  endif

  " Make buffer modifiable temporarily
  call setbufvar(a:buf, '&modifiable', 1)

  " Clear and set lines
  call deletebufline(a:buf, 1, '$')
  call setbufline(a:buf, 1, a:lines)

  " Make buffer read-only again
  call setbufvar(a:buf, '&modifiable', 0)

  return v:true
endfunction

" Show progress notification
function! cursor#ui#ShowProgress(message) abort
  if exists('*popup_notification')
    call popup_notification([a:message], {
      \ 'time': 2000,
      \ 'highlight': 'Normal',
      \ })
  else
    echo a:message
  endif
endfunction

