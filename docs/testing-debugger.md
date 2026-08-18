# Manual Debugger Testing Guide

Tests both debug backends (`dbg_ntv`, `dbg_dap`) across pixi and uv projects
using the sample projects in `tests/mojo_samples/`.

## Prerequisites

- Neovim 0.10+
- [mojo.nvim] installed and configured
- Mojo SDK 1.0.0+
- For **pixi**: [`pixi`] installed
- For **uv**: [`uv`] installed
- For **dbg_dap**: [nvim-dap] + DAP binary (`_mojo-lldb-dap` on pixi, `lldb-dap` on uv)

## Test Projects

| Project        | Location                             | Env Manager |
| -------------- | ------------------------------------ | ----------- |
| test-mojo-pixi | `tests/mojo_samples/test-mojo-pixi/` | pixi        |
| test-mojo-uv   | `tests/mojo_samples/test-mojo-uv/`   | uv          |

See each project's `README.md` for per-project setup, run, and debug instructions.

Both contain the same `main.mojo`:

```mojo
def main():
    print("Hello, debug!")

    var counter: Int = 0
    for i in range(5):
        counter += i + 1
        print("Step", i, "counter =", counter)

    print("\nFinal counter:", counter)
```

Expected output:

```
Hello, debug!
Step 0 counter = 1
Step 1 counter = 3
Step 2 counter = 6
Step 3 counter = 10
Step 4 counter = 15

Final counter: 15
```

## Quick Health Check

```
:checkhealth mojo
```

Verify `mojo` and a debug binary are found (`mojo-lldb` / `mojo-lldb-dap` on pixi,
`mojo-lldb` / `lldb-dap` on uv).

---

## 1. pixi Project

### Setup

