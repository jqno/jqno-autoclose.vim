# jqno-autoclose

Autoclose plugin for Neovim (and probably Vim)

Features:

- All the traditional auto complete features for parens and quotes:
  - Typing an opening paren or quote, inserts the corresponding closer
  - Typing a `<CR>` between parens, inserts a new line and puts the closer on a line below
  - Typing a space between parens, inserts a space after the opener _and_ before the closer
  - Typing a backspace between parens, removes both the opener and the closer
- Supports hard-coded special cases for specific languages, like `|` in Ruby and Rust
- Supports double quotes such as `**` and `__` for Markdown
- Supports triple quotes such as `"""` for Java and Python
- Supports `<C-L>` as a hotkey to jump past all closing parens, quotes, and spaces in insert mode
- Supports `<CR>` when between opening and closing tags in HTML and XML
- Supports making bulleted lists in Markdown
