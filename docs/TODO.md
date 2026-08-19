# mojo.nvim — TODO

## VS Code Extension Feature Audit

> Based on `modular-mojotools.vscode-mojo` v26.6.0 (2026-06-24).
> Audited: 2026-06-29.
> Key: ✅ in mojo.nvim | 🟡 partial | ❌ missing | ⏳ blocked (no upstream binary)

### SDK Detection & Status Bar

| VS Code Feature                             | Status | Notes                                                           |
| ------------------------------------------- | ------ | --------------------------------------------------------------- |
| SDK auto-detection (pixi + venv + PATH)     | ✅     | `env/detect.lua` — pixi `.pixi` + `.venv`, filesystem-first     |
| Status bar: SDK version / clickable warning | ✅     | lualine adapter shows env + SDK version; `status.MojoVersion()` |
| LSP status bar (running/stopped/crashed)    | ✅     | `status.lua` — lsp_status() runtime tracking in statusline      |
| Crashed-state distinction (26.6.0)          | ✅     | Crash counter with capped-out state + exponential backoff       |
| Click-to-restart LSP from status bar        | ✅     | Clickable status component with action menu                     |
| `Mojo: Refresh SDK Detection` command       | ✅     | `:MojoRefreshSDK` user command                                  |
| `mojo.sdk.path` override setting            | ✅     | `config.sdk_path` + `$MOJO_SDK_PATH` env var                    |
| `mojo.preferWorkspaceEnv` setting           | 🟡     | sdk_path override bypasses auto-detect; no soft priority        |
| `.derived/` monorepo SDK detection          | ✅     | Added `derived` type to `detect.lua`                            |
| Python extension integration                | ❌     | Doesn't use Python extension at all (good for autonomy)         |
| SDK version display                         | ✅     | `env/version.lua` — `mojo --version` parsing with caching       |

### LSP Features

| VS Code Feature                       | Status | Notes                                                              |
| ------------------------------------- | ------ | ------------------------------------------------------------------ |
| Code completion                       | ✅     | Via nvim-cmp & blink.cmp adapters                                  |
| Hover / doc hints                     | ✅     | LSP provides it, but no keybinding documented                      |
| Signature help (overloaded functions) | ✅     | `<C-S-space>` mapped to `vim.lsp.buf.signature_help`              |
| Go to symbol                          | ✅     | LSP provides it via telescope/trouble                              |
| Outline view                          | ✅     | Documented in README "Outline view" subsection (LSP document symbols via native/telescope/trouble) |
| Code diagnostics                      | ✅     | Via LSP health in trouble/telescope                                |
| Quick fixes / code actions            | ✅     | `<leader>ca` mapped to `vim.lsp.buf.code_action` (n + v modes)    |
| Doc string code blocks LSP            | 🟡     | LSP provides it automatically; no mention in docs                  |
| Filter diagnostics in docstrings      | ✅     | `config.lsp.filter_docstring_diagnostics` option                   |
| `mojo.lsp.includeDirs`                | ✅     | `config.lsp.include_dirs` option                                   |
| Stop LSP server command               | ✅     | `:MojoStopLSP` command                                             |
| Restart extension command             | ✅     | `:MojoRestartLSP` command                                          |
| Inline error display                  | ❌     | No Error Lens equivalent                                           |

### Debugging

