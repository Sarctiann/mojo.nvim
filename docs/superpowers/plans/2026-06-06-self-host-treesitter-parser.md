# Self-Host Tree-Sitter Parser — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development
> (recommended) or superpowers:executing-plans to implement this plan task-by-task.
> Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the external `github.com/oaustegard/tree-sitter-mojo` parser dependency
with a self-hosted copy inside this repository.

**Architecture:** Grammar source files are copied into `tree-sitter/mojo/`. The
treesitter.lua module computes the plugin root path via `debug.getinfo()` and points
nvim-treesitter's `install_info` to the local subdirectory using the `location` field.
No public API changes — `treesitter = { enabled = true }` works as before.

**Tech Stack:** Lua, Neovim API, nvim-treesitter, C (tree-sitter grammar).

---

### Task 1: Create feature branch

- [ ] **Step 1: Verify we're on main**

Run: `git branch --show-current`
Expected: `main`

- [ ] **Step 2: Create and switch to feature branch**

```bash
git checkout -b feat/self-host-treesitter-parser
```

---

### Task 2: Copy grammar files into tree-sitter/mojo/

**Files:**
- Create: `tree-sitter/mojo/grammar.js`
- Create: `tree-sitter/mojo/src/parser.c`
- Create: `tree-sitter/mojo/src/scanner.c`
- Create: `tree-sitter/mojo/src/grammar.json`
- Create: `tree-sitter/mojo/src/node-types.json`
- Create: `tree-sitter/mojo/src/tree_sitter/parser.h`
- Create: `tree-sitter/mojo/src/tree_sitter/array.h`
- Create: `tree-sitter/mojo/src/tree_sitter/alloc.h`
- Create: `tree-sitter/mojo/queries/highlights.scm`
- Create: `tree-sitter/mojo/queries/tags.scm`
- Create: `tree-sitter/mojo/package.json`
- Create: `tree-sitter/mojo/tree-sitter.json`
- Create: `tree-sitter/mojo/Cargo.toml`

- [ ] **Step 1: Create the target directory structure**

```bash
mkdir -p tree-sitter/mojo/src/tree_sitter tree-sitter/mojo/queries
```

- [ ] **Step 2: Copy grammar source files**

```bash
cp /tmp/tree-sitter-mojo/grammar.js tree-sitter/mojo/grammar.js
cp /tmp/tree-sitter-mojo/src/parser.c tree-sitter/mojo/src/parser.c
cp /tmp/tree-sitter-mojo/src/scanner.c tree-sitter/mojo/src/scanner.c
cp /tmp/tree-sitter-mojo/src/grammar.json tree-sitter/mojo/src/grammar.json
cp /tmp/tree-sitter-mojo/src/node-types.json tree-sitter/mojo/src/node-types.json
cp /tmp/tree-sitter-mojo/src/tree_sitter/parser.h tree-sitter/mojo/src/tree_sitter/parser.h
cp /tmp/tree-sitter-mojo/src/tree_sitter/array.h tree-sitter/mojo/src/tree_sitter/array.h
cp /tmp/tree-sitter-mojo/src/tree_sitter/alloc.h tree-sitter/mojo/src/tree_sitter/alloc.h
cp /tmp/tree-sitter-mojo/queries/highlights.scm tree-sitter/mojo/queries/highlights.scm
cp /tmp/tree-sitter-mojo/queries/tags.scm tree-sitter/mojo/queries/tags.scm
cp /tmp/tree-sitter-mojo/package.json tree-sitter/mojo/package.json
cp /tmp/tree-sitter-mojo/tree-sitter.json tree-sitter/mojo/tree-sitter.json
cp /tmp/tree-sitter-mojo/Cargo.toml tree-sitter/mojo/Cargo.toml
```

- [ ] **Step 3: Strip `"private": true` and reduce package.json to metadata only**

Write to `tree-sitter/mojo/package.json`:

```json
{
  "name": "tree-sitter-mojo",
  "version": "0.25.0",
  "description": "Mojo grammar for tree-sitter (self-hosted in mojo.nvim)",
  "license": "MIT"
}
```

- [ ] **Step 4: Update tree-sitter.json to reflect self-hosted status**

Write to `tree-sitter/mojo/tree-sitter.json`:

