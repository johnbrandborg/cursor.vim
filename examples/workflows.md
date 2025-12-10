# cursor.vim Workflow Examples

This document provides practical workflow examples for using cursor.vim in your daily development.

## Workflow 1: Code Review Assistant

Use cursor.vim to review and improve your code:

```vim
" 1. Open a file you want to review
:e mycode.py

" 2. Select the function or code block (visual mode)
V10j

" 3. Ask for a review
<leader>ca
" Type: "Review this code for bugs and improvements"

" 4. Read the suggestions

" 5. Open chat for follow-up questions
<leader>cc
" Type: "How would I implement the first suggestion?"

" 6. Apply the suggested code
<leader>cy
```

## Workflow 2: Learning New Concepts

Use the chat feature for interactive learning:

```vim
" 1. Open chat
:CursorChat

" 2. Start a conversation
" Type: "I want to learn about async/await in Python"

" 3. Ask follow-up questions
" Type: "Show me an example with error handling"

" 4. Apply example code to new buffer
<Esc>
:CursorApplyNew

" 5. Save the chat for later reference
:CursorChatSave learning_async_2024.json
```

## Workflow 3: Refactoring Code

Systematically refactor code with AI assistance:

```vim
" 1. Select code to refactor
:%  " Select entire file, or use visual mode for specific sections

" 2. Ask for refactoring suggestions
<leader>ca
" Type: "Refactor this to follow clean code principles"

" 3. Preview the suggested changes
<leader>cp

" 4. Apply changes
<leader>cy
" Choose: "Replace entire buffer"

" 5. Verify changes
:w
:!python -m pytest  " Or your test command
```

## Workflow 4: Documentation Generation

Generate documentation for your code:

```vim
" 1. Select a function
V}

" 2. Ask for documentation
<leader>ca
" Type: "Generate docstring for this function"

" 3. Apply at cursor position
<leader>cy
" Choose: "Insert at cursor"
```

## Workflow 5: Debugging Complex Issues

Use chat for step-by-step debugging:

```vim
" 1. Open the buggy file
:e buggy_script.py

" 2. Start chat with context
:CursorAskBuffer This script throws an error, help me debug it

" 3. Share error messages in chat
<leader>cc
" Type: "The error is: KeyError: 'username'"

" 4. Get suggestions and try fixes

" 5. Iterate until resolved
```

## Workflow 6: Writing Tests

Generate tests for your functions:

```vim
" 1. Open implementation file
:e calculator.py

" 2. Select function to test
/def add<CR>
V%

" 3. Ask for tests
<leader>ca
" Type: "Write pytest tests for this function including edge cases"

" 4. Apply to new test file
<leader>cy
" Choose: "New buffer"

" 5. Save test file
:saveas test_calculator.py
```

## Workflow 7: Code Translation

Translate code between languages:

```vim
" 1. Select Python code
:%

" 2. Ask for translation
<leader>ca
" Type: "Translate this Python code to Rust"

" 3. Review and apply
<leader>cy
" Choose: "New buffer"

" 4. Save as new file
:w mycode.rs
```

## Workflow 8: Quick Snippets

Generate code snippets on the fly:

```vim
" 1. In insert mode, ask for a snippet
<Esc>
:CursorAsk Create a Python decorator for timing function execution

" 2. Apply at cursor
<leader>cy
" Choose: "Insert at cursor"
```

## Workflow 9: API Integration

Get help integrating with APIs:

```vim
" 1. Open chat
:CursorChat

" 2. Describe what you need
" Type: "Show me how to make a POST request to a REST API with authentication headers using Python requests"

" 3. Get example code

" 4. Ask for error handling
" Type: "Add retry logic with exponential backoff"

" 5. Apply complete solution
<Esc>
:CursorApplyNew
```

## Workflow 10: Daily Code Assistant

Keep a chat session for ongoing help throughout the day:

```vim
" Morning: Start a chat
:CursorChat
" Type: "I'm working on a web scraper today. I'll ask questions as I go."

" Throughout the day: Keep returning to the same chat
<leader>cc
" The history is preserved!

" Evening: Save the session
:CursorChatSave daily_work_2024_12_10.json

" Next time: Load if needed
:CursorChatLoad ~/.local/share/nvim/cursor_chats/daily_work_2024_12_10.json
```

## Tips for Effective Usage

### Be Specific

Instead of:
```
"Fix this code"
```

Try:
```
"This function should handle empty lists but currently crashes. Add error handling for edge cases."
```

### Provide Context

When asking about code:
- Use visual selection to include relevant code
- Mention the language/framework
- Describe what the code should do

### Iterate in Chat

For complex problems:
1. Start with a general question
2. Ask follow-up questions
3. Request specific implementations
4. Ask for explanations of suggestions

### Preview Before Apply

Always preview code changes:
```vim
<leader>cp  " Preview first
<leader>cy  " Then apply
```

### Save Important Sessions

```vim
:CursorChatSave important_session.json
```

## Combining with Other Tools

### With LSP

```vim
" 1. Use LSP for navigation
gd  " Go to definition

" 2. Ask Cursor about it
<leader>ca
" Type: "Explain how this function works"
```

### With Git

```vim
" 1. See changes
:!git diff

" 2. Ask for review
:CursorAsk Review my recent changes and suggest improvements

" 3. Apply fixes
<leader>cy
```

### With Terminal

```vim
" 1. Run tests in terminal
:term pytest

" 2. Copy error, ask Cursor
<leader>ca
" Type: "This test fails with [error], how do I fix it?"
```

## Performance Tips

- Increase timeout for complex queries
- Use specific prompts to get faster responses
- Preview large changes before applying
- Clear chat history periodically for focused contexts

## Next Steps

- Experiment with different prompts
- Combine cursor.vim with your existing workflow
- Share useful prompts with your team
- Create custom keymaps for common queries

