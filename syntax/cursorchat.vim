" Syntax highlighting for Cursor chat buffers

if exists('b:current_syntax')
  finish
endif

" Headers
syntax match CursorChatTitle /^# Cursor Chat$/
syntax match CursorChatUserHeader /^## You:$/
syntax match CursorChatAssistantHeader /^## Cursor:$/
syntax match CursorChatMessageHeader /^## Your message:$/

" Separators
syntax match CursorChatSeparator /^[=-]\{60\}$/

" Instructions
syntax match CursorChatInstruction /^Type your message.*$/
syntax match CursorChatInstruction /^Commands:.*$/

" Code blocks
syntax region CursorChatCodeBlock start=/^```/ end=/^```/ contains=CursorChatCodeFence
syntax match CursorChatCodeFence /^```\w*$/

" Highlight groups
highlight default link CursorChatTitle Title
highlight default link CursorChatUserHeader Identifier
highlight default link CursorChatAssistantHeader Function
highlight default link CursorChatMessageHeader Question
highlight default link CursorChatSeparator Comment
highlight default link CursorChatInstruction Comment
highlight default link CursorChatCodeBlock String
highlight default link CursorChatCodeFence Special

let b:current_syntax = 'cursorchat'

