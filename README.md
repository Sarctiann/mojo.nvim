# mojo.nvim

Sovereign Neovim integration for [Mojo](https://www.modular.com/mojo).

`mojo.nvim` owns the entire Mojo- Neovim surface. It centralizes filetype detection,
Treesitter, LSP, formatting, environment activation, and any future language tooling
into a single, modular plugin designed to be replaced piece by piece when
[Modular](https://www.modular.com) ships official tools.

## Sovereignty Rules

1. **Complete Centralization** — Every Mojo-specific Neovim feature lives here.
2. **Modular → Official Replacement** — Each module can be rewritten independently when
   Modular ships an official alternative.
3. **No Third-Party Mojo Dependencies** — Mojo-specific third-party plugins are
   re-implemented here, not depended on.
4. **Adapter Pattern** — Generic integrations (LazyVim) live in `adapters/` and are
   always optional.
5. **Zero-Bundle for Official Binaries** — LSP server, formatter, and CLI tools are
   discovered at runtime, never bundled.
6. **Environmental Autonomy** — Pixi and venv environments are detected and activated
   transparently for LSP, formatting, and terminals.
7. **One Breaking-Change Point** — When Modular ships a change, only the relevant
   module needs updating.

## What it provides

- `.mojo` and `🔥` filetype detection
- Treesitter parser registration for Mojo
- Environment helpers for Pixi and virtualenv projects
- LSP and formatter integration (opt-in, via `nvim-lspconfig` / `conform.nvim`)
- Terminal environment auto-activation
- LazyVim adapter helpers
- EmmyLua type annotations (module: `Mojo-lang`)

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
  debug = true,
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
- When `debug = true`, logs are written to `mojo-debug.log` in the current working directory.
- The plugin auto-activates Pixi or venv project environments before Mojo LSP startup and in terminal buffers.
- Treesitter is isolated behind `lua/mojo/treesitter.lua` so the parser backend can be replaced later.
- All public APIs are annotated with EmmyLua types (`Mojo-lang.*`).
- Full design spec at `docs/superpowers/specs/2026-06-05-mojo.nvim-design.md`.
