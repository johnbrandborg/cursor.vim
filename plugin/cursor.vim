" cursor.vim - Cursor AI Integration for Vim and Neovim
" Maintainer: John Brandborg
" License: MIT

if exists('g:loaded_cursor_vim')
  finish
endif
let g:loaded_cursor_vim = 1

" Detect runtime environment
if has('nvim-0.8')
  " ========================================
  " NEOVIM IMPLEMENTATION (Lua)
  " ========================================

  " Initialize plugin
  lua << EOF
  local cursor = require('cursor')

  -- Setup with default config if user hasn't called setup
  vim.api.nvim_create_autocmd('VimEnter', {
    once = true,
    callback = function()
      if not cursor.state.initialized then
        cursor.setup()
      end
    end,
  })
EOF

  " Command definitions for Neovim
  command! -nargs=0 CursorSetup lua require('cursor').setup()
  command! -nargs=0 CursorStatus lua require('cursor').status()

  " Ask commands
  command! -nargs=+ CursorAsk lua require('cursor.ask').ask(<q-args>)
  command! -nargs=0 CursorAskInteractive lua require('cursor.ask').ask_interactive()
  command! -nargs=* CursorAskVisual lua require('cursor.ask').ask_visual(<q-args>)
  command! -nargs=* CursorAskBuffer lua require('cursor.ask').ask_buffer(<q-args>)

  " Chat commands
  command! -nargs=0 CursorChat lua require('cursor.chat').open_chat()
  command! -nargs=0 CursorChatClear lua require('cursor.chat').clear_history()
  command! -nargs=? CursorChatSave lua require('cursor.chat').save_history(<f-args>)
  command! -nargs=1 -complete=file CursorChatLoad lua require('cursor.chat').load_history(<f-args>)
  command! -nargs=0 CursorChatClose lua require('cursor.chat').close_chat()

  " Apply commands
  command! -nargs=0 CursorApply lua require('cursor.apply').apply_last()
  command! -nargs=0 CursorApplyNew lua require('cursor.apply').apply_to_new_buffer()
  command! -nargs=0 CursorPreview lua require('cursor.apply').preview_last()

  " Default key mappings (can be disabled by setting g:cursor_no_default_mappings)
  if !exists('g:cursor_no_default_mappings') || !g:cursor_no_default_mappings
    lua << EOF
    local cursor = require('cursor')
    local config = require('cursor.config')

    -- Setup keymaps after config is loaded
    vim.api.nvim_create_autocmd('User', {
      pattern = 'CursorSetupComplete',
      callback = function()
        local cfg = config.get()
        local mappings = cfg.mappings

        if mappings.ask then
          vim.keymap.set('n', mappings.ask, ':CursorAskInteractive<CR>', { silent = true, desc = 'Cursor Ask' })
          vim.keymap.set('v', mappings.ask, ':<C-u>CursorAskVisual<CR>', { silent = true, desc = 'Cursor Ask Visual' })
        end

        if mappings.chat then
          vim.keymap.set('n', mappings.chat, ':CursorChat<CR>', { silent = true, desc = 'Cursor Chat' })
        end

        if mappings.apply then
          vim.keymap.set('n', mappings.apply, ':CursorApply<CR>', { silent = true, desc = 'Cursor Apply' })
        end

        if mappings.status then
          vim.keymap.set('n', mappings.status, ':CursorStatus<CR>', { silent = true, desc = 'Cursor Status' })
        end
      end,
    })
EOF
  endif

elseif v:version >= 900
  " ========================================
  " VIM IMPLEMENTATION (Vimscript)
  " ========================================

  " Auto-initialize
  augroup CursorVim
    autocmd!
    autocmd VimEnter * call cursor#init#Setup()
  augroup END

  " Command definitions for Vim
  command! -nargs=0 CursorSetup call cursor#init#Setup()
  command! -nargs=0 CursorStatus call cursor#init#Status()

  " Ask commands
  command! -nargs=+ CursorAsk call cursor#ask#Ask(<q-args>)
  command! -nargs=0 CursorAskInteractive call cursor#ask#AskInteractive()
  command! -nargs=* CursorAskVisual call cursor#ask#AskVisual(<q-args>)
  command! -nargs=* CursorAskBuffer call cursor#ask#AskBuffer(<q-args>)

  " Chat commands
  command! -nargs=0 CursorChat call cursor#chat#OpenChat()
  command! -nargs=0 CursorChatClear call cursor#chat#ClearHistory()
  command! -nargs=? CursorChatSave call cursor#chat#SaveHistory(<f-args>)
  command! -nargs=1 -complete=file CursorChatLoad call cursor#chat#LoadHistory(<f-args>)
  command! -nargs=0 CursorChatClose call cursor#chat#CloseChat()

  " Apply commands
  command! -nargs=0 CursorApply call cursor#apply#ApplyLast()
  command! -nargs=0 CursorApplyNew call cursor#apply#ApplyToNewBuffer()
  command! -nargs=0 CursorPreview call cursor#apply#PreviewLast()

  " Default key mappings (can be disabled by setting g:cursor_no_default_mappings)
  if !exists('g:cursor_no_default_mappings') || !g:cursor_no_default_mappings
    " Setup keymaps
    if !hasmapto('<Plug>CursorAsk', 'n')
      nmap <silent> <leader>ca <Plug>CursorAsk
    endif
    if !hasmapto('<Plug>CursorAskVisual', 'v')
      vmap <silent> <leader>ca <Plug>CursorAskVisual
    endif
    if !hasmapto('<Plug>CursorChat', 'n')
      nmap <silent> <leader>cc <Plug>CursorChat
    endif
    if !hasmapto('<Plug>CursorApply', 'n')
      nmap <silent> <leader>cy <Plug>CursorApply
    endif
    if !hasmapto('<Plug>CursorStatus', 'n')
      nmap <silent> <leader>cs <Plug>CursorStatus
    endif

    " Define <Plug> mappings
    nnoremap <silent> <Plug>CursorAsk :CursorAskInteractive<CR>
    vnoremap <silent> <Plug>CursorAskVisual :<C-u>call cursor#ask#AskVisual('')<CR>
    nnoremap <silent> <Plug>CursorChat :CursorChat<CR>
    nnoremap <silent> <Plug>CursorApply :CursorApply<CR>
    nnoremap <silent> <Plug>CursorStatus :CursorStatus<CR>
  endif

else
  " Neither Neovim 0.8+ nor Vim 9.0+
  echohl WarningMsg
  echomsg 'cursor.vim requires Neovim 0.8+ or Vim 9.0+'
  echohl None
  finish
endif

" Auto-setup keymaps after first setup
augroup CursorVim
  autocmd!
  autocmd User CursorSetupComplete silent! doautocmd <nomodeline> User CursorMappings
augroup END

