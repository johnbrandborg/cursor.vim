# Contributing to cursor.vim

Thank you for your interest in contributing to cursor.vim! This document provides guidelines and instructions for contributing.

> **⚠️ Note**: cursor.vim is currently in **ALPHA** status. We welcome contributions, especially bug reports and fixes as we work toward a stable release!

## How to Contribute

### Reporting Bugs

If you find a bug, please open an issue with:

- A clear, descriptive title
- Steps to reproduce the issue
- Expected behavior
- Actual behavior
- Your environment (Neovim version, OS, Cursor CLI version)
- Any relevant logs or error messages

### Suggesting Features

Feature suggestions are welcome! Please open an issue with:

- A clear description of the feature
- Use cases and benefits
- Any implementation ideas you might have

### Pull Requests

1. **Fork the repository**

2. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make your changes**
   - Follow the existing code style
   - Use clear, descriptive variable and function names
   - Add comments for complex logic
   - Keep commits focused and atomic

4. **Test your changes**
   - Test in Neovim
   - Verify all commands work as expected
   - Test edge cases

5. **Commit your changes**
   ```bash
   git commit -m "Add feature: description of feature"
   ```

   Follow conventional commit messages:
   - `feat:` for new features
   - `fix:` for bug fixes
   - `docs:` for documentation changes
   - `refactor:` for code refactoring
   - `test:` for adding tests
   - `chore:` for maintenance tasks

6. **Push to your fork**
   ```bash
   git push origin feature/your-feature-name
   ```

7. **Open a Pull Request**
   - Provide a clear description of the changes
   - Reference any related issues
   - Explain the rationale behind your changes

## Code Style

### Lua

- Use 2 spaces for indentation
- Use snake_case for local variables and functions
- Use PascalCase for module tables (M)
- Add comments for non-obvious code
- Follow existing patterns in the codebase

Example:
```lua
local M = {}

-- Clear, descriptive function name
local function parse_response(data)
  if not data or data == '' then
    return nil, 'Empty response'
  end

  return vim.json.decode(data)
end

function M.public_function()
  local result = parse_response('...')
  return result
end

return M
```

### Vimscript

- Use 2 spaces for indentation
- Use clear, descriptive command names
- Add help tags for new commands
- Document command options

## Project Structure

```
cursor.vim/
├── plugin/         # Entry point, command registration
├── lua/cursor/     # Lua implementation
│   ├── init.lua   # Main module
│   ├── config.lua # Configuration
│   ├── cli.lua    # CLI interface
│   ├── ask.lua    # Ask feature
│   ├── chat.lua   # Chat feature
│   ├── apply.lua  # Apply feature
│   └── ui.lua     # UI components
└── doc/           # Documentation
```

## Development Workflow

1. **Setup development environment**
   ```bash
   # Clone the repository
   git clone https://github.com/johnbrandborg/cursor.vim.git
   cd cursor.vim

   # Create symlink for development
   ln -s $(pwd) ~/.config/nvim/pack/dev/start/cursor.vim
   ```

2. **Make changes**
   - Edit files in your preferred editor
   - Reload Neovim to test changes

3. **Test changes**
   ```vim
   " Reload plugin
   :lua package.loaded['cursor'] = nil
   :lua require('cursor').setup()

   " Test commands
   :CursorStatus
   :CursorAsk Test question
   ```

4. **Debug**
   ```lua
   -- Enable debug mode
   require('cursor').setup({ debug = true })
   ```

## Documentation

- Update README.md for user-facing changes
- Update doc/cursor.txt for new commands/functions
- Add examples for new features
- Keep documentation clear and concise

## Testing

While we don't have automated tests yet, please manually test:

- All affected commands work
- Error handling works correctly
- UI components display properly
- Chat history persists correctly
- Code application works as expected

## Questions?

Feel free to open an issue for any questions about contributing!

## Code of Conduct

- Be respectful and constructive
- Welcome newcomers
- Focus on the issue, not the person
- Collaborate in good faith

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

