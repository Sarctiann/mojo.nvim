# mojo.nvim — TODO

> Priorities are based on AGENTS.md sovereignty rules. P0 = blocks sovereignty.
> Each item references the rule(s) it violates or satisfies.

## Workflow Rules

1. **One branch per task** — each P0/P1 item below is done in a separate
   branch from `main`. No mixing concerns.
2. **No commits without request** — never commit unless I explicitly ask.
3. **Merge then next** — once tested and committed, merge to `main`, then
   start the next task on a fresh branch.

---

## P0 — Sovereignty Violations (must fix)

### ~~1. Re-implement tree-sitter-mojo parser in-repo~~ ✅

**Rule violated:** #3 (No Third-Party Mojo Plugin Dependencies)

**Resolution:** The tree-sitter-mojo grammar was adopted into `tree-sitter/mojo/`
as a self-hosted copy. Updated for Mojo 1.0 syntax: `struct`/`trait`/`thin`/`abi`/
`register_passable` reserved keywords, `capture_list`/`capture_item` productions,
restructured `function_definition` for all effect/raises/return orderings,
bare `raises` keyword, `grammar.cjs` → `grammar.js` rename.

`treesitter.lua` now manages the full parser lifecycle: stale grammar detection,
auto-rebuild with `cc`, query file sync, `:MojoRebuildParser` command. No longer
depends on `TSInstall mojo`.

**Files changed:**

- `tree-sitter/mojo/` — grammar source, generated parser, queries
- `lua/mojo/treesitter.lua` — self-managed parser lifecycle (auto-rebuild, `:MojoRebuildParser`)
- `lua/mojo/env.lua` — `clear` on terminal activation
- `README.md` — auto-rebuild docs
- `docs/superpowers/specs/2026-06-06-mojo-grammar-1.0-update-design.md`

**Branch:** `feat/self-host-treesitter-parser`

---

### ~~2. Extract generic-plugin integration from core modules into adapters~~ ✅

**Rule violated:** #4 (Adapter Pattern for Generic Extensions)

**Resolution:** Core modules now only produce pure options/state — all side-effect
calls (`lspconfig.mojo.setup()`, `conform.setup()`, `nvim-treesitter` registration,
autocmds, `:MojoRebuildParser`) moved to adapter modules. `init.lua` calls adapters
(default) or a user-supplied `adapter` function; core modules are dependency-free.

**Files changed:**

- `lua/mojo/lsp.lua` — removed `M.setup()`, pure option builder
- `lua/mojo/format.lua` — removed `M.setup()`, pure option builder
- `lua/mojo/treesitter.lua` — removed `M.setup()`, exposes `register()`, `compile_parser()`, `stale_parser()`
- `lua/mojo/init.lua` — calls adapters, supports `adapter` override per feature
- Create: `lua/mojo/adapters/lspconfig.lua`
- Create: `lua/mojo/adapters/conform.lua`
- Create: `lua/mojo/adapters/treesitter.lua`
- `lua/mojo/config.lua` — added `adapter` fields to type definitions
- `docs/superpowers/specs/2026-06-05-mojo.nvim-design.md` — updated architecture

**Branch:** `refactor/extract-adapters`

---

### ~~3. Move business logic out of init.lua~~ ✅

