# README Restructure & Tool Support Tracking

**Status:** Implemented

## Goal

Restructure the mojo.nvim README to show installation options for multiple package
managers (collapsible sections) and integration guides for popular Neovim tools
(collapsible sections). Add a tracking table to `docs/TODO.md` so each tool's
progress (research → adapter → README) is visible.

## Motivation

The current README only shows `lazy.nvim` installation and has no sections for
community tools like `nvim-lint`, `nvim-cmp`, `nvim-dap`, etc. Users need to
see how to integrate mojo.nvim with their existing toolchain regardless of which
package manager or distro they use.

## README Structure

### Installation

Collapsible `<details>` blocks, one per package manager. The first entry
(lazy.nvim) is open by default (`<details open>`).

| Package Manager | Status |
|-----------------|--------|
| lazy.nvim       | ✅ Exists |
| packer.nvim     | 🔴 Pending |
| mini.deps       | 🔴 Pending |
| vim-plug        | 🔴 Pending |
| rocks.nvim      | 🔴 Pending |

Each block shows:
- Minimal plugin spec
- Dependencies if any
- Setup call

### Tool Integrations

Collapsible `<details>` blocks, one per tool category. All closed by default.
Each follows a consistent template:

```
### <emoji> <Tool Name>

Brief description of what the tool does for Mojo files.

<details>
<summary>Configuration</summary>

```lua
-- Example config showing how to wire mojo.nvim with this tool
```

</details>
```

> **⚠️ Living task — the list below is NOT definitive.** The Neovim ecosystem evolves
> constantly. This task establishes the README structure and tracking system so new
> integrations can be added incrementally as the community discovers needs —
> status bars (`lualine.nvim`), custom pickers, or tools that don't exist yet.
> No list can be final; the goal is the **process** for adding and tracking them.

### Tools to cover (initial batch)

| Category | Tool | Status |
|----------|------|--------|
| LSP | nvim-lspconfig | ✅ Done |
| Formatting | conform.nvim | ✅ Done |
| Treesitter | nvim-treesitter | ✅ Done |
| Linting | nvim-lint | 🔴 Pending |
| Autocompletion | nvim-cmp | 🔴 Pending |
| Autocompletion | blink.cmp | 🔴 Pending |
| Snippets | LuaSnip | 🔴 Pending |
| Debugging | nvim-dap | 🔴 Pending |
| Testing | neotest | 🔴 Pending |
| Distro | LazyVim | ✅ Done (adapter exists) |
| Distro | AstroNvim | 🔴 Pending |
| Distro | NvChad | 🔴 Pending |
| Distro | kickstart.nvim | 🔴 Pending |
| Utilities | telescope.nvim | 🔴 Pending |
| Utilities | which-key.nvim | 🔴 Pending |
| Utilities | trouble.nvim | 🔴 Pending |
| Statusline | lualine.nvim | 🔴 Pending |

## TODO.md Tracking Table

A single P2 entry with sub-items for each tool, designed for incremental growth:

```
### 13. Support popular Neovim tools with README documentation

**Scope:** Ongoing — new tools are added here as they're identified.
Each tool follows: Research → Adapter (if needed) → README section.

#### Initial batch

| Tool | Research | Adapter | README | Status |
|------|----------|---------|--------|--------|
| nvim-lint | ⬜ | ⬜ | ⬜ | 🔴 |
| nvim-cmp | ⬜ | ⬜ | ⬜ | 🔴 |
| ... | ... | ... | ... | ... |

#### Adding new tools

Append a new row to the table when a tool is identified. The process is:
1. Research the tool's API
2. Create adapter if code integration is needed
3. Add collapsible README section
4. Check off columns
```

Each column checked off as work progresses.

## Adapter Pattern

For tools that need code (not just docs), a new adapter is created in
`lua/mojo/adapters/<tool>.lua` following the existing conventions:

- Stateless module
- Returns `M` table with setup/opts functions
- EmmyLua annotations
- Graceful fallback if the tool isn't installed (pcall)

Some categories are purely documentation — no adapter needed:

| Category | Reason |
|----------|--------|
| Package managers | Only show plugin spec syntax, no Lua API |
| Distro integr. | Only show how to configure mojo.nvim within that distro's config format |

### Adapter scope per tool

| Tool | Adapter needed? |
|------|----------------|
| nvim-lint | Yes — wraps formatter config into linter config |
| nvim-cmp | No — standard cmp-source integration |
| blink.cmp | No — standard source definition |
| LuaSnip | No — snippet file placement only |
| nvim-dap | Yes — registers mojo debug adapter if available |
| neotest | Yes — registers mojo test adapter if available |

## Phasing

1. **Phase 1 — Structure**: Update TODO.md, rewrite README installation section
2. **Phase 2 — Documentation**: Write collapsible sections for all tools (docs only)
3. **Phase 3 — Adapters**: Implement adapters where code is needed (nvim-lint, nvim-cmp, etc.)
4. **Phase 4 — Polish**: Ensure consistency, verify all examples work

## Files affected

- `README.md` — full restructure with collapsible sections
- `docs/TODO.md` — add tracking table under P2
- `lua/mojo/adapters/nvim-lint.lua` — future
- `lua/mojo/adapters/nvim-cmp.lua` — future
- `lua/mojo/adapters/blink-cmp.lua` — future
- `lua/mojo/adapters/nvim-dap.lua` — future
- `lua/mojo/adapters/neotest.lua` — future
