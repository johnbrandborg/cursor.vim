# cursor.vim

<p align="center">
  <strong>Cursor AI Integration for Vim and Neovim</strong>
</p>

<p align="center">
  Bring the power of <a href="https://cursor.com">Cursor</a>'s AI capabilities directly into your Vim or Neovim workflow
</p>

---

## Features

- **🤔 Ask** - Get instant answers to coding questions with full context awareness
- **💬 Chat** - Interactive conversational AI assistance with history management
- **✨ Apply** - Seamlessly apply AI-generated code suggestions to your buffers
- **🎨 Modern UI** - Beautiful floating windows and split layouts
- **⚡ Async** - Non-blocking operations that keep your editor responsive
- **🔧 Configurable** - Extensive configuration options and key mappings
- **🔀 Dual Support** - Works with both Vim 9.0+ and Neovim 0.8+

> **Note**: cursor.vim focuses on interactive AI assistance, not inline code completion. Use it alongside [GitHub Copilot](https://github.com/github/copilot.vim) for the best development experience!

## Philosophy

cursor.vim is designed to **complement** inline completion tools like GitHub Copilot, not replace them.

- **Use GitHub Copilot for**: Real-time code suggestions as you type
- **Use cursor.vim for**: Interactive Q&A, learning, debugging, and applying complex changes

Think of it as having both:
- A **co-pilot** (GitHub Copilot) - suggests code while you fly ✈️
- An **instructor** (cursor.vim) - answers questions and helps you learn 🎓

### Feature Comparison

| Feature | GitHub Copilot | cursor.vim |
|---------|----------------|------------|
| Inline code completion | ✅ | ❌ |
| Tab suggestions while typing | ✅ | ❌ |
| Interactive Q&A | ❌ | ✅ |
| Multi-turn conversations | ❌ | ✅ |
| Code explanation | Limited | ✅ |
| Apply code with preview | ❌ | ✅ |
| Chat history | ❌ | ✅ |
| Ask about selections | ❌ | ✅ |
| Works with Vim & Neovim | ✅ | ✅ |

**Recommendation**: Install both! They work great together and serve different purposes.

## Prerequisites

Choose one:
- **Neovim 0.8+** - Modern Neovim with Lua support
- **Vim 9.0+** - Modern Vim with job control and popup windows

Both require:
- **Cursor CLI** - [Cursor Agent CLI](https://cursor.com/cli) installed and authenticated
- **Node.js** - Required by Cursor CLI

## Installation

### Using [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'johnbrandborg/cursor.vim'
```

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  'johnbrandborg/cursor.vim',
  config = function()
    require('cursor').setup({
      -- your config here (optional)
    })
  end
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  'johnbrandborg/cursor.vim',
  config = function()
    require('cursor').setup()
  end
}
```

### Manual Installation

```bash
# For Neovim
git clone --depth=1 https://github.com/johnbrandborg/cursor.vim.git \
  ~/.config/nvim/pack/cursor/start/cursor.vim

# For Vim
git clone --depth=1 https://github.com/johnbrandborg/cursor.vim.git \
  ~/.vim/pack/cursor/start/cursor.vim
```

## Quick Start

1. Install the plugin using your preferred method
2. Install and authenticate with [Cursor CLI](https://cursor.com/cli)
3. Open Vim or Neovim and run `:CursorSetup` to verify installation
4. Start using cursor.vim!

**Note**: cursor.vim automatically detects your editor (Vim or Neovim) and loads the appropriate implementation.

```vim
" Ask a question
:CursorAsk How do I implement a binary search in Python?

" Open chat interface
:CursorChat

" Apply last AI response to buffer
:CursorApply
```

## Configuration

cursor.vim comes with sensible defaults, but you can customize it to your liking.

### Neovim Configuration (Lua)

```lua
require('cursor').setup({
  -- Path to cursor CLI executable
  cli_path = 'cursor',

  -- Default AI model
  model = 'claude-sonnet-4',

  -- Timeout for CLI operations (milliseconds)
  timeout = 30000,

  -- UI preferences
  ui = {
    -- Window type: 'float', 'split', 'vsplit'
    window_type = 'float',

    -- Floating window dimensions (percentage)
    float_width = 0.8,
    float_height = 0.8,

    -- Split size (lines/columns)
    split_size = 15,

    -- Border style: 'none', 'single', 'double', 'rounded', 'solid', 'shadow'
    border = 'rounded',
  },

  -- Chat preferences
  chat = {
    -- Save chat history
    save_history = true,

    -- Maximum context messages
    max_context = 20,

    -- History directory
    history_dir = vim.fn.stdpath('data') .. '/cursor_chat_history',
  },

  -- Key mappings (set to false to disable)
  mappings = {
    ask = '<leader>ca',
    chat = '<leader>cc',
    apply = '<leader>cy',
    status = '<leader>cs',
  },

  -- Debug mode
  debug = false,
})
```

### Vim Configuration (Vimscript)

```vim
" Set configuration before plugin loads
let g:cursor_config = {
  \ 'cli_path': 'cursor',
  \ 'model': 'claude-sonnet-4',
  \ 'timeout': 30000,
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
  \ },
  \ 'debug': v:false,
  \ }
```

To disable default key mappings entirely (works for both Vim and Neovim):

```vim
let g:cursor_no_default_mappings = 1
```

## Usage

### Ask Feature

Ask questions and get AI-powered answers with full context.

```vim
" Simple question
:CursorAsk How do I reverse a list in Python?

" Interactive mode (prompts for input)
:CursorAskInteractive
" Or use keymap: <leader>ca

" Ask about visual selection
" 1. Select code in visual mode
" 2. Press <leader>ca or run :CursorAskVisual

" Ask about current buffer
:CursorAskBuffer Explain this code
```

### Chat Feature

Interactive conversational interface with context memory.

```vim
" Open chat window
:CursorChat
" Or use keymap: <leader>cc

" In chat window:
" - Type your message and press <Enter> to send
" - Press 'q' to close
" - Use <leader>cc to clear history

" Save chat history
:CursorChatSave my_session.json

" Load chat history
:CursorChatLoad ~/.local/share/nvim/cursor_chat_history/my_session.json

" Clear chat history
:CursorChatClear

" Close chat window
:CursorChatClose
```

### Apply Feature

Apply AI-generated code directly to your buffers.

```vim
" Preview code blocks from last response
:CursorPreview

" Apply code from last response
:CursorApply
" Or use keymap: <leader>cy

" You'll be prompted to choose:
" - Replace entire buffer
" - Append to end
" - Insert at cursor

" Apply to new buffer
:CursorApplyNew
```

### Status

Check plugin status and configuration.

```vim
:CursorStatus
" Or use keymap: <leader>cs
```

## Commands Reference

| Command | Description |
|---------|-------------|
| `:CursorSetup` | Initialize plugin (called automatically) |
| `:CursorStatus` | Show plugin status |
| `:CursorAsk <question>` | Ask a question |
| `:CursorAskInteractive` | Ask with input prompt |
| `:CursorAskVisual` | Ask about visual selection |
| `:CursorAskBuffer` | Ask about current buffer |
| `:CursorChat` | Open chat interface |
| `:CursorChatClear` | Clear chat history |
| `:CursorChatSave [file]` | Save chat session |
| `:CursorChatLoad <file>` | Load chat session |
| `:CursorChatClose` | Close chat window |
| `:CursorApply` | Apply last AI response |
| `:CursorApplyNew` | Apply to new buffer |
| `:CursorPreview` | Preview code blocks |

## Default Key Mappings

| Mode | Key | Action |
|------|-----|--------|
| Normal | `<leader>ca` | Ask (interactive) |
| Visual | `<leader>ca` | Ask about selection |
| Normal | `<leader>cc` | Open chat |
| Normal | `<leader>cy` | Apply code |
| Normal | `<leader>cs` | Show status |

## Examples

### Example 1: Refactor Code

```vim
" 1. Select code you want to refactor
" 2. Press <leader>ca (or :CursorAskVisual)
" 3. Type: "Refactor this to use list comprehension"
" 4. Review the response
" 5. Press <leader>cy to apply changes
```

### Example 2: Debug Assistance

```vim
" 1. Select buggy code
" 2. :CursorAskVisual Why isn't this working?
" 3. Get detailed explanation
" 4. Ask follow-up questions in :CursorChat
```

### Example 3: Learn New Concepts

```vim
:CursorAsk Explain Python decorators with examples
" Review detailed explanation in floating window
```

## Troubleshooting

### Cursor CLI Not Found

```vim
:CursorStatus
" Check if CLI is detected

" If not, set custom path in config:
require('cursor').setup({
  cli_path = '/path/to/cursor'
})
```

### Authentication Issues

Ensure Cursor CLI is authenticated:

```bash
cursor auth login
```

### Timeout Errors

Increase timeout for complex queries:

```lua
require('cursor').setup({
  timeout = 60000  -- 60 seconds
})
```

### Debug Mode

Enable debug logging:

```lua
require('cursor').setup({
  debug = true
})
```

## Architecture

cursor.vim is built with a dual modular architecture supporting both Vim and Neovim:

```
cursor.vim/
├── plugin/cursor.vim          # Auto-detects Vim/Neovim and loads appropriate implementation
├── lua/cursor/                # Neovim implementation (Lua)
│   ├── init.lua              # Main module
│   ├── config.lua            # Configuration
│   ├── cli.lua               # Cursor CLI interface (libuv)
│   ├── ask.lua               # Ask feature
│   ├── chat.lua              # Chat feature
│   ├── apply.lua             # Code application
│   └── ui.lua                # UI components
└── autoload/cursor/           # Vim implementation (Vimscript)
    ├── init.vim              # Main module
    ├── config.vim            # Configuration
    ├── cli.vim               # Cursor CLI interface (job_start)
    ├── ask.vim               # Ask feature
    ├── chat.vim              # Chat feature
    ├── apply.vim             # Code application
    └── ui.vim                # UI components
```

**Both implementations provide feature parity** - all commands and features work identically in Vim and Neovim.

## Contributing

Contributions are welcome! Please feel free to submit issues and pull requests.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Why Use cursor.vim with GitHub Copilot?

cursor.vim and [copilot.vim](https://github.com/github/copilot.vim) serve different but complementary purposes:

**GitHub Copilot excels at:**
- Inline code suggestions as you type
- Autocomplete for repetitive patterns
- Fast, context-aware completions

**cursor.vim excels at:**
- Interactive Q&A and explanations
- Multi-turn conversations with context
- Debugging and learning
- Applying complex code changes with preview
- Explicit code generation on demand

**Together, they provide:**
- 🚀 **Faster coding** - Copilot for quick completions
- 🧠 **Better understanding** - cursor.vim for learning and debugging
- 🎯 **More control** - cursor.vim for explicit, reviewed changes
- 💪 **Complete workflow** - Cover all aspects of AI-assisted development

Many developers use both: Copilot for day-to-day completions, and cursor.vim when they need to think through problems or learn new concepts.

## Implementation Details

cursor.vim provides two complete implementations:

| Feature | Neovim (Lua) | Vim (Vimscript) |
|---------|--------------|-----------------|
| Async Operations | `vim.loop` (libuv) | `job_start()` |
| Floating Windows | `nvim_open_win()` | `popup_create()` |
| JSON Handling | `vim.json.*` | `json_encode/decode()` |
| Configuration | Lua tables | Dictionary variables |

Both implementations are maintained in parallel and provide identical functionality.

## Future Enhancements

- [ ] Planning feature integration
- [ ] Inline code completion
- [ ] Multi-model selection
- [ ] Custom system prompts
- [ ] LSP integration for context-aware suggestions
- [ ] Telescope integration
- [ ] Diff view for code changes

## License

MIT License - see [LICENSE](LICENSE) file for details

## Acknowledgments

- Inspired by [copilot.vim](https://github.com/github/copilot.vim)
- Built for [Cursor](https://cursor.com) AI integration
- Powered by [Neovim](https://neovim.io)

## Links

- [Cursor](https://cursor.com)
- [Cursor CLI Documentation](https://cursor.com/cli)
- [Neovim](https://neovim.io)
- [Vim Documentation](https://vimhelp.org)

---

<p align="center">
  Made with ❤️ for the Vim community
</p>