```json
{
  "grammars": [
    {
      "name": "mojo",
      "camelcase": "Mojo",
      "scope": "source.mojo",
      "path": ".",
      "file-types": ["mojo", "\U0001f525"],
      "highlights": "queries/highlights.scm",
      "injection-regex": "mojo"
    }
  ],
  "metadata": {
    "version": "0.1.0",
    "license": "MIT",
    "description": "Mojo grammar for tree-sitter (self-hosted in mojo.nvim)",
    "links": {
      "repository": "https://github.com/Sarctiann/mojo.nvim"
    }
  },
  "bindings": {
    "c": true
  }
}
```

---

### Task 3: Merge .gitignore

**Files:**
- Modify: `.gitignore`

- [ ] **Step 1: Add grammar-related entries to .gitignore**

Write to `.gitignore`:

```gitignore
.DS_Store
*/.DS_Store
Cargo.lock
package-lock.json
node_modules
build
/target/
*.log
```

(New entries: `Cargo.lock`, `package-lock.json`, `node_modules`, `build`, `/target/`)

---

### Task 4: Update LICENSE with MIT attribution

**Files:**
- Modify: `LICENSE`

- [ ] **Step 1: Replace LICENSE content**

Write to `LICENSE`:

```text
MIT License

Copyright (c) 2026 Sarctiann

Portions of this software are derived from tree-sitter-mojo:

  - tree-sitter-python grammar base
    Copyright (c) 2016 Max Brunsfeld <maxbrunsfeld@gmail.com>
  - Initial tree-sitter-mojo concept
    Copyright (c) 2023 HerringtonDarkholme
  - tree-sitter-mojo fork
    Copyright (c) 2026 Oskar Austegard

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

### Task 5: Update lua/mojo/config.lua — simplify parser config

**Files:**
- Modify: `lua/mojo/config.lua:9-21`

- [ ] **Step 1: Remove TreesitterInstallInfo class and simplify TreesitterParserConfig**

Replace lines 9-21 (the three class definitions for install info, parser, and treesitter config):

Old code:
```lua
--- @class Mojo-lang.TreesitterInstallInfo
--- @field url string
--- @field revision string
--- @field queries string

--- @class Mojo-lang.TreesitterParserConfig
--- @field install_info Mojo-lang.TreesitterInstallInfo
--- @field filetype string
--- @field tier integer

--- @class Mojo-lang.TreesitterConfig
--- @field enabled boolean|nil
--- @field parser Mojo-lang.TreesitterParserConfig|nil
```

New code:
```lua
--- @class Mojo-lang.TreesitterConfig
--- @field enabled boolean|nil
```

- [ ] **Step 2: Simplify the treesitter defaults**

Replace lines 53-64:

Old code:
```lua
	treesitter = {
		enabled = true,
		parser = {
			install_info = {
				url = "https://github.com/oaustegard/tree-sitter-mojo",
				revision = "v1.0",
				queries = "queries",
			},
			filetype = "mojo",
			tier = 2,
		},
	},
```

New code:
```lua
	treesitter = {
		enabled = true,
	},
```

- [ ] **Step 3: Remove now-invalid type field from Config class**

In the `Mojo-lang.Config` class (lines 34-41), remove the `@field parser Mojo-lang.TreesitterParserConfig|nil` reference. Replace:

Old code:
```lua
--- @class Mojo-lang.Config
--- @field filetype Mojo-lang.FiletypeConfig|nil
--- @field terminal Mojo-lang.TerminalConfig|nil
--- @field treesitter Mojo-lang.TreesitterConfig|nil
--- @field lsp Mojo-lang.LspConfig|nil
--- @field format Mojo-lang.FormatConfig|nil
--- @field debug boolean|nil
--- @field hooks Mojo-lang.Hooks|nil
```

New code (no change needed — `Mojo-lang.TreesitterConfig` still exists, it just lost the `parser` field):

Actually the Config class references `Mojo-lang.TreesitterConfig`, which still exists (we just simplified it). No change needed here.

---

### Task 6: Update lua/mojo/treesitter.lua — use local path

**Files:**
- Modify: `lua/mojo/treesitter.lua`

- [ ] **Step 1: Rewrite treesitter.lua**

Write entire file to `lua/mojo/treesitter.lua`:

```lua
local M = {}

--- @return string
local function plugin_root()
  local source = debug.getinfo(1, "S").source
  local path = source:sub(2)
  return vim.fn.fnamemodify(path, ":h:h:h")
end

