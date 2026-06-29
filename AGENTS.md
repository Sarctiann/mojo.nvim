# mojo.nvim — Sovereignty Rules & Conventions

> These rules govern ALL development on this plugin. They define how and why we build
> things. Every AI agent and contributor MUST follow them.

## Sovereignty Rules

### 1. Complete Centralization
The plugin is the single source of truth for Mojo support in Neovim.
Every editor-side piece required to work with Mojo lives here or is wired through here.
Users should not need additional Mojo-specific Neovim plugins.

### 2. Modular → Official Replacement Path
Each feature is isolated behind a clear module boundary (`lua/mojo/<feature>.lua`).
The module API is designed so that when Modular ships an official tool, only that module
needs to be rewritten — the rest of the plugin and user configuration stays unchanged.

### 3. No Third-Party Mojo Plugin Dependencies
Any Mojo-specific Neovim tool created by a third party must be re-implemented in this
repository rather than added as a dependency. The plugin must be self-sufficient for
Mojo work. Generic tools (`nvim-treesitter`, `conform.nvim`, `nvim-dap`) remain
optional backends — the plugin adapts to them, not the other way around. LSP uses
Neovim's native `vim.lsp.config` API directly (no `nvim-lspconfig` dependency).

### 4. Adapter Pattern for Generic Extensions
Integration with generic Neovim plugin ecosystems (LazyVim, lazy.nvim, etc.) must be
implemented as stateless adapters in `lua/mojo/adapters/<name>.lua`. Adapters transform
the plugin's internal API into the shape the generic plugin expects. They must never
become hard dependencies.

### 5. Zero-Bundle for Official Binaries
The plugin must never bundle Modular's official binaries (LSP server, formatter, DAP
server, CLI tools). It discovers them through environment helpers that search Pixi
environments, virtualenvs, and system PATH. Users always get their own managed
binaries.

### 6. Environmental Autonomy
The plugin must detect and activate the correct language environment (Pixi, venv)
transparently. LSP, formatter, and terminal sessions must inherit the correct PATH,
library paths, and environment variables without user intervention.

### 7. One Breaking-Change Point
When Modular ships a breaking change or an official tool, the update surface is the
single module that wraps that concern. The design spec and README must be updated
to reflect the new recommended path (load `update-docs` to audit).

## Coding Conventions

### Type Annotations
- All public functions MUST have EmmyLua `--- @param`, `--- @return` annotations.
- Classes use the `Mojo-lang.*` namespace (defined in `config.lua`).
- Class definitions must live in ONE file only (`config.lua`). Other files reference
  them without redefining.
- Use `(fun(...): type)|nil` for optional function fields (parenthesize the function
  type before `|nil`).

### Module Structure
- `lua/mojo/<feature>.lua` — one concern per module.
- `lua/mojo/adapters/<name>.lua` — optional integrations, always stateless.
- The entrypoint (`init.lua`) only wires modules together; it contains no business logic.
- Config lives in `config.lua` with defaults, merge, and all type class definitions.

### Dependencies
- No `require()` of a third-party Mojo-specific plugin.
- Generic plugins (`nvim-treesitter`, `conform`, `nvim-dap`) use `pcall` —
  optional. LSP uses the native `vim.lsp.config` API (no `nvim-lspconfig`).
- If a generic plugin is missing, the feature degrades gracefully (returns `false`).
- DAP adapter (`mojo-lldb-dap`) discovery follows same pattern as LSP server:
  env-resolution first, PATH fallback.

### Documentation
- `README.md` is for users: installation, setup, features. No internal rules.
- `AGENTS.md` is for contributors and AI agents: sovereignty rules, conventions.
- `docs/superpowers/specs/` — design documents and specs.
- `docs/superpowers/plans/` — implementation plans.
- Commit messages use conventional commits (`feat:`, `fix:`, `docs:`, `refactor:`).

## Skills

Workflow automation lives in `.agents/skills/`. Load the relevant skill before
starting a task:

| Skill | When to load |
|-------|-------------|
| `mojo-task-workflow` | When executing any task from `docs/TODO.md` |
| `mojo-todo-update` | When updating `docs/TODO.md` after an audit or completed task |
| `mojo-community-post` | When drafting a community update post |
| `update-docs` | When auditing docs for accuracy and consistency after features land |

Each skill contains the full workflow and conventions for that concern.
