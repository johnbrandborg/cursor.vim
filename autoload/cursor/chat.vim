" Chat feature implementation for cursor.vim (Vim implementation)
" Maintainer: John Brandborg

" Chat state
let s:state = {
  \ 'history': [],
  \ 'chat_buf': v:null,
  \ 'chat_win': v:null,
  \ }

" Format chat history for display
function! s:FormatChatDisplay(history) abort
  let l:lines = []

  call add(l:lines, '# Cursor Chat')
  call add(l:lines, '')
  call add(l:lines, 'Type your message below and press <CR> to send')
  call add(l:lines, 'Commands: :CursorChatClear (clear) | :CursorChatSave (save) | q (quit)')
  call add(l:lines, repeat('=', 60))
  call add(l:lines, '')

  for l:msg in a:history
    if l:msg.role ==# 'user'
      call add(l:lines, '## You:')
      call add(l:lines, '')
      call add(l:lines, l:msg.content)
    elseif l:msg.role ==# 'assistant'
      call add(l:lines, '## Cursor:')
      call add(l:lines, '')
      let l:content_lines = split(l:msg.content, "\n", v:true)
      call extend(l:lines, l:content_lines)
    endif
    call add(l:lines, '')
    call add(l:lines, repeat('-', 60))
    call add(l:lines, '')
  endfor

  call add(l:lines, '## Your message:')
  call add(l:lines, '')

  return l:lines
endfunction

" Create chat window
function! cursor#chat#OpenChat() abort
  if s:state.chat_buf isnot v:null && bufexists(s:state.chat_buf)
    " Chat buffer exists, try to focus it
    if s:state.chat_win isnot v:null && win_id2win(s:state.chat_win) > 0
      call win_gotoid(s:state.chat_win)
      return
    endif
  endif

  let l:config = cursor#config#Get()

  " Create new split for chat
  execute 'botright ' . float2nr(&lines * 0.6) . ' split'

  let s:state.chat_buf = bufnr('%')
  let s:state.chat_win = win_getid()

  " Set buffer options
  setlocal buftype=nofile
  setlocal bufhidden=hide
  setlocal filetype=cursorchat
  setlocal noswapfile
  setlocal wrap
  setlocal linebreak
  setlocal modifiable

  " Display current history
  let l:lines = s:FormatChatDisplay(s:state.history)
  call setline(1, l:lines)

  " Setup keymaps
  call s:SetupChatKeymaps()

  " Move cursor to end
  call cursor(line('$'), 0)
  startinsert!
endfunction

" Setup keymaps for chat buffer
function! s:SetupChatKeymaps() abort
  " Send message on Enter (in insert mode)
  inoremap <buffer> <silent> <CR> <Esc>:call cursor#chat#SendMessage()<CR>

  " Close on q (in normal mode)
  nnoremap <buffer> <silent> q :call cursor#chat#CloseChat()<CR>

  " Clear chat
  nnoremap <buffer> <silent> <leader>cc :call cursor#chat#ClearHistory()<CR>
endfunction

" Send message from chat buffer
function! cursor#chat#SendMessage() abort
  if s:state.chat_buf is v:null || !bufexists(s:state.chat_buf)
    return
  endif

  " Get all lines
  let l:lines = getbufline(s:state.chat_buf, 1, '$')

  " Find the last "Your message:" section
  let l:message_start = v:null
  for l:i in range(len(l:lines) - 1, 0, -1)
    if l:lines[l:i] =~# '^## Your message:'
      let l:message_start = l:i + 1
      break
    endif
  endfor

  if l:message_start is v:null
    call cursor#ui#ShowError('Could not find message input area', 'cursor.vim Error')
    return
  endif

  " Extract message (skip empty line after header)
  let l:message_lines = []
  for l:i in range(l:message_start + 1, len(l:lines) - 1)
    if !empty(l:lines[l:i]) || !empty(l:message_lines)
      call add(l:message_lines, l:lines[l:i])
    endif
  endfor

  " Remove trailing empty lines
  while !empty(l:message_lines) && empty(l:message_lines[-1])
    call remove(l:message_lines, -1)
  endwhile

  let l:message = join(l:message_lines, "\n")

  if empty(l:message)
    call cursor#ui#ShowError('Empty message', 'cursor.vim Error')
    return
  endif

  " Add user message to history
  call add(s:state.history, {
    \ 'role': 'user',
    \ 'content': l:message,
    \ })

  " Show loading indicator
  call cursor#ui#ShowProgress('Sending message to Cursor AI...')

  " Prepare history for CLI (limit context)
  let l:config = cursor#config#Get()
  let l:history_for_cli = []
  let l:start_idx = max([0, len(s:state.history) - l:config.chat.max_context])
  for l:i in range(l:start_idx, len(s:state.history) - 1)
    call add(l:history_for_cli, s:state.history[l:i])
  endfor

  " Send to CLI
  call cursor#cli#Chat(
    \ l:message,
    \ l:history_for_cli,
    \ function('s:ChatCallback')
    \ )
