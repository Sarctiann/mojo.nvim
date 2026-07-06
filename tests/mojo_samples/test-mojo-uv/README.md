# test-mojo-uv

Sample Mojo project managed with [uv](https://docs.astral.sh/uv). Used for manual
debugger testing of [mojo.nvim](https://github.com/Sarctiann/mojo.nvim).

## Setup (from scratch)

Follows the official [Mojo quickstart for uv](https://mojolang.org/install/):

```bash
# 1. Install uv (if needed)
curl -LsSf https://astral.sh/uv/install.sh | sh

# 2. Create the project
uv init test-mojo-uv && cd test-mojo-uv

# 3. Create virtual environment
uv venv && source .venv/bin/activate

# 4. Add the mojo package (--prerelease allow required for beta builds)
uv add mojo --prerelease allow
```

> The `--prerelease allow` flag is required only when installing beta (or dev) builds.

This project is already initialized - just run `uv sync` and `source .venv/bin/activate`.

## Run

```bash
source .venv/bin/activate
mojo run main.mojo
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

## Debug

See the [debugger testing guide](../../../docs/testing-debugger.md) for the full
step-by-step manual test procedure covering both native (`dbg_ntv`) and DAP
(`dbg_dap`) backends.

mojo.nvim automatically handles macOS quarantine removal and code-signing.
Native and DAP debugging work out of the box on both macOS and Linux.

Quick start:

```bash
source .venv/bin/activate
nvim main.mojo
:Mojo debug-native   " native LLDB terminal
:Mojo debug-dap      " nvim-dap + lldb-dap (automatic macOS signing)
```
