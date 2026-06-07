# Design: Update Self-Hosted Tree-Sitter Grammar for Mojo 1.0

**Date:** 2026-06-07
**Status:** Implemented and verified
**Branch:** `feat/self-host-treesitter-parser`

## Summary

Update the self-hosted tree-sitter-mojo grammar (`tree-sitter/mojo/`) to reflect
Mojo language changes up to v1.0.0b1. The grammar was forked from
oaustegard/tree-sitter-mojo and hasn't tracked recent Mojo evolution.

## What Changes

### grammar.js (renamed from grammar.cjs)

| Change | Detail | Line |
|--------|--------|------|
| **Reserve `struct`** | Add to `reserved` block | ~120 |
| **Reserve `trait`** | Add to `reserved` block | ~120 |
| **Reserve `Self`** | Add to `reserved` block | ~120 |
| **Reserve `thin`, `abi`, `register_passable`** | Add to `reserved` block | ~120 |
| **Remove `owned`** | Remove from `argument_convention` | 722 |
| **Add `capture_list`** | New `{mut a, b, read}` syntax after function signature | ~440 |
| **Restructure `function_definition`** | Single `optional(seq(repeat(effects), optional(choice(raises+return, return+raises))))` | 444 |
| **Removed `_function_effects`** | Effects inline via `repeat(choice('thin', seq('abi', '(' '"C"', ')'), 'register_passable'))` | — |
| ~Add `function_pointer_type`~ | **REMOVED** — caused cascading GLR conflicts with every type operator (union, constrained, member). Rare in real Mojo code; users can wrap in `alias` as workaround. Revisit in future iteration. | — |

### scanner.c

No changes needed. `t` prefix already sets the `Format` flag (line 306-308),
making T-strings (`t"text {expr}"`) work as interpolated strings.

### highlights.scm

| Change | Reason |
|--------|--------|
| Remove `"owned"` from `@keyword.modifier` | Removed in Mojo 1.0 |
| Remove `"nonmaterializable"` from decorator list | Removed from docs |
| Remove `"trait_downcast"`, `"trait_downcast_var"` from builtins | Removed in 1.0 |
| Add `"register_passable"` to decorator list (keep, still valid) | Clarify status |
| Add `@keyword` for `thin`, `register_passable` | New effects |
| Add `@keyword` for capture list tokens (`{`, `}`) | New syntax |
| Add `"raises"` bare keyword `@keyword` | Bare raises (no error type) highlighted |
| Remove `(capture_item "ref" @keyword.modifier)` | Impossible pattern — `"ref"` inside `capture_item` conflicts with non-reserved identifier match. `ref` is already captured by the `[...] @keyword.modifier` set above. |

### tags.scm

No changes needed.

## What Does NOT Change

- `fn` kept as alias for `def` (deprecated but not removed upstream)
- `borrowed`, `inout` kept in `argument_convention` (still accepted by compiler)
- `treesitter.lua` — self-hosted parser with auto-rebuild on stale grammar; `:MojoRebuildParser` command
- Indent/dedent logic in scanner — unaffected
- F-string handling — already correct

## Grammar Rule Details

### Capture list

