# Debug Improvements — Unified Debug Experience

**Status:** Partially Implemented
**Date:** 2026-06-28
**Updated:** 2026-06-29 (post debugger bugfix session)

## Implementation Divergences

| Spec | Implementation | Reason |
|------|---------------|--------|
| `breakpoints.lua` toggle/clear use only signs | Uses nvim-dap `dap.breakpoints` API when available, `MojoBreakpoint` signs as fallback | Integrates with `<leader>db` keymap; breakpoints shared across backends |
| `sync()` does incremental diff with LLDB ID tracking | `sync_all()` re-sends all breakpoints (no ID tracking) | Simpler, no parsing needed; duplicate `breakpoint set` is idempotent in LLDB |
| `M.status()` returns `{ backends: string[] }` | Returns `{ native: boolean, dap: boolean, active: string\|nil }` | Simpler for statusline rendering |
| `get_buffer_bps()` returns `{ [line] = true }` | `get_lines()` returns sorted `integer[]` | More ergonomic for iteration |
| `debug.start()` uses `active_backend` optimistic set | `_start_dap()` sets `active_backend` inside, with `pcall` wrapper on `dap.run()` | Prevents false "active" status on DAP launch failure |
| Double build on DAP launch | `mojoFile` returns source path directly; `program` calls `M.build()` once | Eliminates redundant compilation |

## Goal

Unify mojo.nvim's two debugging backends (`dbg_native` via `mojo debug` terminal,
`dbg_dap` via `mojo-lldb-dap` + nvim-dap) behind a single user-facing interface
with shared breakpoints, consistent commands, and auto-scroll.

## Background

The Mojo SDK ships two debugging tools:

| Binary | Logical name | Availability | Type |
|--------|-------------|--------------|------|
| `mojo-lldb` | `dbg_native` | Always (uv + pixi) | LLDB CLI via terminal |
| `mojo-lldb-dap` / `_mojo-lldb-dap` | `dbg_dap` | Only pixi envs | DAP server (needs nvim-dap) |

Currently, each backend is wired independently:
- `:MojoDebug` (commands.lua) → `mojo debug <file>` in a terminal with LLDB keymaps
- `adapters/dap.lua` → nvim-dap adapter for `mojo-lldb-dap` with 4 configs

There is no shared breakpoint system, no unified entry point, and no auto-scroll.

## Architecture

### Module layout

```
lua/mojo/
├── debug/                  <-- NEW directory
│   ├── init.lua            -- Public API: start(), toggle_bp(), clear_bps(), status()
│   ├── native.lua          -- dbg_native: mojo debug terminal, LLDB command dispatch
│   ├── breakpoints.lua     -- Shared BP signs, diff tracking, LLDB sync
│   └── window.lua          -- Terminal window, winbar, keymaps, auto-scroll
├── adapters/dap.lua        -- UNCHANGED: nvim-dap bridge (optional dependency)
├── env/bin.lua             -- MODIFIED: add get_dbg_native_cmd("mojo-lldb")
├── commands.lua            -- MODIFIED: Mojo debug [native|dap]
├── status.lua              -- MODIFIED: dbg_status() reflects both backends
└── config.lua              -- MODIFIED: Mojo-lang.DebugConfig class
```

### Data flow

```
:Mojo debug (auto)
      │
      ▼
debug.start("auto")
      │
      ├── env.get_dap_cmd() trouve mojo-lldb-dap?
      │        └── sí → adapters/dap.lua (nvim-dap, sin cambios)
      │
      └── env.get_dbg_native_cmd("mojo-lldb") ou get_mojo_cmd() existe?
               │
               ├── Nota: en pixi → mojo-lldb (LLDB CLI completo + breakpoints)
               ├── Nota: en uv   → mojo debug (vía mojo CLI, sin mojo-lldb)
               │
               └── sí → debug/native.lua
                          │
                          ├── debug/window.lua: abre terminal mojo debug <file>
                          │   - winbar con keymaps [r][n][s][c][v][b][q]
                          │   - auto-scroll configurable
                          ├── debug/breakpoints.lua: lee signs → envía commands LLDB
                          └── debug/breakpoints.lua: activa watcher para cambios
```

## Components

### `debug/init.lua` — Entry point

```lua
--- @param backend "auto"|"native"|"dap"|nil
function M.start(backend)

--- Toggle breakpoint at cursor line (sign-based, no deps)
function M.toggle_bp()

--- Clear all breakpoints in current buffer
function M.clear_bps()

--- Return status info
--- @return { backends: string[], active: string|nil, bps: integer }
function M.status()
```

- `start("auto")`: tries `get_dbg_dap_cmd()`, then `get_dbg_native_cmd()`, in order
- `start("native")`: forces terminal-based debugging
- `start("dap")`: forces nvim-dap (requires nvim-dap installed)

### `debug/native.lua` — dbg_native backend

Responsibilities:
- Abrir terminal con `mojo debug <file>` via `vim.cmd("belowright terminal ...")`
- Mantener referencia al job_id y buffer de la terminal
- `send_command(cmd)` — envía comando LLDB al terminal job
- `send_breakpoint(line)` — envía `breakpoint set --file "<file>" --line <N>`
- `remove_breakpoint(id)` — envía `breakpoint delete <id>`
- `close()` — cierra la terminal si está abierta

State tracking:
- LLDB breakpoint IDs (asignados por LLDB) mapeados a líneas de Neovim
- Requiere parsear output de `breakpoint set` para extraer el `id` (ej: `Breakpoint 1: where = ...`)

### `debug/breakpoints.lua` — Shared breakpoints

