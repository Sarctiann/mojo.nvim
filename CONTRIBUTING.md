# Contributing to mojo.nvim

## Project Stewardship

I am the circumstantial owner of this plugin — I maintain it because nobody else
has stepped up yet. My intention is to align with the structural will of the Mojo
community.

If you are a member of the Mojo/Modular community with a meaningful role in it
and you also use Neovim, you may request contributor access to this project.
I will gladly grant it.

## Project Purpose

This project exists to bridge the gap between the software Modular provides and
our beloved Neovim editor. Its reason for being is directly tied to this gap —
if Modular ships official Neovim support, the plugin's scope adapts accordingly.

## Priority Hierarchy

When deciding how to implement a feature, follow this priority order:

1. **Modular official tools** — vendor-provided binaries (LSP server, formatter,
   DAP server, CLI) are always the first choice. We discover them at runtime,
   never bundle them.
2. **Our own implementations** — centralized in this repository for correct
   Neovim integration. Designed so each piece can be replaced by Modular's
   official tool when it ships (see Sovereignty Rule 2).
3. **Third-party tools** — temporary, transitional, or last-resort dependencies
   only. Any Mojo-specific Neovim tool by a third party must be re-implemented
   here rather than added as a dependency (see Sovereignty Rule 3).

---

## Sovereignty Rules

The full sovereignty rules are defined in `AGENTS.md` and apply to all
contributions. The short version:

1. **Complete Centralization** — mojo.nvim is the single source of truth for Mojo
   support in Neovim. No additional Mojo-specific plugins needed.
2. **Modular → Official Replacement Path** — each feature is one module, swappable
   when Modular ships official tooling.
3. **No Third-Party Mojo Plugin Dependencies** — re-implement rather than depend
   on external Mojo-specific plugins.
4. **Adapter Pattern** — generic Neovim plugin integrations are stateless adapters
   in `lua/mojo/adapters/`.
5. **Zero-Bundle** — never bundle Modular binaries; discover them at runtime.
6. **Environmental Autonomy** — detect and activate the correct language
   environment transparently.
7. **One Breaking-Change Point** — when Modular ships a breaking change, the
   update surface is a single module.

---

## Project Structure

```
mojo.nvim/
├── lua/mojo/                # Plugin source
│   ├── init.lua             # Entrypoint — wires modules, no business logic
│   ├── config.lua           # Config defaults, merge logic, EmmyLua type classes
│   ├── <feature>.lua        # One concern per module (lsp.lua, terminal.lua, ...)
│   ├── env/                 # Environment detection subsystem
│   │   ├── init.lua         # Public API re-exports
│   │   ├── detect.lua       # SDK detection (pixi, venv)
│   │   ├── bin.lua          # Binary discovery (mojo, lsp, dap)
│   │   ├── activate.lua     # Environment activation
│   │   └── util.lua         # Shared utilities
│   └── adapters/            # Optional, stateless generic-plugin integrations
│       ├── lualine.lua      # lualine.nvim adapter
│       ├── lspconfig.lua    # native vim.lsp.config adapter
│       ├── conform.lua      # conform.nvim adapter
│       ├── dap.lua          # nvim-dap adapter
│       ├── blink.lua        # blink.cmp adapter
│       ├── nvim-cmp.lua     # nvim-cmp adapter
│       ├── treesitter.lua   # nvim-treesitter adapter
│       └── lazyvim.lua      # LazyVim adapter
├── tests/                   # Test files (see Testing section below)
├── docs/
│   ├── TODO.md              # Feature tracking against VS Code
│   ├── superpowers/
│   │   ├── specs/           # Design documents
│   │   └── plans/           # Implementation plans
│   └── posts/               # Community update drafts
├── AGENTS.md                # Sovereignty rules & conventions (AI + contributors)
├── CONTRIBUTING.md          # This file
└── README.md                # User-facing documentation
```

## Module Conventions

- `lua/mojo/<feature>.lua` — one concern, one file.
- `lua/mojo/adapters/<name>.lua` — stateless adapters for generic plugins. Never
  become hard dependencies.
- `init.lua` wires modules together; it contains no business logic.
- `config.lua` owns all defaults, merge logic, and EmmyLua type class definitions
  (namespace `Mojo-lang.*`).

## Configuration

Adding a new config option requires changes in two places:

1. **`config.lua`** — define the type class (e.g., `Mojo-lang.StatuslineConfig`),
   add defaults to `M.defaults`, and a field in the parent `Mojo-lang.Config`.
2. **`init.lua`** — read the option from `opts` and wire it to the relevant module
   during `setup()`.

Type annotations use EmmyLua format:

```lua
--- @class Mojo-lang.MyFeatureConfig
--- @field enabled boolean|nil
--- @field some_option string|nil
--- @field adapter (fun(opts: Mojo-lang.MyFeatureConfig): boolean)|nil
```

Optional function types must be parenthesized before `|nil`:
```lua
--- @field adapter (fun(opts: Mojo-lang.MyFeatureConfig): boolean)|nil
```

Public functions MUST have `@param` and `@return` annotations. The `Mojo-lang.*`
namespace is defined in `config.lua` only — other files reference it without
redefining.

## Dependencies

- No `require()` of a third-party Mojo-specific plugin.
- Generic plugins (`nvim-treesitter`, `conform.nvim`, `nvim-dap`, etc.) use
  `pcall` — optional. (LSP uses the native `vim.lsp.config` API, no
  `nvim-lspconfig` dependency.)
- If a generic plugin is missing, the feature degrades gracefully (returns
  `false`).

## Documentation

| File | Audience | Content |
|------|----------|---------|
| `README.md` | Users | Installation, setup, features. No internal rules. |
| `AGENTS.md` | Contributors & AI agents | Sovereignty rules, conventions. |
| `CONTRIBUTING.md` | Contributors | This file — governance, structure, workflow. |
| `docs/superpowers/specs/` | Contributors | Design documents for new subsystems. |
| `docs/superpowers/plans/` | Contributors | Implementation plans. |
| `docs/TODO.md` | All | Feature tracking against VS Code extension. |

Keep all docs consistent by running `update-docs` after features land, after
TODO updates, or periodically as a maintenance pass.

Commit messages use conventional commits: `feat:`, `fix:`, `docs:`, `refactor:`.

## Testing

Tests live in `tests/` and run via Neovim's headless mode.

**Running tests:**
```bash
nvim --headless -c "luafile tests/<test_file>.lua" -c "qa!"
```

**Existing test:** `tests/test_queries.lua` — parses `.mojo` samples, reports
Tree-sitter ERROR nodes, and runs capture assertions.

**Test pattern:**
- Tests are standalone Lua files executed by `luafile`.
- They report PASS/FAIL per assertion and aggregate errors.
- On failure, exit with code `cq <error_count>` (non-zero).
- Test samples and fixtures go in `tests/` subdirectories
  (e.g., `tests/mojo_samples/`).

There is no test framework dependency — tests use plain Lua and `nvim` API calls.
New tests should follow this pattern.

---

## Workflow

The plugin uses skills (in `.agents/skills/`) to automate workflows:

| Skill | When to use |
|-------|-------------|
| `mojo-task-workflow` | Executing a task from `docs/TODO.md` |
| `mojo-todo-update` | Updating `docs/TODO.md` after audit or task completion |
| `mojo-community-post` | Drafting community update posts |
| `update-docs` | Auditing docs for accuracy and consistency after features land |

For AI agents: load the relevant skill before starting a task.
