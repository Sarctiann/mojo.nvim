---
name: update-docs
description: Audit documentation files for accuracy, consistency, and freshness. Covers README, AGENTS, CONTRIBUTING, LICENSE, TODO, specs, plans, posts, and config files. Optionally suggests conceptual improvements.
license: MIT
compatibility: opencode
metadata:
  audience: maintainers
  scope: project
triggers:
  - manual invocation
  - chained from mojo-task-workflow step 5
  - chained from mojo-todo-update after completion
---

# Update Docs

Audit the project's documentation suite for accuracy, cross-document consistency,
and conceptual freshness. Can be invoked manually or chained from
`mojo-task-workflow` / `mojo-todo-update` as a final quality gate.

## Scope

| File | Check |
|------|-------|
| `README.md` | Features match modules, installation still accurate, links valid, demo GIF |
| `AGENTS.md` | Sovereignty rules current, skills table matches `.agents/skills/` |
| `CONTRIBUTING.md` | Project structure matches FS, adapters/skills tables match reality |
| `LICENSE` | Copyright year, attributions |
| `docs/TODO.md` | Completed tasks marked, priorities valid, audit tables current |
| `docs/superpowers/specs/*.md` | Implemented specs vs reality, contradictions |
| `docs/superpowers/plans/*.md` | Completed plans vs still-active |
| `docs/posts/*.md` | Outdated version references |
| `.editorconfig` | Matches current project conventions |
| `.gitignore` | Patterns still relevant, missing ignores |

## Workflow

### 1. Determine scope

If chained from `mojo-task-workflow` or `mojo-todo-update`, the invoking skill
passes a `TARGET_FILES` hint. If invoked manually, ask the user:

- **Quick check** — `README.md`, `AGENTS.md`, `CONTRIBUTING.md`, `docs/TODO.md`
- **Full audit** — all files in scope above
- **Targeted** — specific files the user names

### 2. Per-file investigation and fix

For each file in scope, run the corresponding checklist below. Edits should be
made with native `edit`/`write` tools. After each edit, re-read the file to
confirm correctness.

---

#### README.md checklist

- [ ] `features` section: grep `lua/mojo/*.lua` (excluding adapters/) for module names, cross-reference with README feature blocks. Every module should have a feature entry, and vice versa.
- [ ] adapters listed in README match actual `lua/mojo/adapters/*.lua` files
- [ ] commands documented match actual commands in `lua/mojo/commands.lua` and `init.lua`
- [ ] keymaps documented match actual keymaps
- [ ] installation instructions still work (check lazy.nvim, packer, etc. snippets)
- [ ] **Configuration defaults block** — Read `config.lua` `M.defaults` line by line and compare against the `<details>` configuration block in README. Every key and sub-key in `M.defaults` must appear in the README with the same default value (including nested tables like `debug.keymaps` and `debug.search_for`). Extra entries in the README that are NOT in `M.defaults` must correspond to a `@field` type annotation in `config.lua` (e.g., `adapter` fields are defined in `@class` annotations but not in `M.defaults`). Pay special attention to deeply nested defaults — compare all levels, not just top-level keys.
- [ ] **README emoji convention:** The README is viewed on GitHub and the web. Use standard emojis (🔥, ⚡, ✅, ❌) visible on all platforms. NEVER use Nerd Font unicode icons (󰈸, 󱵮) in README — those require special patched fonts and render as tofu on GitHub. Nerd Font icons are only acceptable in code comments or config defaults inside `config.lua`.
- [ ] setup example still accurate against current `config.lua` defaults
- [ ] `docs/readme-assets/` directory exists with at least one `.gif` file; if empty or missing, suggest creating a demo (see `scripts/make-demo-gif.sh`). Check `docs/readme-assets/*.txt` files to know which features are already covered — each `.txt` is a copy of the `specs.txt` used to generate the corresponding GIF, listing every feature segment included.
- [ ] links anchor to existing sections (`#` references are valid)
- [ ] statusline component names match `lua/mojo/status.lua`

After fixes: if the README is 300+ lines or a section has grown bulky, suggest
splitting into `docs/features.md` or adding screenshots/GIFs.

---

#### AGENTS.md checklist

- [ ] all 7 sovereignty rules present, numbered, and correctly described
- [ ] skills table entries match `.agents/skills/` directory contents
- [ ] skills descriptions match what the skills actually do
- [ ] module conventions section matches `lua/mojo/` structure
- [ ] no stale references to removed files or conventions
- [ ] coding conventions (EmmyLua, namespaces) match actual codebase practice

---

#### CONTRIBUTING.md checklist

- [ ] project structure tree matches actual filesystem (run `ls -d lua/mojo/*/` and `ls lua/mojo/*.lua` to verify)
- [ ] adapters table matches `lua/mojo/adapters/*.lua`
- [ ] skills table matches `.agents/skills/` — compare contents and descriptions
- [ ] testing instructions accurate (command, test file, test pattern)
- [ ] documentation table (README/AGENTS/CONTRIBUTING/specs/plans/TODO) accurate
- [ ] sovereignty rules summary matches AGENTS.md