Sin dependencias externas. Usa `vim.fn.sign_getplaced()` para leer breakpoints.

```lua
function M.get_buffer_bps(buf)
  --- Returns: { [line] = true, ... }
end

function M.toggle(buf, line)
  --- Adds or removes a sign
end

function M.clear(buf)
  --- Removes all signs
end

function M.sync(chan_id, filepath)
  --- Calculates diff between Nvim signs and LLDB state
  --- Sends breakpoint set/delete to terminal job
end

function M.watch(chan_id, filepath)
  --- Sets up autocmd to detect sign changes on BufWritePost/BufLeave
  --- Calls sync() on change
end

function M.unwatch()
  --- Removes autocmd
end
```

Sign definition:
```lua
vim.fn.sign_define("MojoBreakpoint", { text = "●", texthl = "DiagnosticSignError" })
```

Tracking LLDB breakpoint IDs:
- Después de `breakpoint set`, LLDB responde con `Breakpoint N: ...`
- Se parsea esa respuesta y se guarda `lua_breakpoints[line] = lldb_id`
- Al hacer diff, los IDs viejos se usan para `breakpoint delete <id>`

### `debug/window.lua` — Terminal window management

- Reutiliza y mejora lo que ya existe en `commands.lua:setup_debug_terminal()`
- Winbar con keymaps: `[r]un [n]ext [s]tep [c]ontinue [v]ars [q]uit`
- Auto-scroll: después de cada `chan_send`, mueve cursor al final del buffer
- Configurable vía `config.debug.auto_scroll` (default: true)

```lua
function M.setup_window(buf, win)
  --- Sets winbar, keymaps, auto-scroll
end

function M.auto_scroll(buf, win)
  --- vim.api.nvim_win_set_cursor(win, { line_count, 0 })
end
```

### `env/bin.lua` — New binary detection

```lua
--- @param path string|nil
--- @return string|nil
function M.get_dbg_native_cmd(path)
  --- Finds "mojo-lldb" in env bin_dir, pixi envs, or PATH
  --- Same pattern as get_lsp_cmd()
end

--- Existing get_dap_cmd stays as-is (finds mojo-lldb-dap / _mojo-lldb-dap)
```

### Config — `config.lua`

```lua
--- @class Mojo-lang.DebugConfig
--- @field enabled boolean|nil
--- @field auto_scroll boolean|nil
--- @field auto_backend "native"|"dap"|nil   -- nil means auto-detect
--- @field adapter (fun(opts: Mojo-lang.DebugConfig): boolean)|nil
```

Default: `{ enabled = false, auto_scroll = true, auto_backend = nil }`

### Commands — `commands.lua`

```
:Mojo debug             — start(auto)
:Mojo debug native      — start("native")
:Mojo debug dap         — start("dap")
```

El master command `:Mojo` se extiende:
```lua
local dispatch = {
  ["debug"] = function(args)
    if args == "native" then debug.start("native")
    elseif args == "dap" then debug.start("dap")
    else debug.start("auto")
    end
  end,
}
```

El subcommand `debug` acepta `nargs = "?"`, completa con `native`/`dap`.

### Status — `status.lua`

`dbg_status()` se actualiza para reflejar ambos backends:

```lua
function M.dbg_status()
  local has_dap = env.get_dbg_dap_cmd() ~= nil
  local has_native = env.get_dbg_native_cmd() ~= nil
  if has_dap then
    local ok, dap = pcall(require, "dap")
    if ok and dap.session and dap.session() then
      return "active"
    end
    return "inactive"  -- dap available
  end
  if has_native then
    -- could check if native debug terminal is open
    return "inactive"
  end
  return "unavailable"
end
```

## Breakpoint sync protocol (dbg_native)

### Initial sync (on open)

```lua
for line, _ in pairs(buffer_bps) do
  send_command(string.format(
    'breakpoint set --file "%s" --line %d', filepath, line
  ))
end
```

LLDB response por cada `breakpoint set`:
```
Breakpoint 1: where = File.swift:12, address = ...
```

Parseo simple: capturar `Breakpoint (\d+)` con `string.match()`.

### Incremental sync (on change)

Cuando el usuario agrega/quita breakpoints mientras dbg_native está activo:

1. `watch_bps()` detecta cambio via `BufWritePost` o `BufLeave`
2. `sync_bps()` compara `current_signs` vs `lldb_state`
3. Para cada línea nueva: `breakpoint set --file ... --line ...`
4. Para cada línea removida: `breakpoint delete <id>`
5. Actualiza `lldb_state` map

### Edge cases

- Archivo guardado con nuevas líneas → breakpoints en líneas incorrectas. No se
  intenta re-mapear; el usuario debe re-aplicar breakpoints. Se podría mejorar
  en el futuro con tracking de cambios de línea.
- Múltiples archivos abiertos → solo el archivo actual está en debug.
- LLDB no responde → se ignora el error (el usuario ve el error en la terminal).

## Auto-scroll

Después de cada `vim.api.nvim_chan_send()`, si `config.debug.auto_scroll != false`:

```lua
local line_count = vim.api.nvim_buf_line_count(buf)
vim.api.nvim_win_set_cursor(win, { line_count, 0 })
```

Esto asegura que el output de LLDB (breakpoints, backtraces, variables) sea
visible sin scroll manual.

## Omitted from scope

- **neotest integration** — blocked upstream (mojo test not stable)
- **Visualizers** (lldbDataFormatters.py) — handled automatically by `mojo-lldb-dap`
  wrapper; out of scope for this module
- **Multi-session** — solo un debug a la vez
