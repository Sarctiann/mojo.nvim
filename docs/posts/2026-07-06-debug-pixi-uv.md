🔥 **[mojo.nvim](https://github.com/Sarctiann/mojo.nvim) update**

Debugging now works out of the box on both pixi and uv projects, macOS and Linux. No manual signing required.

**What's new:**

- **DAP debug for uv/pip projects** *(nvim-dap)* — bypasses the Python wrapper, calls native `lldb-dap` directly with pre-init commands for Mojo LLDB plugin and data formatters. Sets `PYTHONHOME`, `MOJO_PYTHON`, and `MOJO_PYTHON_LIBRARY` automatically for the debuggee.
- **Automatic macOS code-signing** — removes quarantine and ad-hoc signs debug adapter binaries so Gatekeeper doesn't block execution. No more `xattr` or `codesign` manually.
- **Native debug for uv/pip** — `:MojoDebugNative` compiles with `--debug-level=full -O0`, re-signs the binary with `get-task-allow` entitlements automatically.

**What we already support:**

- **Syntax highlighting & Treesitter** *(nvim-treesitter)* — self-hosted parser
- **LSP: completions, diagnostics, hover** *(nvim-lspconfig + nvim-cmp / blink.cmp)* — env-aware binary resolution
- **Code formatting** *(conform.nvim)* — `mojo format`
- **Terminal env auto-activation** — pixi/venv activated in new terminals
- **Environment detection** — pixi, venv, manual SDK paths
- **Statusline** *(lualine.nvim)* — env type, SDK version, debugger status
- **Distro adapters** — LazyVim, AstroNvim, NvChad, kickstart.nvim