Official [Mojo quickstart for pixi](https://mojolang.org/install/):

```bash
# Install pixi (if needed)
curl -fsSL https://pixi.sh/install.sh | sh

# Create the project and install mojo
pixi init test-mojo-pixi \
    -c https://conda.modular.com/max/  -c conda-forge
cd test-mojo-pixi
pixi add mojo
pixi shell
```

The project under `tests/mojo_samples/test-mojo-pixi/` is already initialized.
Just run:

```bash
cd tests/mojo_samples/test-mojo-pixi
pixi install
pixi shell
```

### Run (sanity check)

```bash
pixi run mojo run main.mojo
```

### Native Debugger (`dbg_ntv`)

The native debugger opens a terminal buffer running `mojo-lldb` directly.
Keybindings in normal mode: `r` run, `n` next, `s` step, `c` continue,
`v` variables, `b` sync breakpoints, `q`/`<Esc>` close.

```bash
pixi shell -e nvim
```

```
:e main.mojo
" Set a breakpoint at line 6 (counter += i + 1)
:Mojo debug-native
```

| Step | Action | Expected |
|------|--------|----------|
| 1 | `:MojoDebugNative` or `:Mojo debug-native` | Terminal split opens with LLDB. `(lldb)` prompt appears. Build completes without errors. |
| 2 | Press `r` (run) | Program runs, stops at breakpoint (line 6). Output shows `Hello, debug!` then `stop reason = breakpoint`. |
| 3 | Press `c` (continue) | Program continues, hits breakpoint on next loop iteration. |
| 4 | Press `c` repeatedly (5x total) | After loop finishes: `Final counter: 15`. Program exits normally. |
| 5 | Press `v` (frame variable) | Shows local variables (`counter`, `i`). |
| 6 | Press `q` | Terminal closes. |

**Breakpoint sync** (editor ↔ LLDB):

```
:e main.mojo
" Toggle breakpoints at lines 4 and 7
:Mojo debug-native
```

- On start, LLDB outputs `Breakpoint N: where = main::main` at correct lines.
- Press `r` → stops at first breakpoint.
- Press `b` → re-syncs current breakpoints.
- `:w` → breakpoints re-sync automatically.

### DAP Debugger (`dbg_dap`)

Requires [nvim-dap]. Set breakpoints with `<leader>db` / `:DapToggleBreakpoint`.

```bash
pixi shell -e nvim
```

```
:e main.mojo
" Toggle a breakpoint at line 6
<leader>db
:Mojo debug-dap
```

| Step | Action | Expected |
|------|--------|----------|
| 1 | `<leader>db` | Breakpoint sign appears in gutter. |
| 2 | `:MojoDebugDap` or `:Mojo debug-dap` | nvim-dap session starts. Debugger pauses at entry. |
| 3 | `<F5>` (continue) | Runs to your breakpoint at line 6. |
| 4 | `<F5>` again | Next loop iteration. |
| 5 | `<F10>` (step over) | Steps to next line. |
| 6 | Hover over `counter` | Shows variable value (if nvim-dap-ui installed). |
| 7 | `<F5>` until exit | Program completes. |

---

## 2. uv Project

### Setup

Official [Mojo quickstart for uv](https://mojolang.org/install/):

```bash
# Install uv (if needed)
curl -LsSf https://astral.sh/uv/install.sh | sh

# Create the project and install mojo
uv init test-mojo-uv && cd test-mojo-uv
uv venv && source .venv/bin/activate
uv add mojo --prerelease allow
```

> `--prerelease allow` is required only when installing beta (or dev) builds.

The project under `tests/mojo_samples/test-mojo-uv/` is already initialized.
Just run:

```bash
cd tests/mojo_samples/test-mojo-uv
uv sync
source .venv/bin/activate
```

### Run (sanity check)

```bash
mojo run main.mojo
```

### Native Debugger (`dbg_ntv`)

```bash
source .venv/bin/activate
nvim main.mojo
```

```
:Mojo debug-native
```

Same steps as the pixi native flow above.

**macOS caveat**: The mojo binary installed via uv/PyPI lacks debugger
entitlements. If you see `Not allowed to attach to process`:

```bash
# Create entitlements plist
cat > /tmp/debug.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict><key>com.apple.security.get-task-allow</key><true/></dict></plist>
EOF

# Re-sign the mojo binary
codesign --force --sign - --entitlements /tmp/debug.plist $(which mojo)
```

Pixi-installed mojo does not have this issue — prefer the pixi project for
full debugger testing on macOS.

### DAP Debugger (`dbg_dap`)

```bash
source .venv/bin/activate
nvim main.mojo
```

```
:Mojo debug-dap
```

Same steps as the pixi DAP flow above. Same macOS entitlement caveat applies.

---

## Test Matrix

| Project | Backend | Command              | macOS handling     |
| ------- | ------- | -------------------- | ------------------ |
| pixi    | native  | `:Mojo debug-native` | Built-in           |
| pixi    | dap     | `:Mojo debug-dap`    | Built-in           |
| uv      | native  | `:Mojo debug-native` | Automatic signing  |
| uv      | dap     | `:Mojo debug-dap`    | Automatic signing  |

---

## Troubleshooting

### "mojo binary not found"

Activate the correct environment before launching Neovim:

- pixi: `pixi shell` (or `pixi shell -e nvim`)
- uv: `source .venv/bin/activate`

### Debug binary not found

- **pixi**: `mojo-lldb` and `mojo-lldb-dap` are included.
- **uv**: The plugin requires `lldb-dap` or `mojo-lldb-dap` in the venv. uv-installed
  Mojo includes `lldb-dap`. If the binary is missing, reinstall the mojo package:
  `uv add mojo --prerelease allow`.

Binary names are configurable via `debug.search_for` in the plugin config
(default: `lldb-dap`, `_mojo-lldb-dap`, `mojo-lldb-dap`, `mojo-lldb`, `lldb`).

### Build failure

```bash
# pixi
pixi run mojo build main.mojo

# uv
source .venv/bin/activate
mojo build main.mojo
```

### LLDB attach error (macOS)

`Not allowed to attach to process` — see the [uv project README](tests/mojo_samples/test-mojo-uv/README.md)
for the re-sign workaround, or use the pixi project instead.

[mojo.nvim]: https://github.com/Sarctiann/mojo.nvim
[nvim-dap]: https://github.com/mfussenegger/nvim-dap
[`pixi`]: https://pixi.sh
[`uv`]: https://docs.astral.sh/uv
