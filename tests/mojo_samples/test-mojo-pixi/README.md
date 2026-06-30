# test-mojo-pixi

Sample Mojo project managed with [pixi](https://pixi.sh). Used for manual
debugger testing of [mojo.nvim](https://github.com/Sarctiann/mojo.nvim).

## Setup (from scratch)

Follows the official [Mojo quickstart for pixi](https://mojolang.org/install/):

```bash
# 1. Install pixi (if needed)
curl -fsSL https://pixi.sh/install.sh | sh

# 2. Create the project
pixi init test-mojo-pixi \
    -c https://conda.modular.com/max/  -c conda-forge
cd test-mojo-pixi

# 3. Add the mojo package
pixi add mojo

# 4. Enter the project environment
pixi shell
```

This project is already initialized - just run `pixi install` and `pixi shell`.

## Run

```bash
pixi run mojo run main.mojo
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

Quick start:

```bash
pixi shell -e nvim
:Mojo debug-native   " native LLDB terminal
:Mojo debug-dap      " nvim-dap + mojo-lldb-dap
```
