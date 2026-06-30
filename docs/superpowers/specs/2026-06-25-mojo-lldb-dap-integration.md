# mojo-lldb-dap Integration (nvim-dap)

**Status:** Implemented

## Goal

Enable debugging of Mojo programs in Neovim by integrating `mojo-lldb-dap` (the
official DAP server shipped with the Mojo SDK) with `nvim-dap`.

## Background

The Mojo SDK ships two debugging-related binaries and supporting visualizers:

| Path | Type | Purpose |
|------|------|---------|
| `bin/mojo-lldb-dap` | Shell script | Wrapper that sets CONDA_PREFIX and imports Mojo visualizers |
| `bin/_mojo-lldb-dap` | Mach-O arm64 | DAP server binary (Apple's lldb-dap adapted for Mojo) |
| `bin/mojo-lldb` | Mach-O arm64 | LLDB CLI adapted for Mojo |
| `lib/lldb-visualizers/lldbDataFormatters.py` | Python | Mojo type formatters |
| `lib/lldb-visualizers/mlirDataFormatters.py` | Python | MLIR type formatters |

The DAP server (`_mojo-lldb-dap`) is a full implementation of the Debug Adapter
Protocol, originally Apple's `lldb-dap` adapted for the Mojo toolchain. It
supports stdio communication (default) or TCP (`--connection`).

## Architecture

```
┌──────────────────┐     DAP (stdio)      ┌─────────────────────┐
│  nvim-dap         │ ◄──────────────────► │  mojo-lldb-dap      │
│  (adapter: mojo)  │     JSON-RPC         │  (shell wrapper)    │
│                   │                      │       │             │
│  - launch config  │                      │  CONDA_PREFIX/bin/  │
│  - breakpoints    │                      │  _mojo-lldb-dap     │
│  - stack frames   │                      │       │             │
│  - variables      │                      │  ─pre-init-command  │
│  - REPL           │                      │  lldbDataFormatters │
└──────────────────┘                      │  mlirDataFormatters │
                                           └─────────────────────┘
```

### Adapter definition

```lua
-- lua/mojo/adapters/dap.lua
require("dap").adapters.mojo = {
  type = "executable",
  command = "mojo-lldb-dap",
  options = {
    env = function()
      local detected = require("mojo.env").detect()
      if detected and detected.env_dir then
        return { CONDA_PREFIX = detected.env_dir }
      end
      return {}
    end,
  },
}
```

The adapter sets `CONDA_PREFIX` in the DAP server's environment so the shell
wrapper can resolve `$CONDA_PREFIX/bin/_mojo-lldb-dap` and the visualizers in
`$CONDA_PREFIX/lib/lldb-visualizers/`.

### Launch configurations

The DAP server supports two mutually exclusive launch modes:

1. **`mojoFile`** — the DAP server compiles `.mojo` to a binary via `mojo build`
   (equivalent to VS Code's "Debug Mojo File"). This is the primary workflow.
2. **`program`** — debug a pre-compiled binary (for advanced users or repeat
   sessions).

And two lifecycle modes:

1. **`launch`** — spawn the target process.
2. **`attach`** — attach to an existing process by PID or name.

### Configuration mappings (VS Code → nvim-dap)

| VS Code property | nvim-dap property | Notes |
|------------------|-------------------|-------|
| `type: "mojo-lldb"` | `type: "mojo"` | Adapter type |
| `request: "launch"` | `request: "launch"` | Standard DAP |
| `request: "attach"` | `request: "attach"` | Standard DAP |
| `mojoFile` | `mojoFile` | DAP server compiles .mojo on-the-fly |
| `program` | `program` | Precompiled binary path |
| `args` | `args` | Program arguments |
| `buildArgs` | `buildArgs` | Extra args to `mojo build` |
| `cwd` | `cwd` | Working directory |
| `env` | `env` | Extra env vars |
| `stopOnEntry` | `stopOnEntry` | Pause at program start |
| `initCommands` | `initCommands` | LLDB commands at debugger init |
| `preRunCommands` | `preRunCommands` | LLDB commands before launch |
| `sourcePath` | `sourcePath` | Source path remapping |
| `runInTerminal` | `runInTerminal` | Launch in integrated terminal |

## Default configurations

```lua
require("dap").configurations.mojo = {
  {
    type = "mojo",
    request = "launch",
    name = "Debug Mojo File",
    mojoFile = "${file}",
    cwd = "${workspaceFolder}",
  },
  {
    type = "mojo",
    request = "launch",
    name = "Debug Mojo File (with args)",
    mojoFile = "${file}",
    args = function()
      local args_str = vim.fn.input("Program args: ")
      return vim.split(args_str, "%s+")
    end,
    cwd = "${workspaceFolder}",
  },
  {
    type = "mojo",
    request = "launch",
    name = "Debug Binary",
    program = function()
      return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
    end,
    cwd = "${workspaceFolder}",
  },
  {
    type = "mojo",
    request = "attach",
    name = "Attach to Process",
    pid = require("dap.utils").pick_process,
  },
}
```

## Module boundary

| Concern | Module |
|---------|--------|
| DAP adapter (nvim-dap integration) | `adapters/dap.lua` |
| Binary discovery (mojo-lldb-dap path) | `env/bin.lua` (extend `get_lsp_cmd` pattern) |
| DAP launch configuration builder | `debug.lua` (rename/reuse current debug log module) |

**Current `debug.lua`** is a logging module — it should be renamed to
`log.lua` to free the `debug` name for debugging functionality. This is a
refactoring prerequisite.

## Open questions

1. Should `dap.lua` auto-register on `setup()`, or require explicit `require("mojo.adapters.dap").setup()`?
   → Follow existing pattern: opt-in via adapter config, just like blink/nvim-cmp.
2. How to handle the `mojoFile` → binary path resolution for source maps?
   → DAP server handles it internally via `mojo build` temp output.
3. Should we configure `dap.adapters.mojo` eagerly or lazily?
   → Lazily via `dap.setup()` wrapper or explicit call, to avoid polluting dap
     config for non-Mojo users.

## Implementation plan

1. Rename `debug.lua` → `log.lua`, update all consumers (refactor-only, no behavior change)
2. Add `get_dap_cmd` to `env/bin.lua` (same pattern as `get_lsp_cmd`)
3. Create `adapters/dap.lua` with adapter + default configurations
4. Wire optional dap setup in `init.lua` behind `opts.debugging.enabled`
5. Add config types and defaults in `config.lua`
6. Document in README with minimal nvim-dap setup example
