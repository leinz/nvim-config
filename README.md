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
- `gd`: go to definition
- `gr`: references
- `<leader>ca`: code action
- `<leader>rn`: rename
- `-`: file browser