**Rule violated:** Module Structure (AGENTS.md § "The entrypoint (`init.lua`)
only wires modules together; it contains no business logic.")

**Resolution:** The `BufReadPre`/`BufNewFile` autocmd for env activation moved
from `init.lua` into `filetype.lua`, which also gained the `🔥` extension
pattern. `init.lua` now only wires modules and adapters.

**Files changed:**

- `lua/mojo/init.lua` — removed autocmd block, calls adapters
- `lua/mojo/filetype.lua` — added env activation autocmd

**Branch:** `refactor/extract-adapters`

---

## P1 — Missing Infrastructure

### ~~4. Add test infrastructure and initial tests~~ ⏸️ On hold

Deferred until core features stabilize and the plugin API solidifies.

### ~~5. Add CI configuration~~ ⏸️ On hold

Deferred until test infrastructure (P1 #4) is in place.

---

### ~~6. Fill missing EmmyLua type annotations~~ ✅

**Rule violated:** Coding Conventions — "All public functions MUST have
EmmyLua `--- @param`, `--- @return` annotations."

**Resolution:** Added missing annotations to `filetype.lua`, `terminal.lua`,
and `format.lua`. `treesitter.lua` public functions (`compile_parser`,
`register`, `stale_parser`) already had `@return` annotations from the
adapter extraction refactor.

---

### ~~7. Clean up old docs/superpowers/~~ ✅

**Resolution:** Removed `docs/superpowers/plans/` entirely (all plans were stale
or already executed). Updated `specs/2026-06-05-mojo.nvim-design.md` to reflect
the current adapter-based architecture.

---

## P2 — Quality & Completeness

### ~~8. Support `🔥` extension in autocmd pattern~~ ✅

**Resolution:** Fixed as part of P0 #3 refactor — the env activation autocmd
was moved from `init.lua` to `filetype.lua`, which already uses the pattern
`{ "*.mojo", "*.🔥" }`.

---

### ~~9. Split env.lua into separate concerns~~ ✅

**Why:** `lua/mojo/env.lua` violated single-concern-per-module.

**Resolution:** Split into `lua/mojo/env/` directory:
- `env/util.lua` — shared filesystem/environment helpers
- `env/detect.lua` — environment detection and caching
- `env/activate.lua` — PATH/env variable manipulation, terminal activation
- `env/bin.lua` — binary discovery (`get_mojo_cmd`, `get_lsp_cmd`)
- `env/init.lua` — backward-compatible re-export of full public API

`require("mojo.env")` still works; no consumer changes needed.
`DetectedEnv` class definition moved to `config.lua` per AGENTS.md convention.

**Branch:** `refactor/split-env`

---

### ~~10. Add .editorconfig~~ ✅

**Resolution:** Added `.editorconfig` with tabs for Lua, spaces for JSON/YAML/TOML/markdown/queries, LF line endings, UTF-8, trailing whitespace trimming.

---

### 13. Support popular Neovim tools with README documentation

**Scope:** Ongoing — new tools are added here as they're identified.
Each tool follows: Research → Adapter (if needed) → README section.

**Analysis results:**

| Tool           | Needs adapter? | Needs README? | Notes |
| -------------- | -------------- | ------------- | ----- |
| nvim-lint      | No             | Yes           | Mojo has no linter beyond `mojo format` and LSP diagnostics. nvim-lint would need a Mojo linter binary that doesn't exist yet. Could point users to LSP diagnostics via `diagnosticls` or `null-ls` bridge, but that's fragile. |
| nvim-cmp       | No             | No            | Works automatically — receives LSP completions from `mojo-lsp-server` via the standard `nvim_lsp` source. Already noted in README. |
| blink.cmp      | No             | No            | Same as nvim-cmp — works via LSP protocol. No adapter needed. |
| LuaSnip        | No             | Yes (minimal) | Works with Treesitter integration for snippet expansion. Could document Mojo snippets if user creates them, but no adapter needed. |
| nvim-dap       | Yes            | Yes           | Mojo has no DAP adapter yet. Blocked on Modular releasing a debug adapter. Could document how to set up when one exists. |
| neotest        | Yes            | Yes           | Mojo has no test runner adapter yet. Blocked on `mojo test` stabilizing. Could document future integration. |
| telescope.nvim | No             | No            | Works automatically — picks up `.mojo`/`🔥` files in standard pickers. Already noted in README. |
| which-key.nvim | No             | No            | Works automatically — discovers any Mojo-related keymaps the user defines. |
| trouble.nvim   | No             | No            | Works automatically — displays diagnostics from `mojo-lsp-server`. Already noted in README. |
| lualine.nvim   | No             | Yes (minimal)  | Could document a Mojo filetype icon, but lualine picks up filetype automatically. No adapter needed. |
| AstroNvim      | No             | Yes           | Distribution integration — just needs a docs section showing how to configure mojo.nvim within AstroNvim's config format. No adapter per sovereignty rule #4. |
| NvChad         | No             | Yes           | Same as AstroNvim — docs section showing NvChad config. No adapter. |
| kickstart.nvim  | No             | Yes           | Same — docs section showing minimal kickstart config. No adapter. |

**Tools that need action now:**
- nvim-cmp, blink.cmp, telescope.nvim, which-key.nvim, trouble.nvim → already in README, no change
- LuaSnip, lualine.nvim → minimal README note (no adapter)
- AstroNvim, NvChad, kickstart.nvim → README sections showing config
- nvim-dap, neotest → blocked on upstream (Modular debug adapter / stable `mojo test`)
- nvim-lint → blocked (no Mojo linter binary exists)

**Adapters to create: None currently needed.**

---

## P3 — Polish

### ~~11. Decouple debug.lua from config.options~~ ✅

**Why:** `debug.lua` read `config.options` directly, creating an implicit ordering dependency.

**Resolution:** Added `M.setup({ debug = boolean })` to `debug.lua`. `init.lua` now calls `debug.setup({ debug = opts.debug })` explicitly after config merge. Removed the `require("mojo.config")` dependency from `debug.lua`.

---

### ~~12. General code review~~ ✅

**Findings addressed:**

- macOS-specific `DYLD_FALLBACK_LIBRARY_PATH` in `env/activate.lua` — now uses
  `vim.fn.has("mac")` to select `DYLD_FALLBACK_LIBRARY_PATH` (macOS) or
  `LD_LIBRARY_PATH` (Linux) appropriately.
- All `pcall`-guarded requires (`lspconfig`, `conform`, `nvim-treesitter.parsers`)
  have correct fallback behavior (return `false`, skip silently).
- No dead code found — all modules are consumed by `init.lua` or adapters.
