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

### 2. Extract generic-plugin integration from core modules into adapters

**Rule violated:** #4 (Adapter Pattern for Generic Extensions)

**Why:** Three core modules directly call `setup()` on generic plugins instead
of producing pure options consumed by adapters:

| Module                    | Direct call to                     | Line |
| ------------------------- | ---------------------------------- | ---- |
| `lua/mojo/lsp.lua`        | `lspconfig.mojo.setup()`           | 55   |
| `lua/mojo/format.lua`     | `conform.setup()`                  | 40   |
| `lua/mojo/treesitter.lua` | `nvim-treesitter.parsers` mutation | 11   |

**Fix:** Make `lsp.lua`, `format.lua`, and `treesitter.lua` pure option/state
builders. Move every `setup()` call that wires to a generic plugin into
corresponding adapter modules under `lua/mojo/adapters/`:

- `lua/mojo/adapters/lspconfig.lua` — wraps `lspconfig.mojo.setup()`
- `lua/mojo/adapters/conform.lua` — wraps `conform.setup()`
- `lua/mojo/adapters/treesitter.lua` — wraps `nvim-treesitter` registration

The `init.lua` entrypoint should call adapters when the corresponding feature
is enabled, not call the core modules' `setup()` directly.

**Files affected:**

- `lua/mojo/lsp.lua`
- `lua/mojo/format.lua`
- `lua/mojo/treesitter.lua`
- `lua/mojo/init.lua`
- Create: `lua/mojo/adapters/lspconfig.lua`
- Create: `lua/mojo/adapters/conform.lua`
- Create: `lua/mojo/adapters/treesitter.lua`
- `docs/superpowers/specs/2026-06-05-mojo.nvim-design.md` — update architecture

---

### 3. Move business logic out of init.lua

**Rule violated:** Module Structure (AGENTS.md § "The entrypoint (`init.lua`)
only wires modules together; it contains no business logic.")

**Why:** `lua/mojo/init.lua:28-37` creates an autocmd directly for env
activation. This is business logic, not wiring.

**Fix:** Move the `BufReadPre`/`BufNewFile` autocmd into `filetype.lua`
(which already registers filetype detection for the same purpose) or into
`env.lua`.

**Files affected:**

- `lua/mojo/init.lua` — remove autocmd block
- `lua/mojo/filetype.lua` — add autocmd for env activation
- `lua/mojo/env.lua` — export a setup function if needed

---

## P1 — Missing Infrastructure

### 4. Add test infrastructure and initial tests

**Why:** No tests exist. Every feature needs coverage before refactoring.

**Task:** Choose a Neovim test runner (plenary.nvim's test harness is the de
facto standard). Add tests for at minimum:

- `env.lua` — detection logic (pixi vs venv), PATH manipulation
- `filetype.lua` — filetype registration
- `config.lua` — merge logic
- `hooks.lua` — merge logic
- `debug.lua` — log output

**Files created:**

- `tests/` directory
- `tests/env_spec.lua`
- `tests/filetype_spec.lua`
- `tests/config_spec.lua`
- `tests/hooks_spec.lua`
- `tests/debug_spec.lua`

---

### 5. Add CI configuration

**Why:** No CI means no automated test runs or linting.

**Task:** Add GitHub Actions workflow that runs tests on push/PR.

**Files created:**

- `.github/workflows/ci.yml`

---

### 6. Fill missing EmmyLua type annotations

**Rule violated:** Coding Conventions — "All public functions MUST have
EmmyLua `--- @param`, `--- @return` annotations."

**Missing in:**

- `lua/mojo/filetype.lua` — `M.setup()` has no annotations at all
- `lua/mojo/treesitter.lua` — `M.setup()` missing `@return`, `compile_parser` and `stale_parser` missing `@return`
- `lua/mojo/terminal.lua` — `M.setup()` has no `@return`
- `lua/mojo/format.lua` — `M.opts()` has no `@return` (opts table shape)

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

| Tool | Research | Adapter | README | Status |
|------|----------|---------|--------|--------|
| nvim-lint | ⬜ | ⬜ | ⬜ | 🔴 |
| nvim-cmp | ⬜ | ⬜ | ⬜ | 🔴 |
| blink.cmp | ⬜ | ⬜ | ⬜ | 🔴 |
| LuaSnip | ⬜ | ⬜ | ⬜ | 🔴 |
| nvim-dap | ⬜ | ⬜ | ⬜ | 🔴 |
| neotest | ⬜ | ⬜ | ⬜ | 🔴 |
| telescope.nvim | ⬜ | ⬜ | ⬜ | 🔴 |
| which-key.nvim | ⬜ | ⬜ | ⬜ | 🔴 |
| trouble.nvim | ⬜ | ⬜ | ⬜ | 🔴 |
| lualine.nvim | ⬜ | ⬜ | ⬜ | 🔴 |
| AstroNvim | ⬜ | ⬜ | ⬜ | 🔴 |
| NvChad | ⬜ | ⬜ | ⬜ | 🔴 |
| kickstart.nvim | ⬜ | ⬜ | ⬜ | 🔴 |

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
