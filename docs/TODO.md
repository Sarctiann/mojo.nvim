# mojo.nvim — TODO

> Priorities are based on AGENTS.md sovereignty rules. P0 = blocks sovereignty.

## Workflow Rules

1. **One branch per task** — each item below is done in a separate branch from `main`. No mixing concerns.
2. **No commits without request** — never commit unless I explicitly ask.
3. **Merge then next** — once tested and committed, merge to `main`, then start the next task on a fresh branch.

---

## P1 — Missing Infrastructure

### 1. Add test infrastructure and initial tests

Deferred until core features stabilize and the plugin API solidifies.

### 2. Add CI configuration

Deferred until test infrastructure (P1 #1) is in place.

---

## P2 — Quality & Completeness

### 3. Support popular Neovim tools with README documentation

**Scope:** Ongoing — new tools are added here as they're identified.

| Tool           | Needs adapter? | Needs README? | Notes                               |
| -------------- | -------------- | ------------- | ----------------------------------- |
| lualine.nvim   | No             | Yes (minimal) | Could document Mojo filetype icon   |
| AstroNvim      | No             | Yes           | Docs section showing config format  |
| NvChad         | No             | Yes           | Docs section showing config format  |
| kickstart.nvim | No             | Yes           | Docs section showing minimal config |
| nvim-dap       | Blocked        | Blocked       | No Mojo DAP adapter exists yet      |
| neotest        | Blocked        | Blocked       | `mojo test` not stable yet          |
| nvim-lint      | Blocked        | Blocked       | No Mojo linter binary exists        |