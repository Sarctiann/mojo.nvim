# mojo.nvim

Neovim integration for [Mojo](https://www.modular.com/mojo).

Centralizes filetype detection, Treesitter, LSP, formatting, and environment
activation — designed so each piece can be swapped when
[Modular](https://www.modular.com) ships official tooling.

## What it provides

- `.mojo` and `🔥` filetype detection
- Treesitter parser registration for Mojo
- Environment helpers for Pixi and virtualenv projects
- LSP and formatter integration (opt-in, via `nvim-lspconfig` / `conform.nvim`)
- Terminal environment auto-activation
- LazyVim adapter helpers
- EmmyLua type annotations (module: `Mojo-lang`)

## Features

### Filetype
`.mojo` and `🔥` files are automatically recognized as `mojo` filetype.

### Environment
Detects Pixi (`pixi.toml` / `.pixi/`) and virtualenv (`.venv/`) projects and
activates them for LSP, formatting, and terminal buffers transparently.

### Treesitter
Registers the Mojo parser with `nvim-treesitter`.

### LSP
Configures `mojo-lsp-server` via `nvim-lspconfig` with environment-aware binary
resolution (finds the binary in the active Pixi/venv environment).

### Format
Configures `mojo format` via `conform.nvim` with environment-aware binary resolution.

### Terminal
Auto-activates the project environment in new shell terminal buffers.

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

### Setup

```lua
require("mojo").setup({
  debug = true,       -- writes mojo-debug.log to cwd
  lsp = { enabled = true },
  format = { enabled = true },
  treesitter = { enabled = true },
  terminal = { enabled = true },
})
```

### LazyVim adapters

```lua
local mojo = require("mojo.adapters.lazyvim")

-- nvim-treesitter
{ "nvim-treesitter/nvim-treesitter",
  opts = function(_, opts) return mojo.treesitter(opts) end,
}

-- nvim-lspconfig
{ "neovim/nvim-lspconfig",
  opts = function(_, opts) return mojo.lsp(opts) end,
}

-- conform.nvim
{ "stevearc/conform.nvim",
  opts = function(_, opts) return mojo.format(opts) end,
}
```

## Configuration

All options and their defaults:

```lua
{
  filetype = { enabled = true },
  terminal = {
    enabled = true,
    auto_activate = true,
    delay_ms = 200,
  },
  treesitter = {
    enabled = true,
    parser = {
      install_info = {
        url = "https://github.com/oaustegard/tree-sitter-mojo",
        revision = "v1.0",
        queries = "queries",
      },
      filetype = "mojo",
      tier = 2,
    },
  },
  lsp = {
    enabled = false,
    root_markers = { "pixi.toml", "pyproject.toml", ".pixi", ".venv" },
  },
  format = {
    enabled = false,
    formatter_name = "mojo",
  },
  debug = false,
  hooks = {},
}
```

## Notes

- The plugin does not ship the Mojo LSP binary or official toolchain.
- When `debug = true`, logs are written to `mojo-debug.log` in the current working directory.
- The plugin auto-activates Pixi or venv project environments before Mojo LSP startup and in terminal buffers.
- Treesitter is isolated behind `lua/mojo/treesitter.lua` so the parser backend can be replaced later.
