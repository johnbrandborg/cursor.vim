" Ask feature implementation for cursor.vim (Vim implementation)
" Maintainer: John Brandborg

" Get visual selection
function! s:GetVisualSelection() abort
  let [l:start_line, l:start_col] = getpos("'<")[1:2]
  let [l:end_line, l:end_col] = getpos("'>")[1:2]

  if l:start_line == 0 || l:end_line == 0
    return v:null
  endif

  let l:lines = getline(l:start_line, l:end_line)

  if empty(l:lines)
    return v:null
  endif

  return join(l:lines, "\n")
endfunction

" Format response for display
function! s:FormatResponse(response) abort
  if empty(a:response)
    return ['No response received']
  endif

  return split(a:response, "\n", v:true)
endfunction

" Response callback
function! s:AskCallback(prompt, response, error) abort
  if a:error isnot v:null
    call cursor#ui#ShowError(a:error, 'Cursor Ask Error')
    return
  endif

  " Store response for apply feature
  call cursor#init#SetLastResponse(a:response)

  " Format and display response
  let l:lines = s:FormatResponse(a:response)

  call cursor#ui#ShowResponse(l:lines, {
    \ 'title': 'Cursor Ask',
    \ 'readonly': v:true,
    \ 'filetype': 'markdown',
    \ })
endfunction

" Execute ask command
function! cursor#ask#Ask(prompt, ...) abort
  let l:opts = get(a:, 1, {})

  if empty(a:prompt)
    call cursor#ui#ShowError('No prompt provided', 'cursor.vim Error')
    return
  endif

  " Get context if provided
  let l:context = get(l:opts, 'context', '')

  " Show loading indicator
  call cursor#ui#ShowProgress('Asking Cursor AI...')

  " Build full prompt with context
  let l:full_prompt = a:prompt
  if !empty(l:context)
    let l:full_prompt = a:prompt . "\n\nContext:\n```\n" . l:context . "\n```"
  endif

  " Execute CLI command
  call cursor#cli#Ask(
    \ a:prompt,
    \ l:context,
    \ function('s:AskCallback', [l:full_prompt])
    \ )
endfunction

" Ask with visual selection
function! cursor#ask#AskVisual(...) abort
  let l:selection = s:GetVisualSelection()

  if l:selection is v:null
    call cursor#ui#ShowError('No visual selection', 'cursor.vim Error')
    return
  endif

  " Get prompt from arguments or user input
  let l:prompt = get(a:, 1, '')

  if empty(l:prompt)
    let l:prompt = input('Ask about selection: ')
    if empty(l:prompt)
      return
    endif
  endif

  call cursor#ask#Ask(l:prompt, {'context': l:selection})
endfunction

" Ask about current buffer
function! cursor#ask#AskBuffer(...) abort
  let l:buf_content = join(getline(1, '$'), "\n")
  let l:filename = expand('%:t')

  " Get prompt from arguments or user input
  let l:prompt = get(a:, 1, '')

  if empty(l:prompt)
    let l:prompt = input('Ask about ' . l:filename . ': ')
    if empty(l:prompt)
      return
    endif
  endif

  call cursor#ask#Ask(l:prompt, {'context': l:buf_content})
endfunction

" Interactive ask - prompt user for input
function! cursor#ask#AskInteractive() abort
  let l:prompt = input('Ask Cursor: ')

  if empty(l:prompt)
    return
  endif

  call cursor#ask#Ask(l:prompt)
endfunction

