# Neovim configuration

## Install

Start Neovim once. `lazy.nvim` will bootstrap itself and install plugins.
No language servers are downloaded until you ask Mason to install them.

Then install language tools inside Neovim:

```vim
:Mason
```

Install syntax parsers explicitly:

```vim
:TSInstall bash go gomod gosum java json lua markdown markdown_inline python rust toml vim vimdoc yaml
```

You can also run:

```vim
:MasonToolsInstall
```

## Useful keys

- `<leader>ff`: find files
- `<leader>fg`: search text
- `<leader>f`: format
- `<leader>mp`: present the current markdown file with vimdeck.nvim
- `gd`: go to definition
- `gr`: references
- `<leader>ca`: code action
- `<leader>rn`: rename
- `-`: file browser

## Markdown presentations

Markdown presentations use `vimdeck.nvim` and run inside Neovim.
Figlet headers are disabled by default so presentations do not need the
external `figlet` command.
Headers use underline styling, and vertical centering is disabled to avoid a
vimdeck.nvim header highlight offset issue.

Open a markdown file and run:

```vim
:Vimdeck
```

You can also use `<leader>mp` from a markdown buffer.

To present a specific markdown file:

```vim
:VimdeckFile path/to/slides.md
```

If a deck has frontmatter, keep `use_figlet: false` there too unless you have
installed `figlet` locally:

```markdown
---
use_figlet: false
header_style: underline
center_vertical: false
---
```
