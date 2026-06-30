# Completion Adapters for nvim-cmp and blink.cmp — Design

**Status:** Implemented

## Goal

Provide first-class completion support for Mojo files through nvim-cmp and
blink.cmp, supplementing the LSP with Mojo-specific keywords, builtins, types,
and snippets.

## Architecture

### Core module: `lua/mojo/completion.lua`

Pure data module — no side effects, no `setup()`. Exports structured data that
adapters consume.

**Exports:**

- `M.keywords` — table of Mojo keywords (`fn`, `struct`, `trait`, `var`, `borrowed`, etc.)
- `M.builtins` — table of Mojo built-in functions (`print`, `len`, `range`, `abs`, etc.)
- `M.types` — table of Mojo standard-library types (`Int`, `String`, `List`, `Dict`, etc.)
- `M.snippets` — table of snippet triggers and bodies for common Mojo constructs
- `M.all_items()` — merged iterator returning keywords + builtins + types with
  completion item metadata (label, kind, detail)

All lists are static tables defined at module load time. No filesystem reads,
no LSP calls, no async operations.

### Adapter: `lua/mojo/adapters/nvim-cmp.lua`

Registers a custom cmp source (`mojo`) that provides keyword/builtin/type
completions for `mojo` filetype. Also ensures the `nvim_lsp` source is active
for Mojo buffers.

**Exports:**

- `M.setup(opts)` — calls `cmp.register_source()` and configures
  `cmp.setup.filetype("mojo", { sources = ... })`. Pcall-guarded — returns
  `false` if `cmp` is not installed.

### Adapter: `lua/mojo/adapters/blink.lua`

Configures blink.cmp to enable `lsp` and `path` providers for Mojo filetype,
plus a custom `mojo` provider that serves the same keyword/builtin/type data.

**Exports:**

- `M.setup(opts)` — extends blink's `providers` and `sources` config for
  `mojo` filetype. Pcall-guarded — returns `false` if `blink` is not installed.

### Config extension: `Mojo-lang.CompletionConfig`

Added to `config.lua`:

```lua
--- @class Mojo-lang.CompletionConfig
--- @field enabled boolean|nil
--- @field adapter (fun(opts: Mojo-lang.CompletionConfig): boolean)|nil
```

Default: `{ enabled = true }`.

### Integration in `init.lua`

After existing feature setup blocks, add:

```lua
if opts.completion and opts.completion.enabled ~= false then
  local cmp_opts = opts.completion
  if cmp_opts.adapter then
    cmp_opts.adapter(cmp_opts)
  else
    -- Try blink first, fall back to cmp, silently skip if neither installed
    if not require("mojo.adapters.blink").setup(cmp_opts) then
      require("mojo.adapters.cmp").setup(cmp_opts)
    end
  end
end
```

Actually, per the sovereignty rules, we should NOT auto-detect which completion
framework the user has. The adapter pattern means the user or their distro
picks. So `init.lua` won't auto-call either adapter — the user explicitly
enables one via config:

```lua
require("mojo").setup({
  completion = { enabled = true },  -- uses default adapter (tries both)
})
```

Or with explicit adapter:

```lua
require("mojo").setup({
  completion = {
    adapter = function(opts)
      require("mojo.adapters.blink").setup(opts)
    end,
  },
})
```

### LazyVim adapter update

`adapters/lazyvim.lua` gets a `M.completion(opts)` function returning the
blink or cmp source config for LazyVim users.

## Data Sources

### Keywords

All Mojo keywords from `tree-sitter/mojo/grammar.js` reserved words plus
Mojo-specific tokens:

`fn`, `struct`, `trait`, `var`, `alias`, `comptime`, `borrowed`, `inout`,
`mut`, `read`, `ref`, `out`, `deinit`, `raises`, `thin`, `register_passable`,
`self`, `Self`, `abi`, `constrained`, `fieldwise_init`, `parameter`, `value`,
`always_inline`, `noinline`, `staticmethod`, plus Python-compatible keywords
(`if`, `else`, `elif`, `for`, `while`, `return`, etc.)

### Built-in functions

From the highlights.scm builtin list:

`abort`, `abs`, `all`, `any`, `ascii`, `atof`, `atol`, `bin`, `breakpoint`,
`chr`, `constrained`, `debug_assert`, `divmod`, `enumerate`, `external_call`,
`hash`, `hex`, `input`, `iter`, `len`, `map`, `materialize`, `max`, `min`,
`next`, `oct`, `open`, `ord`, `partition`, `pow`, `print`, `range`, `rebind`,
`rebind_var`, `reflect`, `repr`, `reversed`, `round`, `slice`, `sort`, `swap`,
`zip`

### Standard-library types

`Bool`, `Int`, `Int8`, `Int16`, `Int32`, `Int64`, `UInt8`, `UInt16`, `UInt32`,
`UInt64`, `Float16`, `Float32`, `Float64`, `String`, `List`, `Dict`, `Set`,
`Tuple`, `Option`, `Result`, `Error`, `Regex`, `Path`, `File`, `SIMD`,
`DType`, `Address`, `Pointer`, `Reference`, `Span`, `Vector`

### Snippets

| Trigger | Body |
|---------|------|
| `fn` | `fn ${1:name}($2)$3 -> $4:\n\t$0` |
| `sfn` | `fn ${1:name}($2)$3:\n\t$0` (no return type) |
| `struct` | `struct ${1:Name}:\n\t$0` |
| `trait` | `trait ${1:Name}:\n\t$0` |
| `vdef` | `var ${1:name}: ${2:Type} = ${3:value}` |
| `ldef` | `let ${1:name}: ${2:Type} = ${3:value}` |
| `alias` | `alias ${1:Name} = ${2:Type}` |
| `ifl` | `if ${1:cond}:\n\t$0` |
| `elfl` | `elif ${1:cond}:\n\t$0` |
| `ell` | `else:\n\t$0` |
| `forl` | `for ${1:x} in ${2:range}:\n\t$0` |
| `wl` | `while ${1:cond}:\n\t$0` |
| `tc` | `try:\n\t$0\nexcept ${1:Error}:\n\t${2:pass}` |

## Rules

- Core module (`completion.lua`) has zero side effects — only data and pure functions.
- Adapters are pcall-guarded — missing `cmp` or `blink` is not an error.
- Adapters follow the existing pattern (`adapters/lspconfig.lua`, etc.).
- `completion.lua` data is audited against the same source as `highlights.scm`
  (Mojo stdlib tag `mojo/v1.0.0b1`).