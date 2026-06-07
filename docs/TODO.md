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

### 7. Clean up old docs/superpowers/

**Why:** `docs/superpowers/plans/2026-06-05-mojo.nvim.md` is an old
implementation plan with unchecked checkboxes. It's stale and misleading.

**Task:**

- Remove `docs/superpowers/plans/` directory (or archive it)
- Ensure `docs/superpowers/specs/2026-06-05-mojo.nvim-design.md` accurately
  reflects the current and planned architecture

---

## P2 — Quality & Completeness

### 8. Support `🔥` extension in autocmd pattern

**Bug:** `lua/mojo/init.lua:29` only matches `*.mojo` for env activation,
but `filetype.lua` registers both `.mojo` and `🔥` files. If `🔥` is already
registered, the filetype detection will work, but env activation won't trigger
automatically for `🔥` files.

**Fix:** Add `🔥` (or `*.🔥`) to the autocmd pattern.

---

### 9. Split env.lua into separate concerns

**Why:** `lua/mojo/env.lua` currently handles:

- Root directory discovery
- Pixi environment detection
- Virtualenv detection
- Binary discovery (`mojo`, `mojo-lsp-server`)
- PATH and environment variable manipulation
- Terminal activation

This violates the single-concern-per-module principle.

**Task:** Split into:

- `lua/mojo/env/detect.lua` — detection logic
- `lua/mojo/env/activate.lua` — PATH/env manipulation and terminal activation
- `lua/mojo/env/bin.lua` — binary discovery (`get_mojo_cmd`, `get_lsp_cmd`)
- Or keep a single `env.lua` but extract helpers into private submodules

---

### 10. Add .editorconfig

**Why:** No `.editorconfig` means inconsistent editor settings for contributors.

---

### 13. Support popular Neovim tools with README documentation

**Scope:** Ongoing — new tools are added here as they're identified.
Each tool follows: Research → Adapter (if needed) → README section.

**Initial batch:**

| Tool           | Research | Adapter | README | Status |
| -------------- | -------- | ------- | ------ | ------ |
| nvim-lint      | ⬜       | ⬜      | ⬜     | 🔴     |
| nvim-cmp       | ⬜       | ⬜      | ⬜     | 🔴     |
| blink.cmp      | ⬜       | ⬜      | ⬜     | 🔴     |
| LuaSnip        | ⬜       | ⬜      | ⬜     | 🔴     |
| nvim-dap       | ⬜       | ⬜      | ⬜     | 🔴     |
| neotest        | ⬜       | ⬜      | ⬜     | 🔴     |
| telescope.nvim | ⬜       | ⬜      | ⬜     | 🔴     |
| which-key.nvim | ⬜       | ⬜      | ⬜     | 🔴     |
| trouble.nvim   | ⬜       | ⬜      | ⬜     | 🔴     |
| lualine.nvim   | ⬜       | ⬜      | ⬜     | 🔴     |
| AstroNvim      | ⬜       | ⬜      | ⬜     | 🔴     |
| NvChad         | ⬜       | ⬜      | ⬜     | 🔴     |
| kickstart.nvim | ⬜       | ⬜      | ⬜     | 🔴     |

**Adding new tools:** Append a new row when a tool is identified.
Process: research → create adapter (if needed) → add README section → check off columns.

---

## P3 — Polish

### 11. Decouple debug.lua from config.options

**Why:** `lua/mojo/debug.lua:39` reads `config.options` directly. This creates
an implicit ordering dependency (config must be set up before debug works).

**Fix:** Pass the debug flag explicitly through module setup or function args.

---

### 12. General code review

- Check for macOS-specific assumptions (e.g., `DYLD_FALLBACK_LIBRARY_PATH`)
- Ensure all `pcall`-guarded requires have correct fallback behavior
- Remove any dead code from initial scaffolding