endfunction

" Chat response callback
function! s:ChatCallback(response, error) abort
  if a:error isnot v:null
    call cursor#ui#ShowError(a:error, 'Cursor Chat Error')
    " Remove the user message from history since it failed
    if !empty(s:state.history)
      call remove(s:state.history, -1)
    endif
    return
  endif

  " Add assistant response to history
  call add(s:state.history, {
    \ 'role': 'assistant',
    \ 'content': a:response,
    \ })

  " Update display
  call cursor#chat#RefreshDisplay()
endfunction

" Refresh chat display
function! cursor#chat#RefreshDisplay() abort
  if s:state.chat_buf is v:null || !bufexists(s:state.chat_buf)
    return
  endif

  let l:lines = s:FormatChatDisplay(s:state.history)

  " Update buffer
  call setbufvar(s:state.chat_buf, '&modifiable', 1)
  call deletebufline(s:state.chat_buf, 1, '$')
  call setbufline(s:state.chat_buf, 1, l:lines)

  " Move cursor to end if window is valid
  if s:state.chat_win isnot v:null && win_id2win(s:state.chat_win) > 0
    call win_execute(s:state.chat_win, 'call cursor(line("$"), 0)')
    call win_execute(s:state.chat_win, 'startinsert!')
  endif
endfunction

" Clear chat history
function! cursor#chat#ClearHistory() abort
  let s:state.history = []
  call cursor#chat#RefreshDisplay()
  call cursor#ui#ShowProgress('Chat history cleared')
endfunction

" Close chat window
function! cursor#chat#CloseChat() abort
  if s:state.chat_win isnot v:null && win_id2win(s:state.chat_win) > 0
    call win_execute(s:state.chat_win, 'close')
  endif
  let s:state.chat_win = v:null
endfunction

" Save chat history to file
function! cursor#chat#SaveHistory(...) abort
  let l:config = cursor#config#Get()

  if !l:config.chat.save_history
    call cursor#ui#ShowError('Chat history saving is disabled', 'cursor.vim Error')
    return
  endif

  let l:filename = get(a:, 1, strftime('%Y%m%d_%H%M%S') . '_chat.json')
  let l:filepath = l:config.chat.history_dir . '/' . l:filename

  let l:json = json_encode(s:state.history)

  call writefile([l:json], l:filepath)

  call cursor#ui#ShowProgress('Chat history saved to ' . l:filepath)
endfunction

" Load chat history from file
function! cursor#chat#LoadHistory(filepath) abort
  if !filereadable(a:filepath)
    call cursor#ui#ShowError('Failed to load chat history: file not found', 'cursor.vim Error')
    return
  endif

  let l:content = join(readfile(a:filepath), '')

  try
    let s:state.history = json_decode(l:content)
    call cursor#chat#RefreshDisplay()
    call cursor#ui#ShowProgress('Chat history loaded')
  catch
    call cursor#ui#ShowError('Failed to parse chat history', 'cursor.vim Error')
  endtry
endfunction

" Get current chat history
function! cursor#chat#GetHistory() abort
  return s:state.history
endfunction

