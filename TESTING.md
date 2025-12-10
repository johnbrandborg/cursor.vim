# cursor.vim Testing Guide

This document provides testing procedures for both Vim and Neovim implementations.

## Prerequisites

Before testing, ensure you have:

- [ ] Vim 9.0+ installed (`vim --version`)
- [ ] Neovim 0.8+ installed (`nvim --version`)
- [ ] Cursor CLI installed (`which cursor`)
- [ ] Cursor CLI authenticated (`cursor auth login`)
- [ ] Node.js installed (`node --version`)

## Installation for Testing

### Neovim Test Installation

```bash
# Clone to test location
git clone https://github.com/johnbrandborg/cursor.vim.git /tmp/cursor.vim-test

# Create symlink
mkdir -p ~/.config/nvim/pack/test/start
ln -sf /tmp/cursor.vim-test ~/.config/nvim/pack/test/start/cursor.vim

# Start Neovim
nvim
```

### Vim Test Installation

```bash
# Clone to test location
git clone https://github.com/johnbrandborg/cursor.vim.git /tmp/cursor.vim-test

# Create symlink
mkdir -p ~/.vim/pack/test/start
ln -sf /tmp/cursor.vim-test ~/.vim/pack/test/start/cursor.vim

# Start Vim
vim
```

## Test Checklist

### Basic Functionality Tests

#### 1. Plugin Detection and Loading

**Neovim:**
```vim
:echo has('nvim-0.8')
" Should return: 1

:echo exists('g:loaded_cursor_vim')
" Should return: 1

:CursorStatus
" Should show status window with Neovim implementation
```

**Vim:**
```vim
:echo v:version >= 900
" Should return: 1

:echo exists('g:loaded_cursor_vim')
" Should return: 1

:CursorStatus
" Should show status window with Vim implementation
```

#### 2. Configuration Tests

**Neovim:**
```vim
:lua print(vim.inspect(require('cursor.config').get()))
" Should display configuration table
```

**Vim:**
```vim
:echo cursor#config#Get()
" Should display configuration dictionary
```

#### 3. CLI Validation

Both editors:
```vim
:CursorStatus
" Check that 'CLI Available: true' is shown
```

### Feature Tests

#### Ask Feature

**Test 1: Simple Ask**
```vim
:CursorAsk What is a Python list comprehension?
" Expected: Floating window/popup with AI response
```

**Test 2: Interactive Ask**
```vim
:CursorAskInteractive
" Type: "Explain recursion"
" Expected: Prompt appears, then response in window
```

**Test 3: Visual Selection Ask**
```vim
" 1. Create a file with some code
:enew
:set filetype=python
idef hello():
    print("world")
<Esc>

" 2. Select the function
V}

" 3. Ask about it
<leader>ca
" Or: :CursorAskVisual
" Type: "What does this function do?"
" Expected: Response about the selected code
```

**Test 4: Buffer Ask**
```vim
:CursorAskBuffer Explain this code
" Expected: Response about entire buffer content
```

#### Chat Feature

**Test 1: Open Chat**
```vim
:CursorChat
" Or: <leader>cc
" Expected: Chat window opens with instructions
```

**Test 2: Send Message**
```vim
" In chat window:
" Type: "Hello, can you help me with Python?"
" Press <CR> in insert mode
" Expected: AI response appears in chat
```

**Test 3: Conversation Context**
```vim
" Send follow-up message:
" Type: "Show me an example"
" Press <CR>
" Expected: Response that references previous context
```

**Test 4: Clear History**
```vim
:CursorChatClear
" Expected: Chat history cleared, fresh chat window
```

**Test 5: Save/Load History**
```vim
" After having a conversation:
:CursorChatSave test_session.json
" Expected: File saved message

:CursorChatClear
" Clear current chat

:CursorChatLoad ~/.vim/cursor_chat_history/test_session.json
" (or ~/.local/share/nvim/cursor_chat_history/ for Neovim)
" Expected: Previous conversation loaded
```

**Test 6: Close Chat**
```vim
" In chat window:
" Press 'q' in normal mode
" Or: :CursorChatClose
" Expected: Chat window closes
```

#### Apply Feature

**Test 1: Preview Code**
```vim
" After getting a response with code:
:CursorPreview
" Expected: Preview window showing code blocks
```

**Test 2: Apply to Current Buffer**
```vim
:CursorApply
" Or: <leader>cy
" Expected: Prompt to select application mode
" Choose: 1 (Replace), 2 (Append), or 3 (Insert)
" Expected: Code applied to buffer
```

**Test 3: Apply to New Buffer**
```vim
:CursorApplyNew
" Expected: New buffer created with code
```

**Test 4: Multiple Code Blocks**
```vim
" Ask a question that returns multiple code blocks:
:CursorAsk Show me Python and JavaScript examples of async functions

" Then apply:
:CursorApply
" Expected: Prompt to choose which block to apply
```

### UI Tests

#### Floating Windows (Neovim / Vim 8.2+)