---

#### LICENSE checklist

- [ ] copyright year is current
- [ ] attributions still accurate (check if forks/repos referenced are still correct)
- [ ] license name and terms match actual intent

---

#### docs/TODO.md checklist

- [ ] every `[done]` task actually completed (check recent commits or module code)
- [ ] audit table statuses (`✅`, `🟡`, `❌`, `⏳`) reflect current implementation
- [ ] VS Code version number in header is still the latest (check `https://github.com/modular/vscode-mojo/blob/main/CHANGELOG.md`)
- [ ] priorities are still appropriate for current plugin state
- [ ] no duplicate or orphaned entries
- [ ] numbering is sequential with no gaps

---

#### Specs checklist (`docs/superpowers/specs/*.md`)

For each spec file:

- [ ] read the spec's decisions and compare with actual module code
- [ ] if feature is fully implemented: add a `**Status:** ✅ Implemented` line at the top
- [ ] if decisions diverged from implementation: add a `**Divergence:**` note explaining what changed and why
- [ ] if two specs contradict each other on the same principle: flag for user resolution
- [ ] if spec is superseded: add `**Superseded by:** <newer-spec-path>` at the top

---

#### Plans checklist (`docs/superpowers/plans/*.md`)

- [ ] check if all tasks in the plan are done (compare with git log and TODO.md)
- [ ] fully completed plans: move to a `docs/superpowers/plans/archived/` subdirectory
- [ ] partially completed plans: flag remaining tasks to user

---

#### Posts checklist (`docs/posts/*.md`)

- [ ] check for version numbers or feature references that are stale
- [ ] if a post references a TODO task that is now done, suggest an update post
- [ ] posts are dated — if oldest post is >30 days old, suggest a new community update

---

#### .editorconfig checklist

- [ ] indent_style and indent_size match actual project conventions (`lua/` is 2 or 4 spaces?)
- [ ] file type patterns cover all project file extensions (`.mojo`, `.🔥`, `.lua`, `.md`, `.sh`)
- [ ] no stale or irrelevant sections

---

#### .gitignore checklist

- [ ] patterns match actual artifacts (test outputs, build dirs, `.pixi`, `.venv`, etc.)
- [ ] missing ignores for new outputs (check `git status --porcelain` for untracked files)
- [ ] no patterns that accidentally ignore important files

### 3. Cross-document consistency

After per-file fixes, verify relationships between documents:

- [ ] **README features → TODO audit tables:** every feature listed in README should have a row in a TODO audit table, and every TODO audit entry with `✅` status should appear in README
- [ ] **Sovereignty rules:** AGENTS.md rules 1-7 match CONTRIBUTING.md summary — same wording, same order
- [ ] **Module structure:** CONTRIBUTING.md `project structure` tree matches actual files — re-run tree check if any modules were added/removed in step 2
- [ ] **Adapters:** CONTRIBUTING.md adapters list matches `lua/mojo/adapters/` directory — update if needed
- [ ] **Skills table:** AGENTS.md skills table matches CONTRIBUTING.md skills table — both should list the same skills with the same trigger descriptions. Both must match `.agents/skills/` directory.

### 4. Suggest improvements

After all fixes and consistency checks, present a summary to the user:

```
## Update-docs report

### Changes made
- README.md: updated feature list, fixed link anchors
- CONTRIBUTING.md: added dap adapter to adapters table
- .editorconfig: added .mojo indent rules

### Remaining suggestions
- README is 340 lines — consider splitting into docs/features.md
- Only 1 demo GIF — a second GIF showing debugging workflow would improve onboarding (check `docs/readme-assets/*.txt` to see which features are already covered)
- Spec 2026-06-06-tool-support-readme-restructure has diverged from implementation (see divergence note)
```

For suggestions, assess:
- README length and readability — would splitting help?
- How many GIFs exist in `docs/readme-assets/` vs. what's shown in README. Check `docs/readme-assets/*.txt` files — each records the feature segments covered by its corresponding GIF. Cross-reference with the README feature list to identify missing visual coverage.
- Is there a feature that lacks any visual demonstration?
- Would a quick reference table or badge section add value?
- Any missing sections (FAQ, troubleshooting, comparison with VS Code)?

### 5. Commit

If any files were changed, commit with a descriptive message:

```
git add <changed-files>
git commit -m "docs: update <file> — <brief description of changes>"
```

If suggestions were made but no files changed, report without committing.

### Chaining from other skills

When `mojo-task-workflow` chains to this skill, it should pass:
```
TARGET_FILES=README.md,AGENTS.md,docs/TODO.md
```

On `mojo-todo-update` chain:
```
TARGET_FILES=docs/TODO.md
```
