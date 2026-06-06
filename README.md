# mojo.nvim

Generic Neovim integration for Mojo.

`mojo.nvim` centralizes the editor-side pieces needed to work with Mojo while keeping the official Mojo tools external.
The plugin is designed to be generic and modular so each piece can be replaced later if Modular ships an official tool.

## What it provides

- `.mojo` filetype detection
- Treesitter parser registration for Mojo
- Environment helpers for Pixi and virtualenv projects
- Optional LSP and formatter adapters
- Terminal environment activation helpers
- LazyVim adapter helpers

## Installation

### lazy.nvim

```lua
{
  "Sarctiann/mojo.nvim",
  dev = true,
  dir = "~/Documents/SARCTIANN/LuaCode/custom_plugins/mojo.nvim",
  main = "mojo",
  opts = {},
}
```

## Setup

```lua
require("mojo").setup({
  lsp = {
    enabled = true,
  },
  format = {
    enabled = true,
  },
  treesitter = {
    enabled = true,
  },
  terminal = {
    enabled = true,
  },
})
```

## LazyVim adapters

```lua
local mojo = require("mojo.adapters.lazyvim")

{
  "nvim-treesitter/nvim-treesitter",
  opts = function(_, opts)
    return mojo.treesitter(opts)
  end,
}

{
  "neovim/nvim-lspconfig",
  opts = function(_, opts)
    return mojo.lsp(opts)
  end,
}

{
  "stevearc/conform.nvim",
  opts = function(_, opts)
    return mojo.format(opts)
  end,
}
```

## Notes

- The plugin does not ship the Mojo LSP binary.
- The plugin does not bundle the official Mojo toolchain.
- The plugin auto-activates Pixi or venv project environments before Mojo LSP startup and in terminal buffers.
- Treesitter is isolated behind `lua/mojo/treesitter.lua` so the parser backend can be replaced later.