```vim
:CursorAsk Test question
" Expected: Floating window with rounded borders
" Check: Window is centered
" Check: Can close with 'q' or <Esc>
```

#### Split Windows

```vim
" Configure to use splits:
" Neovim:
:lua require('cursor').setup({ ui = { window_type = 'split' } })

" Vim:
:let g:cursor_config = {'ui': {'window_type': 'split'}}

:CursorAsk Test question
" Expected: Horizontal split at bottom
```

### Keymap Tests

Test default keymaps (if not disabled):

```vim
" Normal mode - Ask
<leader>ca
" Expected: Prompt for question

" Visual mode - Ask about selection
" Select some text, then:
<leader>ca
" Expected: Prompt for question about selection

" Normal mode - Chat
<leader>cc
" Expected: Chat window opens

" Normal mode - Apply
<leader>cy
" Expected: Apply last response

" Normal mode - Status
<leader>cs
" Expected: Status window
```

### Error Handling Tests

#### Test 1: CLI Not Found

```vim
" Temporarily break CLI path:
" Neovim:
:lua require('cursor').setup({ cli_path = '/nonexistent/cursor' })

" Vim:
:let g:cursor_config = {'cli_path': '/nonexistent/cursor'}

:CursorAsk Test
" Expected: Error message about CLI not found
```

#### Test 2: Timeout

```vim
" Set very short timeout:
" Neovim:
:lua require('cursor').setup({ timeout = 1 })

" Vim:
:let g:cursor_config = {'timeout': 1}

:CursorAsk Complex question requiring long processing
" Expected: Timeout error after 1ms
```

#### Test 3: Empty Prompts

```vim
:CursorAsk
" Expected: Error about no prompt provided

:CursorAskInteractive
" Press Enter without typing
" Expected: Nothing happens or appropriate message
```

### Performance Tests

#### Test 1: Async Operations

```vim
:CursorAsk What is recursion?
" Immediately try to edit:
itest
<Esc>
" Expected: Editor remains responsive while waiting for response
```

#### Test 2: Large Responses

```vim
:CursorAsk Write a complete Python web scraper with error handling, logging, and retry logic
" Expected: Large response handled smoothly
" Check: Can scroll through response
" Check: No lag or freezing
```

#### Test 3: Multiple Concurrent Requests

```vim
:CursorAsk Question 1
:CursorAsk Question 2
:CursorAsk Question 3
" Expected: All requests handled (may queue or run in parallel)
" Check: No crashes or errors
```

## Compatibility Tests

### Vim 9.0 Specific

```vim
" Check Vim version
:echo v:version
" Should be >= 900

" Test job_start functionality
:CursorAsk Test
" Expected: Works using job_start

" Test popup_create (if Vim 8.2+)
:CursorStatus
" Expected: Popup window (if supported) or split
```

### Neovim 0.8 Specific

```vim
" Check Neovim version
:lua print(vim.version())
" Should be >= 0.8

" Test libuv functionality
:CursorAsk Test
" Expected: Works using vim.loop

" Test floating windows
:CursorStatus
" Expected: Floating window with borders
```

## Regression Tests

After any changes, verify:

- [ ] All commands still work
- [ ] No linter errors
- [ ] Documentation is accurate
- [ ] Examples still work
- [ ] Both Vim and Neovim work identically

## Test Results Template

```
Date: ___________
Tester: ___________
Environment:
  - OS: ___________
  - Vim Version: ___________
  - Neovim Version: ___________
  - Cursor CLI Version: ___________

Test Results:
  [ ] Plugin loads in Vim
  [ ] Plugin loads in Neovim
  [ ] Ask feature works (Vim)
  [ ] Ask feature works (Neovim)
  [ ] Chat feature works (Vim)
  [ ] Chat feature works (Neovim)
  [ ] Apply feature works (Vim)
  [ ] Apply feature works (Neovim)
  [ ] UI displays correctly (Vim)
  [ ] UI displays correctly (Neovim)
  [ ] Keymaps work (Vim)
  [ ] Keymaps work (Neovim)
  [ ] Error handling works
  [ ] Performance is acceptable
  [ ] No linter errors

Issues Found:
  1. ___________
  2. ___________

Notes:
___________
```

## Automated Testing (Future)

Consider adding:
- Unit tests for Lua modules
- Integration tests for CLI communication
- UI tests for window creation
- Performance benchmarks

## Reporting Issues

If you find bugs during testing:

1. Check existing issues: https://github.com/johnbrandborg/cursor.vim/issues
2. Create new issue with:
   - Editor (Vim/Neovim) and version
   - Operating system
   - Steps to reproduce
   - Expected vs actual behavior
   - Error messages or logs

## Continuous Testing

For ongoing development:

```bash
# Watch for changes and test
while true; do
  inotifywait -e modify -r lua/ autoload/ plugin/
  nvim -c "CursorStatus" -c "qa"
  vim -c "CursorStatus" -c "qa"
done
```

---

**Testing Status**: Ready for community testing
**Last Updated**: December 10, 2025