| VS Code Feature                    | Status | Notes                                                                                                                       |
| ---------------------------------- | ------ | --------------------------------------------------------------------------------------------------------------------------- |
| LLDB debug adapter                 | ✅     | `mojo-lldb-dap` + `_mojo-lldb-dap` (arm64); also `lldb-dap` from system PATH                                                |
| AOT compile + LLDB attach (26.6.0) | ✅     | AOT via `mojo build --debug-level=full -O0`; re-signed with `get-task-allow` on macOS                                       |
| Debug Mojo File action             | ✅     | `:MojoDebug` (auto), `:MojoDebugNative`, `:MojoDebugDap`                                                                    |
| `mojoFile` (JIT compile on launch) | 🟡     | DAP via `adapters/dap.lua` (compile first, pass `program`); native AOT only                                                 |
| `buildArgs` in debug config        | ✅     | `config.debug.build_args` passed to `mojo build` in DAP + native adapters (task #8)                                        |
| Attach to process                  | ✅     | Via `dap.configurations.mojo` `Attach to Process` entry                                                                     |
| `mojo debug --vscode` support      | 🟡     | DAP + native `mojo-lldb <bin>` cover the case                                                                               |
| Mojo LLDB plugin + visualizers        | ✅     | `find_visualizers()` detects `lib/lldb-visualizers` + `libMojoLLDB.<ext>` in venv (`site-packages/modular/lib`) + pixi (`env_dir/lib`). The Mojo plugin `libMojoLLDB` (the part that visualizes Mojo values) is the primary load: DAP via `?!plugin load` (fatal on failure) and native via `plugin load`. The two `.py` formatter scripts (which pretty-print compiler C++ internals, not Mojo values) are best-effort extras: DAP via `?command script import`, native only when the LLDB build supports Python scripting (`lldb --batch -o 'script pass'` probe). The `mojo-lldb-dap` shell wrapper is bypassed in favor of the real `_mojo-lldb-dap` binary |
| LLDB init/pre-run/post-run cmds    | 🟡     | Source-map set via `initCommands`; pre/post commands not exposed                                                            |
| Editor → LLDB breakpoint sync      | 🟡     | Reads from nvim-dap breakpoint API (or `MojoBreakpoint` fallback); incremental sync + LLDB ID tracking pending   |

### Run

| VS Code Feature              | Status | Notes                                       |
| ---------------------------- | ------ | ------------------------------------------- |
| Run Mojo File                | ✅     | `:MojoRun` opens terminal split             |
| Run in Dedicated Terminal    | ✅     | `:MojoRunDedicated` dedicated buffer per file |
| Right-click / contextual run | ✅     | Covered by `:MojoRun`                       |
| Command palette run actions  | ✅     | Covered by `:MojoRun` / `:MojoRunDedicated` |

### Formatting

| VS Code Feature          | Status | Notes                                           |
| ------------------------ | ------ | ----------------------------------------------- |
| Format Document          | ✅     | Via conform.nvim adapter `adapters/conform.lua` |
| Format on Save           | ✅     | Standard conform.nvim feature, documented       |
| Default formatter config | ✅     | In README                                       |

### Other

| VS Code Feature              | Status | Notes                             |
| ---------------------------- | ------ | --------------------------------- |
| Syntax highlighting          | ✅     | Via treesitter + filetype         |
| `comptime` keyword support   | ✅     | Treesitter parses it              |
| Function modifier syntax     | ✅     | Treesitter handles `var`          |
| Restart extension command    | ✅     | `:MojoRestartLSP` command         |
| Terminal env auto-activation | ✅     | `terminal.lua` — TermOpen autocmd |

---

## Mojo Language Changelog Audit

> Based on Mojo v1.0.0 (2026-08-11). Investigated: 2026-08-18.
> Key: ✅ handled | 🟡 partial | ❌ gap | ⏳ blocked

### Keywords & Syntax

| Mojo Change                                    | Status | Notes                                                        |
| ---------------------------------------------- | ------ | ------------------------------------------------------------ |
| `fn` keyword now a compilation error           | ✅     | Removed from completion/snippets; grammar is `def`-only      |
| `read` → `imm` argument/capture convention     | ✅     | `imm` in completion keywords; grammar synced to v1.0.4       |
| `lambda` expressions                           | ✅     | Grammar v1.0.4 parses `lambda (x: Int) -> Int` / captures     |
| `var` required on all declarations             | 🟡     | `var` in completion; snippets don't enforce it               |
| `__del__` → `__deinit__` destructor            | ✅     | `dinit` snippet emits `def __deinit__(self)`                 |
| Trailing `where` + `where (cond, "msg")`       | 🟡     | `where` in grammar; message form is new                       |
| `**kwargs` → `var **kwargs`                    | 🟡     | No snippet emits `**kwargs`                                  |
| `import .module` removed                       | ✅     | Grammar v1.0.4 removed `relative_aliased_import`             |
| Escaped-identifier imports                      | ✅     | Grammar v1.0.4 adds `dotted_escaped_identifier`              |
| Param-list `where` no longer supported         | ✅     | Already removed in grammar                                    |
| `@explicit_destroy` requires error string      | 🟡     | Grammar parses generic decorators; semantics not enforced    |
| Reserved words banned as free-function names   | 🟡     | Compiler-enforced; no grammar impact                          |

### Tooling

| Mojo Change                                        | Status | Notes                                                               |
| -------------------------------------------------- | ------ | ------------------------------------------------------------------- |
| `mojo package` → `mojo precompile`                 | 🟡     | No references in codebase; terminal cmds fine                       |
| `.mojopkg` deprecated → `.mojoc`                   | ✅     | `.mojoc` added to filetype detection; `.mojo` covers JIT files |
| `mojo --print-cache-location`                      | ✅     | `:MojoCacheLocation` user command (Task #7)                         |
| `mojo --clear-cache`                               | ✅     | `:MojoClearCache` user command with confirmation (Task #7)          |
| LSP: docstring diagnostics off by default          | 🟡     | Server behavior; could expose `-check-docstrings` option           |
| LSP: no folding-range support                      | ✅     | Neovim falls back to indentation folding                            |
| `--fp-mode`, `--lld-path` CLI flags                | 🟡     | No plugin exposure; debug/native flows unaffected                   |
| `mojo build --emit shared-lib`                     | 🟡     | Not exposed; out of scope for now                                   |

### Stdlib

| Mojo Change                                    | Status | Notes                                            |
| ---------------------------------------------- | ------ | ------------------------------------------------ |
| `UnsafePointer` → `Pointer` unification        | ✅     | Completion lists `Pointer` + `Mut/Imm/OptionalPointer` |
| `InlineArray` → `Array`                        | ✅     | `Array` added; `InlineArray` removed (Task #12)   |
| `StringSlice` → `StringSpan`                   | ✅     | `StringSpan` added; `StringSlice` removed (Task #12) |
| `ImplicitlyDestructible` → `Deinitable`        | ✅     | `Deinitable` added (Task #12)                     |
| `SIMDSize` → `SIMDLength`; `size` → `length`   | ✅     | `SIMDLength` added; no `SIMDSize` in completion   |
| `OwnedKwargsDict` → `StringDict`               | ✅     | `StringDict` added (Task #12)                     |
| `Variant.take` → `unwrap`; `steal_data` → `unsafe_take_allocation` | 🟡 | Method-level; not applicable to type list |
| List expressions construct `Array` by default  | 🟡     | Completion/snippets unaffected                    |
| `Int` alias for `Scalar[DType.int]`            | 🟡     | `Int` already in completion types                 |
| `range()` dtype-parameterized family           | 🟡     | `range` already in builtins                       |

---

## P1 — Language Sync

### ~~1. Remove `fn` keyword from completion source & snippets~~ [done]

**Created:** 2026-06-29 | **Updated:** 2026-06-30
**Sovereignty:** Rule 1 (Centralization) — completion must reflect the current language.
**Why:** Mojo v1.0.0b2 made `fn` a compilation error (was a warning). `def` is now the single function-declaration keyword.

**Scope:**

- Remove `"fn"` from `completion.lua` keywords list ✅
- Change `fn` snippet trigger to `def` with `def` body ✅
- Change `sfn` snippet trigger to `sdef` with `def` body ✅

### ~~2. Remove `register_passable` keyword from completion source~~ [done]

**Created:** 2026-06-29 | **Updated:** 2026-06-30
**Sovereignty:** Rule 1 (Centralization) — completion must reflect the current language.
**Why:** Mojo v1.0.0b2 removed the `register_passable` effect keyword. Register passability is now computed implicitly.

**Scope:**

- Remove `"register_passable"` from `completion.lua` keywords list ✅
- Update design spec `2026-06-06-mojo-grammar-1.0-update-design.md` to note the removal ✅

### ~~3. Add `.mojoc` file extension to filetype detection~~ [done]

**Created:** 2026-06-29 | **Updated:** 2026-06-30
**Sovereignty:** Rule 1 (Centralization) — all Mojo file types must be recognized.
**Why:** Mojo v1.0.0b2 renamed `mojo package` → `mojo precompile` and deprecated `.mojopkg` in favor of `.mojoc`.

**Scope:**

- Add `.mojoc` extension mapping to `mojo` filetype in `filetype.lua` ✅

### ~~11. Sync vendored tree-sitter grammar with upstream dmitry-salin v1.0.4~~ [done]

**Created:** 2026-08-18 | **Updated:** 2026-08-18
**Sovereignty:** Rule 3 (No Third-Party) — self-hosted grammar must track upstream Mojo.
**Why:** The vendored grammar in `tree-sitter/mojo/` is pinned at upstream commit `a4df8f9` (2026-07-19). Upstream has since released v1.0.4 (2026-08-18) covering Mojo 1.0 syntax: `read`→`imm`, `lambda` expressions, trailing `where` on type expressions, import overhaul (`relative_aliased_import` removed, `dotted_escaped_identifier` added), MLIR node renames (`mlir_*_special_character`→`mlir_*_punctuation`), plus a highlights rework (f-string interpolation, variadic/walrus, symbols/operators).

**Scope:**

- Replace `grammar.js`, `src/parser.c`, `src/scanner.c`, `src/grammar.json`, `src/node-types.json`, `src/tree_sitter/*` with upstream v1.0.4 (`68bb75b`) ✅
- Replace `queries/highlights.scm` with upstream `nvim-queries/mojo/highlights.scm` ✅
- Update `package.json` / `tree-sitter.json` / `Cargo.toml` provenance + version to 1.0.4 ✅
- Audit `queries/tags.scm` against new node names (upstream dropped tags.scm) ✅ (kept, all node/field names still valid)
- Modernize `tests/mojo_samples/*.mojo` (e.g. `read` → `imm`, `lambda x` → parenthesized lambda) ✅
- Update `tests/test_queries.lua` capture assertions for renamed nodes ✅
- Verify with `tests/test_queries.lua` (0 ERROR nodes, all captures pass) ✅

### ~~12. Re-audit completion source for Mojo v1.0.0 stdlib + keywords~~ [done]

**Created:** 2026-08-18 | **Updated:** 2026-08-18
**Sovereignty:** Rule 1 (Centralization) — completion must reflect the current language.
**Why:** Mojo 1.0.0 renamed `read`→`imm`, `InlineArray`→`Array`, `StringSlice`→`StringSpan`, `ImplicitlyDestructible`→`Deinitable`, `SIMDSize`→`SIMDLength`, `UnsafePointer`→`Pointer`, `OwnedKwargsDict`→`StringDict`. `completion.lua` still lists the old names and misses new ones.

**Scope:**

- Replace `read` with `imm` in `M.keywords` ✅
- Update `M.types`: add `Array`, `StringSpan`, `Deinitable`, `SIMDLength`, `StringDict`, `MutPointer`, `ImmPointer`, `OptionalPointer`; remove/deprecate `StringSlice`, `InlineArray`, `UnsafePointer` aliases ✅
- Update `M.builtins` for 1.0 renames where applicable ✅ (no builtin renames applicable)
- Update snippets: destructor `__deinit__`, `**kwargs` → `var **kwargs`, SIMD `length=` param ✅ (`dinit` snippet added; no kwargs/SIMD snippets existed)
- Update audit comment to reference Mojo v1.0.0 ✅

---

## P2 — Quality & Completeness

### ~~4. Re-audit completion builtins for Mojo v1.0.0b2 stdlib~~ [done]

**Created:** 2026-06-29 | **Updated:** 2026-06-30
**Sovereignty:** Rule 1 (Centralization) — completion builtins must match the current stdlib.
**Why:** The completion builtins were last audited against v1.0.0b1. v1.0.0b2 added new stdlib APIs (`BinaryHeap`, `WeakPointer`, `Allocation`), renamed others (`Movable.__init__` `take` → `move`), and removed deprecated APIs (`ExternalOrigin` → `UntrackedOrigin`).

**Scope:**

- Compare current `completion.lua` builtins/attrs/types lists against v1.0.0b2 stdlib ✅
- Add new types: `BinaryHeap`, `WeakPointer`, `Allocation`, `ThinAllocation`, `Layout`, `UntrackedOrigin`, `UnsafeAnyOrigin`, `CompletionFlag`, `DevicePointer`, `DeviceContextList`, `ReflectedFn` ✅
- Remove/deprecate: `ExternalOrigin` → `UntrackedOrigin`, `AnyOrigin` → `UnsafeAnyOrigin` ✅
- Update audit comment in `completion.lua` to reference v1.0.0b2 ✅

### ~~5. Update treesitter grammar for Mojo v1.0.0b2 syntax changes~~ [done]

**Created:** 2026-06-29 | **Updated:** 2026-06-30
**Sovereignty:** Rule 3 (No Third-Party) — treesitter grammar bundled in the repo.
**Why:** Mojo v1.0.0b2 changed several syntax rules: `fn` is an error, `register_passable` removed, trailing `where` on struct/comptime declarations added, `@unavailable` decorator added, param-`where` deprecated.

**Scope:**

- Deprecate `fn` in grammar (keep parsing for legacy code, mark as `@keyword.error` in highlights) ✅
- Remove `register_passable` from effect keywords ✅ (already absent from grammar)
- Add trailing `where` clause support to struct and comptime alias declarations ✅
- Add `@unavailable` decorator parsing ✅ (generic decorator rule already parses it; added to highlights.scm)
- Mark param-list `where` as `@keyword.deprecated` in highlights ✅
- Not blocked — grammar is self-hosted in `tree-sitter/mojo/grammar.js`, updated and regenerated

### 6. Lualine icon documentation [done]

**Created:** 2026-06-29 | **Updated:** 2026-06-30
**Sovereignty:** Rule 7 (One Breaking-Change Point) — docs must reflect current state.
**Why:** lualine adapter shows SDK version + env name in statusline; icon and config options need README documentation.

**Scope:**

- Document lualine icon configuration options in README ✅
- Add example lualine config snippet showing SDK version + env name display ✅

### ~~7. Expose `mojo --print-cache-location` and `mojo --clear-cache` as user commands~~ [done]

**Created:** 2026-06-30 | **Updated:** 2026-08-18
**Sovereignty:** Rule 1 (Centralization) — all useful Mojo CLI commands should be accessible.
**Why:** Mojo v1.0.0b2 added `mojo --print-cache-location` and `mojo --clear-cache` CLI options. These are not exposed as Neovim user commands.

**Scope:**

- Add `:MojoCacheLocation` command that echoes the cache path in a notification ✅
- Add `:MojoClearCache` command with confirmation dialog ✅
- Add to `:Mojo menu` floating window ✅ (extended menu to map keys 1..N for all actions)

### ~~8. Expose `buildArgs` in debug launch configuration~~ [done]

**Created:** 2026-06-30 | **Updated:** 2026-08-18
**Sovereignty:** Rule 2 (Modular → Official Replacement Path) — debug module API.
**Why:** The VS Code extension supports `buildArgs` for passing extra flags to `mojo build` during debug compilation. mojo.nvim's DAP adapter doesn't expose this.

**Scope:**

- Add `build_args` field to `config.debug` options ✅ (`Mojo-lang.DebugConfig.build_args`)
- Pass through to `mojo build` command in DAP adapter ✅ (`vim.list_extend` in `build_mojo_file`)
- Document in README debug configuration section ✅

### ~~9. Load Mojo LLDB plugin + data formatters for debugging~~ [done]

**Created:** 2026-06-30 | **Updated:** 2026-08-18
**Sovereignty:** Rule 5 (Zero-Bundle) — discover formatters, don't bundle them.
**Why:** The Mojo SDK ships the `libMojoLLDB` plugin (which visualizes Mojo values in LLDB) plus `lldbDataFormatters.py` and `mlirDataFormatters.py` (which pretty-print compiler C++ internals). Our DAP and native debug adapters should load them.

**Scope:**

- Detect the plugin + formatter scripts in pixi/venv `lib/` directories alongside the SDK ✅ (`find_visualizers()` — searches `env_dir/lib` and `site-packages/modular/lib` for `libMojoLLDB.<ext>` + `lldb-visualizers/`)
- Load the Mojo plugin as the primary concern in both adapters ✅ (DAP via `?!plugin load` — fatal on failure — using the real `_mojo-lldb-dap` binary, bypassing the `mojo-lldb-dap` shell wrapper; native via `plugin load` once the `(lldb)` prompt appears)
- Import the two `.py` formatters as best-effort extras ✅ (DAP via `?command script import`; native only when the LLDB build supports Python scripting via the `lldb --batch -o 'script pass'` probe)
- Verified end-to-end ✅ (covered by `tests/test_dap.lua` unit tests for detection, `?!plugin load`/`?command script import` prefixes, and native `_on_prompt` plugin-first loading)

### ~~10. Document outline view usage in README~~ [done]

**Created:** 2026-06-30 | **Updated:** 2026-08-18
**Sovereignty:** Rule 7 (One Breaking-Change Point) — docs must reflect capabilities.
**Why:** The LSP provides document symbols for an outline view, but there's no documentation on how to access it.

**Scope:**

- Add README section showing how to use `:Telescope lsp_document_symbols` or trouble for outline ✅ (README "Outline view" subsection + keybinding examples)
- Mention keybindings for symbol navigation ✅ (`<leader>so` examples for native/telescope/trouble)