```
capture_list: $ => seq(
  '{',
  commaSep1($.capture_item),
  optional(','),
  '}',
)

capture_item: $ => choice(
  seq('mut', $.identifier),     // mutable by-reference capture
  seq($.identifier, '^'),       // move capture (transfer)
  seq('ref', $.identifier),     // parametric ref capture
  $.identifier,                 // immutable by-reference capture
)

### Updated function_definition

```cjs
function_definition: $ => seq(
  optional('async'),
  choice('def', 'fn'),
  field('name', $.identifier),
  field('type_parameters', optional($.type_parameter)),
  field('parameters', $.parameters),
  // effects, raises, return type in any order
  optional(seq(
    repeat(choice('thin', seq('abi', '(', '"C"', ')'), 'register_passable')),
    optional(choice(
      seq(
        choice('raises', $.raises_clause),
        repeat(choice('thin', seq('abi', '(', '"C"', ')'), 'register_passable')),
        optional(seq('->', field('return_type', $.type))),
      ),
      seq(
        '->', field('return_type', $.type),
        optional(choice('raises', $.raises_clause)),
      ),
    )),
  )),
  optional($.capture_list),
  ':',
  field('body', $._suite),
),
```

This unified structure supports all valid Mojo 1.0 orderings:
- `raises [type] [effects] [-> type]`
- `effects [raises [type]] [-> type]`
- `effects [-> type [raises]]`
- `effects [-> type]`
- `-> type [raises]`

Effects (`thin`, `abi("C")`, `register_passable`) appear via `repeat()` in any supported
position, and the reserved keyword mechanism prevents them from matching `identifier`.

### (Removed) Function pointer type

Was removed from scope due to cascading GLR conflicts with every type operator
(union, constrained, member). Rare in real Mojo code; users can work around by
wrapping in `alias`. Revisit in future iteration if needed.

### Updated argument_convention

```cjs
argument_convention: $ => choice(
  'borrowed', 'inout', 'mut', 'read',
  'out', 'var', 'deinit',
  seq('ref', optional(seq('[', field('lifetime', $.identifier), ']'))),
),
```

### Updated raises_clause

```cjs
raises_clause: $ => seq(
  'raises',
  field('error_type', $.type),
),
```

`$.type` is now required (not optional). Bare `"raises"` is matched inline as a
separate token in the `function_definition` choice.

### Conflict entries

Added to `conflicts` block:
- `[$.raises_clause, $.constrained_type]` — `raises` token is ambiguous with
  type constraints when followed by `[`
- `[$.capture_item, $.primary_expression]` — `{mut x}` captures could be parsed
  as a set literal

### Reserved word mechanism

Tree-sitter's reserved word system works by remapping `sym_identifier` tokens to
keyword tokens when they appear in lexer states that have a non-empty reserved
word set. The mechanism requires:
1. The word listed in the grammar's `reserved` block (all keywords are in `global` set)
2. The parser state having a non-zero `reserved_word_set_id` in its `TSLexerMode`

IMPORTANT: `reserved` keywords do NOT prevent matching via `$.identifier` — they
only remap the token type at the lexer level. This means `raised thin` (bare raises
followed by effect `thin`) parses correctly because `thin` is recognized as
`anon_sym_thin` instead of `identifier`. Without the reserved mechanism, `thin`
would match `$.identifier` and be consumed as the error type of `raises`.

See `lua/mojo/treesitter.lua` for Neovim's auto-install logic.

## Dependencies

- `tree-sitter-cli` — to regenerate `parser.c` from `grammar.js`

## Verification

1. Run `tree-sitter generate` in `tree-sitter/mojo/` — should produce no errors
2. Compile parser: `cc -shared -fPIC -o parser/mojo.so src/parser.c src/scanner.c -Isrc -O2`
3. Open a `.mojo` file in Neovim — parser should compile and highlight correctly
4. Test specific Mojo 1.0 constructs with `tree-sitter parse FILE`:
   - All effect/raises/return orderings
   - Capture lists (`{mut x, y^}`)
   - Typed raises (`raises Error`)
   - `struct`/`trait` definitions
   - T-strings (`t"hello {name}"`)
   - Reserved keywords in identifier positions (should produce ERROR)

### treesitter.lua auto-rebuild

The plugin no longer relies on `TSInstall mojo`. Instead, `treesitter.lua` manages
the parser lifecycle directly:

- On `FileType mojo`, compares `grammar.js` mtime vs `mojo.so` mtime
- If the grammar is newer, automatically recompiles the parser and copies queries,
  then runs `:edit!` to reload the buffer
- `:MojoRebuildParser` command available for manual rebuilds
- The `compile_parser()` function runs `cc -shared -fPIC -O2` synchronously
  and copies query files from `tree-sitter/mojo/queries/` to the Neovim runtime path

### highlights.scm — Impossible pattern fix

`(capture_item "ref" @keyword.modifier)` produced an "Impossible pattern" error
because `ref` is not a reserved keyword in the grammar, so the tree-sitter query
compiler could not guarantee the anonymous `"ref"` token would always appear as a
direct child of `capture_item`. Since `ref` is already captured by the
`[...] @keyword.modifier` set (lines 181-189), the `(capture_item ...)` node pattern
was removed entirely. Only `(capture_list "{" "}")` punctuation highlighting remains.
