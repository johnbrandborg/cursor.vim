# cursor.vim Quick Start Guide

> [!WARNING]
> **⚠️ ALPHA STATUS**: This project is in alpha stage and may contain bugs or incomplete features. Use at your own risk!

Get up and running with cursor.vim in 5 minutes!

## Prerequisites Check

Before installing, ensure you have:

```bash
# Check Neovim version (need 0.8+)
nvim --version

# Check if Cursor Agent CLI is installed
which cursor-agent

# If not installed, visit: https://cursor.com/cli
```

## Installation

### Option 1: lazy.nvim (Recommended)

Add to your `~/.config/nvim/lua/plugins/cursor.lua`:

```lua
return {
  'johnbrandborg/cursor.vim',
  config = function()
    require('cursor').setup()
  end
}
```

### Option 2: vim-plug

Add to your `~/.config/nvim/init.vim`:

```vim
Plug 'johnbrandborg/cursor.vim'
```

Then run `:PlugInstall`

### Option 3: Manual

```bash
git clone https://github.com/johnbrandborg/cursor.vim.git \
  ~/.config/nvim/pack/cursor/start/cursor.vim
```

## First Time Setup

1. **Start Neovim**:
   ```bash
   nvim
   ```

2. **Verify Installation**:
   ```vim
   :CursorStatus
   ```

   You should see a status window showing:
   - ✅ Initialized: true
   - ✅ CLI Available: true

3. **If CLI not found**, configure the path:
   ```lua
   require('cursor').setup({
     cli_path = '/path/to/cursor-agent'
   })
   ```

## Your First Commands

### 1. Ask a Simple Question

```vim
:CursorAsk How do I read a file in Python?
```

A floating window will appear with the AI response!

### 2. Ask About Code

```vim
" Open a file
:e mycode.py

" Select some code (visual mode)
V5j

" Ask about it (using keymap)
<leader>ca

" Or use command
:CursorAskVisual What does this code do?
```

### 3. Start a Chat

```vim
" Open chat window
:CursorChat
" Or press: <leader>cc

" Type your message and press Enter
" Example: "Help me write a function to parse JSON"

" Press 'q' to close when done
```

### 4. Apply AI-Generated Code

```vim
" After getting a response with code blocks:
:CursorApply
" Or press: <leader>cy

" Choose how to apply:
" 1. Replace entire buffer
" 2. Append to end
" 3. Insert at cursor
```

## Essential Keymaps

| Key | Action |
|-----|--------|
| `<leader>ca` | Ask a question (normal mode) |
| `<leader>ca` | Ask about selection (visual mode) |
| `<leader>cc` | Open chat window |
| `<leader>cy` | Apply last AI response |
| `<leader>cs` | Show plugin status |

> **Note**: `<leader>` is typically `\` or `,` depending on your config

## Common Workflows

### Workflow 1: Quick Code Help

```vim
" 1. Type your question
:CursorAsk How do I sort a dictionary by value in Python?

" 2. Read the response

" 3. Apply the code if you like it
<leader>cy
```

### Workflow 2: Code Review

```vim
" 1. Select code you want reviewed
V10j

" 2. Ask for review
<leader>ca
" Type: "Review this code for improvements"

" 3. Apply suggestions
<leader>cy
```

### Workflow 3: Learning Session

```vim
" 1. Start chat
<leader>cc

" 2. Have a conversation
" You: "Teach me about Python decorators"
" AI: [explains decorators]
" You: "Show me an example"
" AI: [provides example]

" 3. Apply example code
<Esc>
:CursorApplyNew

" 4. Save the chat for later
:CursorChatSave learning_decorators.json
```

## Configuration (Optional)

Want to customize? Add this to your config:

```lua
require('cursor').setup({
  -- Increase timeout for complex queries
  timeout = 45000,

  -- Use split instead of floating window
  ui = {
    window_type = 'split',  -- or 'float', 'vsplit'
    border = 'rounded',
  },

  -- Custom keymaps
  mappings = {
    ask = '<leader>ai',    -- Change to your preference
    chat = '<leader>ac',
    apply = '<leader>aa',
    status = '<leader>as',
  },
})
```

## Troubleshooting

### "Cursor CLI not found"

```bash
# Find where cursor-agent is installed
which cursor-agent

# Then configure the path
lua require('cursor').setup({ cli_path = '/usr/local/bin/cursor-agent' })
```

### "Authentication error"

```bash
# Authenticate with Cursor Agent CLI
cursor-agent auth login
```

### Timeout errors

```lua
-- Increase timeout
require('cursor').setup({
  timeout = 60000  -- 60 seconds
})
```

## Next Steps

1. **Read the full docs**: `:help cursor`
2. **Try the examples**: Check `examples/workflows.md`
3. **Customize**: Adjust settings to your preference
4. **Explore**: Try different prompts and workflows

## Quick Reference Card

```
COMMANDS                    KEYMAPS
:CursorAsk <question>       <leader>ca (ask/visual)
:CursorChat                 <leader>cc (chat)
:CursorApply                <leader>cy (apply)
:CursorStatus               <leader>cs (status)

CHAT WINDOW
<Enter>     Send message
q           Close chat
<leader>cc  Clear history

TIPS
- Be specific in your questions
- Use visual selection for context
- Preview code before applying
- Save important chat sessions
```

## Getting Help

- View help: `:help cursor`
- Check status: `:CursorStatus`
- Enable debug: `require('cursor').setup({ debug = true })`
- Report issues: https://github.com/johnbrandborg/cursor.vim/issues

## Example Session

Here's a complete example session:

```vim
" 1. Open Neovim
$ nvim

" 2. Create a new file
:e hello.py

" 3. Ask for code
:CursorAsk Write a Python function to calculate fibonacci numbers

" 4. Apply the code
<leader>cy
" Choose: "Replace entire buffer"

" 5. Ask for improvements
:%
<leader>ca
" Type: "Add error handling and docstrings"

" 6. Apply improvements
<leader>cy

" 7. Save the file
:w

" 8. Test it
:!python hello.py
```

---

**You're ready to go!** 🚀

For more advanced usage, check out:
- Full documentation: `README.md`
- Workflow examples: `examples/workflows.md`
- Help file: `:help cursor`

Happy coding with cursor.vim!

