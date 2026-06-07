# Self-Host Tree-Sitter Mojo Parser

**Date:** 2026-06-06
**Status:** Draft
**TODO Item:** P0 #1 — Re-implement tree-sitter-mojo parser in-repo
**Rule:** AGENTS.md §3 (No Third-Party Mojo Plugin Dependencies)

## Goal

Adopt the tree-sitter-mojo grammar as a self-hosted copy inside this repository.
The plugin no longer references `github.com/oaustegard/tree-sitter-mojo` or any
external parser repo. The grammar source lives in `tree-sitter/mojo/` and
nvim-treesitter is configured to compile from the local copy.

## Files to Add

Grammar files copied from the upstream [tree-sitter-mojo](https://github.com/oaustegard/tree-sitter-mojo)
(MIT-licensed), stripped of bindings, tests, CI, and documentation:

```
tree-sitter/mojo/
├── grammar.js              # Grammar DSL source (for regeneration)
├── src/
│   ├── parser.c            # Generated C parser
│   ├── scanner.c           # External scanner (indent/dedent, strings)
│   ├── grammar.json        # Generated grammar metadata
│   ├── node-types.json     # AST node type definitions
│   └── tree_sitter/        # Tree-sitter runtime headers
│       ├── parser.h
│       ├── array.h
│       └── alloc.h
├── queries/
│   ├── highlights.scm      # Syntax highlighting queries
│   └── tags.scm            # Tag queries
├── package.json            # NPM metadata (nice-to-have)
├── tree-sitter.json        # Tree-sitter metadata
└── Cargo.toml              # Rust crate metadata (nice-to-have)
```

Not copied: `bindings/node/`, `bindings/rust/` (except Cargo.toml),
`bindings/python/`, `test/`, `examples/`, `script/`, `.github/`, `.gitattributes`,
`.npmignore`, `CLAUDE.md`, `README.md`.

## How It Works

nvim-treesitter's parser registration supports an `install_info.location` field
that specifies a subdirectory within the cloned repo. Since mojo.nvim IS a git
repo, `:TSInstall mojo` clones the plugin's own repo from the local filesystem
and compiles the parser from `tree-sitter/mojo/`.

The treesitter.lua module computes the plugin root path dynamically via
`debug.getinfo()` — this works regardless of plugin manager (lazy.nvim, packer,
mini.deps, etc.).

## Files to Modify

### `lua/mojo/config.lua`

- Remove `url` and `revision` from `Mojo-lang.TreesitterInstallInfo` class
- Simplify treesitter defaults: no hardcoded URL, parser config is built by
  `treesitter.lua` at runtime

### `lua/mojo/treesitter.lua`

- Compute the plugin root path dynamically from `debug.getinfo(1, "S").source`
- Set `install_info` to use local path:
  - `url` = plugin root directory
  - `location` = `"tree-sitter/mojo"`
  - `files` = `{"src/parser.c", "src/scanner.c"}`
- Keep the same public API (`M.register()`, `M.setup()`) for backward compat

### `lua/mojo/init.lua`

- No API changes — wiring stays identical

### `README.md`

- Replace "Registers the Mojo parser with `nvim-treesitter`" with note that
  the parser grammar is now self-hosted
- Remove `url` and `revision` from the configuration example
- Update the Treesitter section to reflect self-hosted parser

### `LICENSE`

- Add MIT copyright attribution for the derived tree-sitter-mojo code:
  - Copyright (c) 2016 Max Brunsfeld (tree-sitter-python grammar base)
  - Copyright (c) 2023 HerringtonDarkholme (initial concept)
  - Copyright (c) 2026 Oskar Austegard (maintainer)

### `.gitignore`

- Merge entries from tree-sitter-mojo's `.gitignore`:
  - `Cargo.lock`
  - `package-lock.json`
  - `node_modules`
  - `build`
  - `/target/`

## What Does NOT Change

- Public API of `treesitter.lua` — same `M.register(parser)` and `M.setup(opts)`
- `init.lua` wiring — same conditional requires
- User configuration — `treesitter = { enabled = true }` works as before
- The `:TSInstall mojo` workflow — still the way users install the parser

## Verification

1. `:TSInstall mojo` succeeds and compiles from the local grammar
2. Opening a `.mojo` file shows syntax highlighting via tree-sitter
3. `:TSModuleInfo mojo` shows the parser as installed
4. No references to `oaustegard/tree-sitter-mojo` remain in the codebase
