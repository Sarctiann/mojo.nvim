# Design: Adopt dmitry-salin/tree-sitter-mojo as the vendored grammar

**Date:** 2026-07-19
**Status:** ✅ Implemented (2026-07-19, PR #11). Vendored grammar later synced to
upstream v1.0.4 (`68bb75b`, 2026-08-18) via `docs/TODO.md` task #11.
**Supersedes grammar source in:** `2026-06-06-self-host-treesitter-parser-design.md`,
`2026-06-06-mojo-grammar-1.0-update-design.md`

## Motivation

The self-hosted grammar in `tree-sitter/mojo/` was forked from
oaustegard/tree-sitter-mojo (itself a tree-sitter-python derivative) and has been
hand-patched to track Mojo language changes (see the two specs above). That
manual porting has fallen behind current Mojo:

- **`fn` was removed from the language.** `def` is now the single function
  keyword. The vendored grammar still parses `fn` (marked `@keyword.error`),
  which no longer reflects valid Mojo.
- **Legacy argument conventions** `inout` / `borrowed` / `owned` were replaced by
  `mut` / `read` / `var` (plus `out`, `deinit`). The vendored grammar still
  accepts the old ones.
- The Python-2 `<>` operator is still accepted.

[dmitry-salin/tree-sitter-mojo](https://github.com/dmitry-salin/tree-sitter-mojo)
is an actively maintained, MIT-licensed grammar that tracks the current
[Mojo language reference](https://mojolang.org/docs/reference/).
It is `def`-only, uses the current argument conventions, and adds broader
coverage (MLIR interop, `comptime` control flow, extensions, `where` clauses,
richer generic/parameter syntax).

## What Changes

### `tree-sitter/mojo/`

- `grammar.js`, `src/parser.c`, `src/scanner.c`, `src/grammar.json`,
  `src/node-types.json`, `src/tree_sitter/*` — replaced with dmitry-salin's
  pre-generated grammar (no `tree-sitter generate` needed).
- `queries/highlights.scm` — replaced with dmitry-salin's Neovim highlight
  queries (`nvim-queries/mojo/highlights.scm`), which target the new node names.
- `queries/tags.scm` — replaced with dmitry-salin's `queries/tags.scm`.
- `package.json` / `tree-sitter.json` / `Cargo.toml` — provenance/authorship
  updated to credit dmitry-salin/tree-sitter-mojo. `file-types` keep `mojo` /
  `🔥`; the build still compiles `src/parser.c` + `src/scanner.c` with `-Isrc`.

### `LICENSE`

Attribution updated: tree-sitter-python base (Max Brunsfeld) + tree-sitter-mojo
grammar (Dmitry Salin, Amaan Qureshi), replacing the oaustegard fork lineage.

### `tests/mojo_samples/*.mojo`

Modernized to current Mojo so they parse cleanly under the new grammar:
`fn` → `def`, `inout`/`borrowed`/`owned` → `mut`/`read`/`var`, removed `<>`.

### `tests/test_queries.lua`

Capture assertions updated to the new node names — `function_definition` →
`function_signature`, `(attribute attribute:)` → `(member_access member:)`,
`Self` is now the `(self)` node — plus struct/trait/decorator checks.

## What Does NOT Change

- `lua/mojo/treesitter.lua` — the self-hosted / auto-rebuild mechanism is
  unchanged. It compiles `src/parser.c` + `src/scanner.c` and copies
  `queries/*` to the runtime path; `:MojoRebuildParser` still works.
- Public plugin API, config, and the `treesitter = { enabled = ... }` option.

## Verification

Against a fresh compile of the new grammar (`cc -shared -fPIC -O2 -o mojo.so
src/parser.c src/scanner.c -Isrc`):

1. Parser compiles and loads (ABI accepted by Neovim's tree-sitter runtime).
2. `queries/highlights.scm` and `queries/tags.scm` compile against the grammar.
3. `tests/test_queries.lua` passes: all four sample files parse with **0 ERROR
   nodes**, and all capture assertions on `highlights.mojo` pass.
4. Current-Mojo constructs verified clean: `def` with `mut`/`read`/`out`/`var`
   and `ref[origin]` args, `raises`/`abi`/`thin` effects, `struct`/`trait`,
   typed `Self`, MLIR types, `comptime if`/`for`, transfer `^`, intersection and
   callable types.
