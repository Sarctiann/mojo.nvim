# 🔥 mojo.nvim

Neovim integration for [Mojo](https://www.modular.com/mojo).

Centralizes filetype detection, Treesitter, LSP, formatting, and environment activation—designed so each piece can be swapped when [Modular](https://www.modular.com) ships official tooling.

![mojo.nvim demo](docs/demo.gif)

## Index

- [What it provides](#what-it-provides)
- [Features](#features)
  - [Filetype](#filetype)
  - [Environment](#environment)
  - [Treesitter](#treesitter)
  - [LSP](#lsp)
  - [Format](#format)
  - [Terminal](#terminal)
  - [Completion](#completion)
  - [Run](#run)
  - [Indentation](#indentation)
- [Commands](#commands)
- [Keymaps](#keymaps)
- [Statusline](#statusline)
- [Installation](#installation)
- [Setup](#setup)
- [Configuration](#configuration)
- [Integrations](#integrations)
- [Notes](#notes)
  - [Environment detection chain](#environment-detection-chain)
  - [LSP crash recovery](#lsp-crash-recovery)
  - [Hooks](#hooks)
  - [Adapter overrides](#adapter-overrides)
  - [Tools that work without config](#tools-that-work-without-mojo-specific-config)

## What it provides

- `.mojo` and `🔥` filetype detection
- Treesitter parser registration for Mojo
- Environment helpers for Pixi, virtualenv, and manual SDK paths
- LSP and formatter integration (via `nvim-lspconfig` / `conform.nvim`)
- Terminal environment auto-activation
- Completion support (nvim-cmp / blink.cmp) with keywords, builtins, types, and snippets
- lualine.nvim statusline integration with SDK version display
- `MojoVersion` component for non-lualine statuslines
- 🚧 Debugging support — nvim-dap (mojo-lldb-dap) + native terminal (mojo debug)
- Run current Mojo file with `:Mojo run` / `:Mojo dedicated`
- LSP lifecycle management (`:Mojo menu`, `:Mojo restart`, `:Mojo stop`, `:Mojo refresh`)
- 4-space indentation for Mojo files
- LazyVim, AstroNvim, NvChad, and kickstart.nvim adapter helpers
- EmmyLua type annotations (module: `Mojo-lang`)
- Adapter pattern for every integration — swap any backend without changing config

## Features

### Filetype

`.mojo` and `🔥` files are automatically recognized as `mojo` filetype. The plugin adds these to Neovim's filetype detection and triggers environment activation for each Mojo buffer.

### Environment

Detects Pixi (`pixi.toml` / `.pixi/`) and virtualenv (`.venv/`) projects and activates them for LSP, formatting, and terminal buffers transparently. Also supports manual SDK path override via `config.sdk_path` or the `$MOJO_SDK_PATH` environment variable.

### Treesitter

Registers the self-hosted Mojo parser grammar with `nvim-treesitter`. The grammar files live in `tree-sitter/mojo/` — no external parser repo required. Automatically checks for grammar updates and recompiles when needed, with `:Mojo rebuild` (or `:MojoRebuildParser` when `commands.spread = true`) for manual rebuilds.

### LSP

Configures `mojo-lsp-server` via `nvim-lspconfig` with environment-aware binary resolution (finds the binary in the active Pixi/venv environment). Supports custom root markers for project detection.

### Format

Configures `mojo format` via `conform.nvim` with environment-aware binary resolution. Provides consistent formatting across the editor.

### Terminal

Auto-activates the project environment in new shell terminal buffers. Detects shell terminals and applies the correct activation command before they start.

### Completion

Provides keyword autocompletion for Mojo-specific keywords (53), builtin functions (38), standard library types (30), and snippets (12). Integrates with nvim-cmp and blink.cmp via dedicated adapters. Completion is context-aware — it defers to LSP completions after `.` and `:`.

### Run

Execute the current Mojo file with `:Mojo run` (opens a terminal split) or `:Mojo dedicated` (opens or reuses a dedicated terminal buffer). Both commands resolve the `mojo` binary through the active environment and display a winbar with close instructions. If `commands.spread = true`, the individual `:MojoRun` and `:MojoRunDedicated` commands are also available.

### Debug 🚧

Debug the current Mojo file with `:Mojo debug` (auto-selects backend), `:Mojo debug-native` (terminal via `mojo debug`), or `:Mojo debug-dap` (nvim-dap). The auto backend prefers DAP when `mojo-lldb-dap` is available (pixi), falling back to native `mojo debug` (uv). If `commands.spread = true`, individual `:MojoDebug`, `:MojoDebugNative`, and `:MojoDebugDap` commands are also available.

Native debug (`:MojoDebugNative`) opens a terminal with LLDB keymaps: `r` (run), `n` (next), `s` (step), `c` (continue), `v` (frame variable), `b` (sync breakpoints), `q`/`<Esc>`/`<CR>` (close). Editor breakpoints (set via `<leader>db` or nvim-dap) are synced to LLDB on open and on save.

DAP debug (`:MojoDebugDap`) requires [nvim-dap](https://github.com/mfussenegger/nvim-dap) and provides four launch configurations: Debug Mojo File, Debug Mojo File (with args), Debug Binary, and Attach to Process.

### Indentation

Sets 4-space indentation for Mojo files (matching Python-style conventions) via `ftplugin/mojo.lua`.

## Commands

Commands are configured via the `commands` option. By default only the master `:Mojo` command is created (`commands.spread = false`). Set `commands.spread = true` to also register the individual commands.

| Command              | Description                                                |
| -------------------- | ---------------------------------------------------------- |
| `:Mojo {subcommand}` | Master command with tab-completion (see below)             |
| `:MojoMenu`          | Open floating actions menu (restart/stop LSP, refresh SDK) |
| `:MojoRefreshSDK`    | Clear SDK cache and re-detect environment                  |
| `:MojoRestartLSP`    | Restart Mojo LSP server                                    |
| `:MojoStopLSP`       | Stop Mojo LSP server                                       |
| `:MojoRun`           | Run current `.mojo` file in a terminal split               |
| `:MojoRunDedicated`  | Run current `.mojo` file in a dedicated terminal buffer    |
| `:MojoDebug`         | 🚧 Debug current `.mojo` file (auto-selects best backend)  |
| `:MojoDebugNative`   | 🚧 Debug via `mojo debug` in terminal (dbg_native)        |
| `:MojoDebugDap`      | 🚧 Debug via nvim-dap + mojo-lldb-dap (dbg_dap)           |
| `:MojoRebuildParser` | Manually rebuild the self-hosted tree-sitter Mojo parser   |

`:Mojo` subcommands: `menu`, `run`, `dedicated`, `debug`, `debug-native`, `debug-dap`, `restart`, `stop`, `refresh`, `rebuild`, `keymaps`, `help`. Press `<Tab>` after `:Mojo ` to cycle through them.

## Keymaps

Default keymaps for Mojo buffers. These can be overridden or disabled per-keymap via the `keymaps` config section — set any entry to `false` to disable it, or change the LHS string to rebind.

| Keymap               | Modes            | Context           | Description                                   |
| -------------------- | ---------------- | ----------------- | --------------------------------------------- |
| `K`                  | Normal           | `FileType mojo`   | Signature help inside parens, hover otherwise |
| `<leader>ca`         | Normal, Visual   | `FileType mojo`   | Code action (`vim.lsp.buf.code_action`)       |
| `q`, `<Esc>`, `<CR>` | Normal, Terminal | `:MojoRun` buffer | Close run terminal                            |
| `r` `n` `s` `c` `v`  | Normal           | 🚧 Debug terminal | LLDB: run, next, step, continue, frame var    |
| `b`                  | Normal           | 🚧 Debug terminal | Re-sync breakpoints from editor signs         |

The `:MojoMenu` floating window also has numbered keymaps `1`, `2`, `3` mapped to each action, and `q` / `<Esc>` to close.

## Statusline

Shows environment name, SDK version, and tool status indicators (LSP, formatter, debugger, diagnostics). Indicators are clickable — click on any to open the `:MojoMenu` floating window with restart/stop LSP and refresh SDK actions.

Status icons: `󰄬` (active/green), `○` (inactive/yellow), `󰅖` (error/red).

Highlight groups: `MojoIcon`, `MojoText`, `MojoSep`, `MojoGood`, `MojoNeutral`, `MojoWarn`, `MojoErr`.

Configure per-indicator with `statusline` options or use `require("mojo.status").display()` for non-lualine statuslines.

## Installation

<details open>
<summary><a href="https://github.com/folke/lazy.nvim">lazy.nvim</a></summary>

```lua
{
  "Sarctiann/mojo.nvim",
  main = "mojo",
  opts = {},
}
```

</details>

<details>
<summary><a href="https://github.com/wbthomason/packer.nvim">packer.nvim</a></summary>

```lua
use {
  "Sarctiann/mojo.nvim",
  config = function()
    require("mojo").setup({})
  end,
}
```

</details>

<details>
<summary><a href="https://github.com/echasnovski/mini.deps">mini.deps</a></summary>

```lua
local add = MiniDeps.add

add({
  source = "Sarctiann/mojo.nvim",
  depends = {},
})

require("mojo").setup({})
```

</details>

<details>
<summary><a href="https://github.com/tpope/vim-plug">vim-plug</a></summary>

```vim
Plug 'Sarctiann/mojo.nvim'

lua << EOF
require("mojo").setup({})
EOF
```

</details>

<details>
<summary><a href="https://github.com/lumen-oss/rocks.nvim">rocks.nvim</a></summary>

Run `:Rocks install mojo.nvim` then add to your init.lua:

```lua
require("mojo").setup({})
```

</details>

## Setup

```lua
require("mojo").setup({
  verbose = true, -- writes mojo-debug.log to cwd
})
```

All features are enabled by default. Pass `enabled = false` to disable any feature.

**Note:** `opts` (lazy.nvim) and `setup()` accept the same config table.

## Configuration

<details>
<summary>All options and their defaults</summary>

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
    adapter = nil, -- custom adapter function
  },
  lsp = {
    enabled = true,
    root_markers = { "pixi.toml", "pyproject.toml", ".pixi", ".venv" },
    include_dirs = nil, -- extra include directories
    filter_docstring_diagnostics = nil, -- filter diagnostics in docstrings
    adapter = nil, -- custom adapter function
  },
  format = {
    enabled = true,
    formatter_name = "mojo",
    adapter = nil, -- custom adapter function
  },
  completion = {
    enabled = true,
    adapter = nil, -- custom adapter function
  },
  keymaps = {
    enabled = true,
    signature_help = "K", -- LHS string, or false to disable
    code_action = "<leader>ca", -- LHS string, or false to disable
  },
  commands = {
    master = true, -- creates :Mojo {subcommand} with tab-completion
    spread = false, -- creates individual :MojoMenu, :MojoRun, etc.
  },
  sdk_path = nil, -- or "/path/to/mojo/sdk"
  statusline = {
    enabled = true,
    icon = "🔥",
    show_env_name = true,
    show_sdk_version = true,
    show_lsp = true,
    show_dbg = true,
    show_fmt = true,
    show_diag = true,
    clickable = true,
    colored = true,
    color = "#ff9e64",
    icon_color = "#ff6f00",
    adapter = nil, -- custom adapter function
  },
  debug = {
    enabled = true,
    auto_scroll = true,
    auto_backend = nil, -- nil = auto, "native", "dap"
    search_for = { -- searched in order; user can extend for custom envs
      { name = "lldb-dap",       role = "dap" },
      { name = "_mojo-lldb-dap", role = "dap" },
      { name = "mojo-lldb-dap",  role = "dap" },
      { name = "lldb-dap",       role = "dap" },
      { name = "mojo-lldb",      role = "native" },
      { name = "lldb",           role = "native" },
    },
    adapter = nil, -- custom adapter function
  },
  verbose = false,
  hooks = {},
}
```

</details>

## Integrations

All integrations are optional — the plugin degrades gracefully if the backend is not installed.

| Integration  | Backend                  | Adapter                                                          |
| ------------ | ------------------------ | ---------------------------------------------------------------- |
| LSP          | `nvim-lspconfig`         | `lua/mojo/adapters/lspconfig.lua`                                |
| Formatting   | `conform.nvim`           | `lua/mojo/adapters/conform.lua`                                  |
| Treesitter   | `nvim-treesitter`        | `lua/mojo/adapters/treesitter.lua`                               |
| Completion   | `nvim-cmp` / `blink.cmp` | `lua/mojo/adapters/nvim-cmp.lua` / `lua/mojo/adapters/blink.lua` |
| 🚧 Debugging | `nvim-dap`               | `lua/mojo/adapters/dap.lua`                                      |
| Statusline   | `lualine.nvim`           | `lua/mojo/adapters/lualine.lua`                                  |
| Distribution | LazyVim                  | `lua/mojo/adapters/lazyvim.lua`                                  |

AstroNvim, NvChad, and kickstart.nvim work by just adding `{ "Sarctiann/mojo.nvim" }` to your plugins — no adapter needed.

Each adapter can be replaced via its feature's `adapter` config field for custom behavior.

## Notes

- The plugin does not ship the Mojo LSP binary or official toolchain
- 🚧 Debugging is enabled by default; native terminal backend degrades gracefully when `mojo` not found
- When `verbose = true`, logs are written to `mojo-debug.log` in the current working directory
- The plugin auto-activates Pixi or venv project environments before Mojo LSP startup and in terminal buffers
- Treesitter is isolated behind `lua/mojo/treesitter.lua`. The parser grammar is self-hosted in `tree-sitter/mojo/`. The plugin auto-rebuilds the parser when the grammar source changes; `:MojoRebuildParser` is available for manual rebuilds
- Mojo files use 4-space indentation (configured via `ftplugin/mojo.lua`)

### Environment detection chain

1. **Manual SDK path** — `config.sdk_path` or `$MOJO_SDK_PATH` env var
2. **Derived environment** — `.derived/bin/` directory
3. **Pixi environment** — `pixi.toml` or `.pixi/` directory
4. **Virtual environment** — `.venv/bin/`
5. **No environment** — falls back to system PATH

Detection results are cached per project root. Clear cache with `:MojoRefreshSDK`.

### LSP crash recovery

The plugin tracks LSP server exits and applies exponential backoff on restart (0s → 5s → 30s → 60s) with a cap at 3 restarts. The counter resets after 30 seconds of stable running.

### Hooks

The plugin exposes a `hooks` system for extensibility. Currently available hook:

- `resolve_root(path, markers)` — override root directory detection (defaults to `vim.fs.root()`)

### Adapter overrides

Every feature accepts an optional `adapter` field in its config table. When set, the plugin calls `adapter(opts)` instead of its default adapter, allowing complete swapping of any backend without changing the rest of the config.

### Tools that work without Mojo-specific config

- telescope.nvim — picks up `.mojo`/`.🔥` files in standard pickers
- trouble.nvim — displays diagnostics from `mojo-lsp-server` automatically
- nvim-cmp / blink.cmp — receives LSP completions from `mojo-lsp-server` via the `nvim_lsp` source
- which-key.nvim — discovers any Mojo-related keymaps you define

Adapter-based integration for other tools is tracked in `docs/TODO.md`.