--- @return boolean
function M.register()
  local ok, parsers = pcall(require, "nvim-treesitter.parsers")
  if not ok then
    return false
  end

  parsers.mojo = {
    install_info = {
      url = plugin_root(),
      location = "tree-sitter/mojo",
      files = { "src/parser.c", "src/scanner.c" },
    },
    filetype = "mojo",
  }

  return true
end

--- @param opts Mojo-lang.TreesitterConfig|nil
function M.setup(opts)
  opts = opts or {}
  if opts.enabled == false then
    return
  end

  M.register()

  vim.api.nvim_create_autocmd("User", {
    pattern = "TSUpdate",
    callback = function()
      M.register()
    end,
  })
end

return M
```

---

### Task 7: Update init.lua — remove parser config passing

**Files:**
- Modify: `lua/mojo/init.lua:44`

- [ ] **Step 1: Simplify the treesitter setup call**

Old code (line 44):
```lua
    require("mojo.treesitter").setup(opts.treesitter)
```

New code:
```lua
    require("mojo.treesitter").setup(opts.treesitter)
```

(No actual change — `setup()` still accepts the same config shape, we just changed what `opts.treesitter` contains. Verify this is a no-op.)

---

### Task 8: Update README.md

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Update Treesitter section description**

Replace line 32:
```
Registers the Mojo parser with `nvim-treesitter`.
```
with:
```
Registers the self-hosted Mojo parser grammar with `nvim-treesitter`.
The grammar files live in `tree-sitter/mojo/` — no external parser repo required.
```

- [ ] **Step 2: Update the Configuration example in README**

Replace lines 208-219 (the treesitter config block):
```lua
  treesitter = {
    enabled = true,
    parser = {
      install_info = {
        url = "https://github.com/oaustegard/tree-sitter-mojo",
        revision = "v1.0",
        queries = "queries",
      },
      filetype = "mojo",
      tier = 2,
    },
  },
```
with:
```lua
  treesitter = {
    enabled = true,
  },
```

- [ ] **Step 3: Update the Tools section**

Replace line 238:
```
- Treesitter is isolated behind `lua/mojo/treesitter.lua` so the parser backend can be replaced later.
```
with:
```
- Treesitter is isolated behind `lua/mojo/treesitter.lua`. The parser grammar is self-hosted in `tree-sitter/mojo/`.
```

---

### Task 9: Update the design spec to reflect the change

**Files:**
- Modify: `docs/superpowers/specs/2026-06-05-mojo.nvim-design.md`

- [ ] **Step 1: Update the architecture section**

In the design spec, update the Treesitter section to reflect that the parser is now self-hosted. Add a note about the `tree-sitter/mojo/` directory.

---

### Task 10: Verification

- [ ] **Step 1: Search for any remaining references to oaustegard/tree-sitter-mojo**

```bash
rg "oaustegard/tree-sitter-mojo" --type-add 'all:*' -t all
```

Expected: No matches.

- [ ] **Step 2: Verify Lua syntax is valid**

```bash
luacheck lua/mojo/treesitter.lua lua/mojo/config.lua lua/mojo/init.lua
```

(or use `nvim --headless` to load the module)

- [ ] **Step 3: Verify the grammar files are in place**

```bash
ls -la tree-sitter/mojo/src/parser.c tree-sitter/mojo/src/scanner.c tree-sitter/mojo/grammar.js tree-sitter/mojo/queries/highlights.scm
```

Expected: All files exist and are non-empty.

---

### Task 11: Merge to main

- [ ] **Step 1: Stage all changes**

```bash
git add -A
```

- [ ] **Step 2: Commit (only when user requests)**

```bash
git commit -m "feat: self-host tree-sitter-mojo parser in-repo

Replace the external dependency on oaustegard/tree-sitter-mojo with
a self-hosted copy in tree-sitter/mojo/. The parser grammar is now
part of this repository, satisfying AGENTS.md §3 (No Third-Party
Mojo Plugin Dependencies).

- Copy grammar source files (MIT-licensed, with attribution)
- Point nvim-treesitter install_info to local path via location field
- Simplify treesitter config (no more url/revision in user config)
- Merge grammar .gitignore entries
- Update LICENSE with upstream MIT attribution"
```

- [ ] **Step 3: Switch to main and merge**

```bash
git checkout main && git merge feat/self-host-treesitter-parser
```

- [ ] **Step 4: Delete feature branch**

```bash
git branch -d feat/self-host-treesitter-parser
```
