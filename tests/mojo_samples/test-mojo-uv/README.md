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

> **macOS**: The mojo binary installed via uv/PyPI lacks debugger entitlements.
> mojo.nvim automatically handles quarantine removal and re-signing for DAP debug
> (`:MojoDebugDap`). For native debug (`:MojoDebugNative`), if you see
> `Not allowed to attach to process`, re-sign the mojo binary:
>
> ```bash
> # Create entitlements plist
> cat > /tmp/debug.plist << 'EOF'
> <?xml version="1.0" encoding="UTF-8"?>
> <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
> <plist version="1.0"><dict><key>com.apple.security.get-task-allow</key><true/></dict></plist>
> EOF
>
> # Re-sign the mojo binary
> codesign --force --sign - --entitlements /tmp/debug.plist $(which mojo)
> ```
>
> Pixi-installed mojo does not have this issue. Consider using the pixi project
> (`tests/mojo_samples/test-mojo-pixi/`) for the full debugger experience.

Quick start:

```bash
source .venv/bin/activate
nvim main.mojo
:Mojo debug-native   " native LLDB terminal (may need manual re-sign on macOS)
:Mojo debug-dap      " nvim-dap + lldb-dap (automatic macOS signing)
```
