" Code application logic for cursor.vim (Vim implementation)
" Maintainer: John Brandborg

" Parse code blocks from markdown response
function! s:ParseCodeBlocks(text) abort
  if empty(a:text)
    return []
  endif

  let l:blocks = []
  let l:in_block = v:false
  let l:current_block = {}

  for l:line in split(a:text, "\n", v:true)
    " Check for code block start/end
    let l:match = matchlist(l:line, '^```\(\w*\)')

    if !empty(l:match)
      if !l:in_block
        " Start of code block
        let l:in_block = v:true
        let l:lang = empty(l:match[1]) ? 'text' : l:match[1]
        let l:current_block = {
          \ 'language': l:lang,
          \ 'lines': [],
          \ }
      else
        " End of code block
        let l:in_block = v:false
        if !empty(l:current_block)
          call add(l:blocks, l:current_block)
          let l:current_block = {}
        endif
      endif
    elseif l:in_block
      " Inside code block, collect lines
      call add(l:current_block.lines, l:line)
    endif
  endfor

  return l:blocks
endfunction

" Apply code block to buffer
function! s:ApplyToBuffer(buf, lines, mode) abort
  if !bufexists(a:buf)
    return [v:false, 'Invalid buffer']
  endif

  " Check if buffer is modifiable
  if !getbufvar(a:buf, '&modifiable')
    return [v:false, 'Buffer is not modifiable']
  endif

  if a:mode ==# 'replace'
    " Replace entire buffer
    call deletebufline(a:buf, 1, '$')
    call setbufline(a:buf, 1, a:lines)
  elseif a:mode ==# 'append'
    " Append to buffer
    let l:line_count = len(getbufline(a:buf, 1, '$'))
    call setbufline(a:buf, l:line_count + 1, a:lines)
  elseif a:mode ==# 'insert'
    " Insert at cursor position
    let l:cursor = getcurpos()
    let l:row = l:cursor[1]
    call append(l:row, a:lines)
  else
    return [v:false, 'Unknown mode: ' . a:mode]
  endif

  return [v:true, 'Applied successfully']
endfunction

" Preview code changes
function! s:PreviewCode(blocks) abort
  if empty(a:blocks)
    call cursor#ui#ShowError('No code blocks found in response', 'cursor.vim Error')
    return
  endif

  let l:preview_lines = []

  call add(l:preview_lines, '# Code Blocks Preview')
  call add(l:preview_lines, '')
  call add(l:preview_lines, 'Found ' . len(a:blocks) . ' code block(s)')
  call add(l:preview_lines, '')

  let l:i = 1
  for l:block in a:blocks
    call add(l:preview_lines, '## Block ' . l:i . ' (' . l:block.language . ')')
    call add(l:preview_lines, '')
    call add(l:preview_lines, '```' . l:block.language)
    call extend(l:preview_lines, l:block.lines)
    call add(l:preview_lines, '```')
    call add(l:preview_lines, '')
    let l:i += 1
  endfor

  call cursor#ui#ShowResponse(l:preview_lines, {
    \ 'title': 'Code Preview',
    \ 'readonly': v:true,
    \ 'filetype': 'markdown',
    \ })
endfunction

" Apply last response from ask or chat
function! cursor#apply#ApplyLast() abort
  " Get last response
  let l:response = cursor#init#GetLastResponse()

  if l:response is v:null
    " Try to get from chat
    let l:history = cursor#chat#GetHistory()
    if !empty(l:history) && l:history[-1].role ==# 'assistant'
      let l:response = l:history[-1].content
    endif
  endif

  if l:response is v:null
    call cursor#ui#ShowError('No response to apply', 'cursor.vim Error')
    return
  endif

  " Parse code blocks
  let l:blocks = s:ParseCodeBlocks(l:response)

  if empty(l:blocks)
    call cursor#ui#ShowError('No code blocks found in response', 'cursor.vim Error')
    return
  endif

  " Show preview first
  call s:PreviewCode(l:blocks)

  " Ask user which block to apply (if multiple)
  let l:block_to_apply = l:blocks[0]
  if len(l:blocks) > 1
    let l:choices = []
    for l:block in l:blocks
      call add(l:choices, 'Block (' . l:block.language . ') - ' . len(l:block.lines) . ' lines')
    endfor

    let l:idx = inputlist(['Select code block to apply:'] + map(copy(l:choices), 'v:key + 1 . ". " . v:val'))
    if l:idx < 1 || l:idx > len(l:blocks)
      return
    endif
    let l:block_to_apply = l:blocks[l:idx - 1]
  endif

  call cursor#apply#ApplyBlock(l:block_to_apply)
endfunction

" Apply a specific code block
function! cursor#apply#ApplyBlock(block) abort
  " Ask user for application mode
  let l:mode_idx = inputlist([
    \ 'How to apply code?',
    \ '1. Replace entire buffer',
    \ '2. Append to end',
    \ '3. Insert at cursor',
    \ ])

  if l:mode_idx < 1 || l:mode_idx > 3
    return
  endif

  let l:modes = ['replace', 'append', 'insert']
  let l:mode = l:modes[l:mode_idx - 1]

  " Determine target buffer
  let l:target_buf = bufnr('%')

  " Apply code
  let [l:ok, l:err] = s:ApplyToBuffer(l:target_buf, a:block.lines, l:mode)

  if l:ok
    call cursor#ui#ShowProgress('Code applied successfully (' . l:mode . ')')
  else
    call cursor#ui#ShowError('Failed to apply: ' . l:err, 'cursor.vim Error')
  endif
endfunction

" Apply code to new buffer
function! cursor#apply#ApplyToNewBuffer() abort
  " Get last response
  let l:response = cursor#init#GetLastResponse()

  if l:response is v:null
    let l:history = cursor#chat#GetHistory()
    if !empty(l:history) && l:history[-1].role ==# 'assistant'
      let l:response = l:history[-1].content
    endif
  endif

  if l:response is v:null
    call cursor#ui#ShowError('No response to apply', 'cursor.vim Error')
    return
  endif

  " Parse code blocks
  let l:blocks = s:ParseCodeBlocks(l:response)

  if empty(l:blocks)
    call cursor#ui#ShowError('No code to apply', 'cursor.vim Error')
    return
  endif

  let l:block = l:blocks[0]

  " Create new buffer
  enew
  let l:buf = bufnr('%')

  " Set filetype
  execute 'setlocal filetype=' . l:block.language

  " Apply code
  call setline(1, l:block.lines)

  call cursor#ui#ShowProgress('Code applied to new buffer')
endfunction

" Preview last response
function! cursor#apply#PreviewLast() abort
  let l:response = cursor#init#GetLastResponse()

  if l:response is v:null
    let l:history = cursor#chat#GetHistory()
    if !empty(l:history) && l:history[-1].role ==# 'assistant'
      let l:response = l:history[-1].content
    endif
  endif

  if l:response is v:null
    call cursor#ui#ShowError('No response to preview', 'cursor.vim Error')
    return
  endif

  let l:blocks = s:ParseCodeBlocks(l:response)
  call s:PreviewCode(l:blocks)
endfunction

