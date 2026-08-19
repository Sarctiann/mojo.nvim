local env = require("mojo.env")

local gitignore_notified = false

local M = {}

-- Re-sign with get-task-allow on macOS so debugserver can attach.
-- This mirrors what Xcode does for Debug builds.
local function sign_for_debug(bin)
	if vim.fn.has("mac") ~= 1 then
		return
	end
	if vim.fn.executable("codesign") ~= 1 then
		return
	end
	local tmp = vim.fn.tempname() .. ".plist"
	local f = io.open(tmp, "w")
	if not f then
		return
	end
	f:write('<?xml version="1.0" encoding="UTF-8"?>\n')
	f:write('<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">\n')
	f:write('<plist version="1.0"><dict><key>com.apple.security.get-task-allow</key><true/></dict></plist>\n')
	f:close()
	vim.fn.system({ "codesign", "--force", "--sign", "-", "--entitlements", tmp, bin })
	os.remove(tmp)
end

local function ensure_macos_executable(bin)
	if vim.fn.has("mac") ~= 1 then
		return
	end
	if not bin or bin:sub(1, 1) ~= "/" then
		return
	end
	vim.fn.system({ "xattr", "-d", "com.apple.quarantine", bin })
	if vim.fn.executable("codesign") == 1 then
		vim.fn.system({ "codesign", "--force", "--sign", "-", bin })
	end
end

local function find_package_root(bin_dir)
	local venv_root = vim.fs.dirname(bin_dir)
	local lib_dir = vim.fs.joinpath(venv_root, "lib")
	local stat = vim.uv.fs_stat(lib_dir)
	if not stat or stat.type ~= "directory" then
		return nil
	end
	for name, entry_type in vim.fs.dir(lib_dir) do
		if entry_type == "directory" and name:match("^python3%.") then
			local candidate = vim.fs.joinpath(lib_dir, name, "site-packages", "modular")
			local cand_stat = vim.uv.fs_stat(candidate)
			if cand_stat and cand_stat.type == "directory" then
				return candidate
			end
		end
	end
	return nil
end

--- Locate the Mojo LLDB visualizers and plugin for the active environment.
--- Searches both the venv-style `site-packages/modular/lib` and the env `lib` dir.
--- @param detected Mojo-lang.DetectedEnv|nil
--- @return string|nil, string|nil  (visualizers_dir, plugin_path)
local function find_visualizers(detected)
	if not detected then
		return nil, nil
	end
	local ext = vim.fn.has("mac") == 1 and "dylib" or "so"
	local candidates = {}
	if detected.bin_dir then
		local pkg_root = find_package_root(detected.bin_dir)
		if pkg_root then
			table.insert(candidates, vim.fs.joinpath(pkg_root, "lib"))
		end
	end
	if detected.env_dir then
		table.insert(candidates, vim.fs.joinpath(detected.env_dir, "lib"))
	end
	for _, lib in ipairs(candidates) do
		local vis = vim.fs.joinpath(lib, "lldb-visualizers")
		if vim.uv.fs_stat(vis) then
			local plugin = vim.fs.joinpath(lib, "libMojoLLDB." .. ext)
			return vis, (vim.uv.fs_stat(plugin) and plugin or nil)
		end
	end
	return nil, nil
end

--- Locate the native `lldb-dap` binary to use as the DAP adapter command.
--- @param detected Mojo-lang.DetectedEnv|nil
--- @return string|nil
local function find_lldb_dap(detected)
	if not detected then
		return nil
	end
	local roots = {}
	if detected.bin_dir then
		local pkg_root = find_package_root(detected.bin_dir)
		if pkg_root then
			table.insert(roots, vim.fs.joinpath(pkg_root, "bin"))
		end
	end
	if detected.env_dir then
		table.insert(roots, vim.fs.joinpath(detected.env_dir, "bin"))
	end
	-- Prefer a plain `lldb-dap`, then Mojo's real `_mojo-lldb-dap` binary. Skip
	-- the `mojo-lldb-dap` shell wrapper: it hard-codes `$CONDA_PREFIX/bin/_mojo-
	-- lldb-dap` and breaks when CONDA_PREFIX is unset. A uv/PyPI `lldb-dap` is
	-- itself a Python shim that injects `?!plugin load` / `?command script
	-- import` and crashes if the plugin/visualizers env vars are unset, so we
	-- must set both env vars whenever either is available.
	for _, bin_dir in ipairs(roots) do
		for _, name in ipairs({ "lldb-dap", "_mojo-lldb-dap" }) do
			local bin = vim.fs.joinpath(bin_dir, name)
			if vim.uv.fs_stat(bin) then
				return bin
			end
		end
	end
	return nil
end

local function ensure_gitignore()
	if gitignore_notified then
		return
	end
	local gi_path = vim.fs.joinpath(vim.fn.getcwd(), ".gitignore")
	if vim.fn.filereadable(gi_path) == 0 then
		return
	end
	local f = io.open(gi_path, "r")
	if not f then
		return
	end
	local content = f:read("*a")
	f:close()
	for raw_line in content:gmatch("[^\r\n]+") do
		-- Strip leading/trailing whitespace
		local line = raw_line:match("^%s*(.-)%s*$") or raw_line
		-- Skip empty lines and comments; check remaining lines for _mojo-debug
		if line ~= "" and line:sub(1, 1) ~= "#" then
			-- Strip trailing slash for comparison
			local normalized = line:gsub("/$", "")
			if normalized == "_mojo-debug" then
				gitignore_notified = true
				return
			end
		end
	end
	local f2 = io.open(gi_path, "a")
	if not f2 then
		return
	end
	local sep = content:sub(-1) == "\n" and "" or "\n"
	f2:write(sep, "_mojo-debug/\n")
	f2:close()
	gitignore_notified = true
	vim.notify("mojo.nvim: added _mojo-debug/ to .gitignore", vim.log.levels.INFO)
end

local function build_mojo_file()
	local file = vim.fn.expand("%:p")
	if file == "" then
		vim.notify("mojo.nvim: no file to debug", vim.log.levels.ERROR)
		return nil, nil
	end
	local mojo = require("mojo.env").get_mojo_cmd()
	if not mojo then
		vim.notify("mojo.nvim: mojo binary not found", vim.log.levels.ERROR)
		return nil, nil
	end
	local build_args = require("mojo.config").options.debug.build_args or {}
	local dbg_dir = vim.fs.joinpath(vim.fn.getcwd(), "_mojo-debug")
	ensure_gitignore()
	vim.fn.mkdir(dbg_dir, "p")
	local base = vim.fn.fnamemodify(file, ":t:r")
	local out = vim.fs.joinpath(dbg_dir, base .. ".bin")
	local cmd = { mojo, "build", "--debug-level=full", "-O0", file, "-o", out }
	vim.list_extend(cmd, build_args)
	local result = vim.fn.system(cmd)
	if vim.v.shell_error ~= 0 then
		vim.notify("mojo.nvim: build failed before debugging:\n" .. result, vim.log.levels.ERROR)
		return nil, nil
	end
	sign_for_debug(out)
	return out, file
end

--- @param opts Mojo-lang.DebugConfig|nil
--- @return boolean
function M.setup(opts)
	if not opts or opts.enabled ~= true then
		return false
	end

	local ok, dap = pcall(require, "dap")
	if not ok then
		return false
	end

	if not env.get_dap_cmd() then
		return false
	end

	dap.adapters["mojo-lldb"] = function(callback, _)
		local cmd, env_dir = env.get_dap_cmd()
		if not cmd then
			--- @diagnostic disable-next-line: param-type-mismatch
			callback(nil)
			return
		end
		ensure_macos_executable(cmd[1])
		local adapter_env = {}
		local detect = require("mojo.env.detect")
		local detected = detect.detect()
		local command = cmd[1]
		local args = nil --- @type string[]|nil
		local visualizers, plugin = find_visualizers(detected)
		if visualizers then
			adapter_env.MODULAR_MOJO_MAX_LLDB_VISUALIZERS_PATH = visualizers
		end
		if plugin then
			adapter_env.MODULAR_MOJO_MAX_LLDB_PLUGIN_PATH = plugin
		end
		local native_bin = find_lldb_dap(detected)
		if native_bin then
			ensure_macos_executable(native_bin)
			command = native_bin
			args = {}
			if plugin then
				-- `!` makes plugin load fatal: if the Mojo plugin fails to load,
				-- stop the chain rather than proceeding with a degraded debugger.
				table.insert(args, "--pre-init-command")
				table.insert(args, "?!plugin load " .. plugin)
			end
			if visualizers then
				-- The .py formatters pretty-print the compiler's C++ internals,
				-- not Mojo values; load them best-effort (`?`) but never fatal.
				table.insert(args, "--pre-init-command")
				table.insert(args, "?command script import " .. vim.fs.joinpath(visualizers, "lldbDataFormatters.py"))
				table.insert(args, "--pre-init-command")
				table.insert(args, "?command script import " .. vim.fs.joinpath(visualizers, "mlirDataFormatters.py"))
			end
		end
		if env_dir then
			if detected and detected.type == "pixi" then
				adapter_env.CONDA_PREFIX = env_dir
				adapter_env.MODULAR_HOME = vim.fs.joinpath(env_dir, "share", "max")
			end
			if detected and detected.bin_dir then
				adapter_env.PATH = detected.bin_dir .. ":" .. (vim.env.PATH or "")
			end
			local lib = vim.fs.joinpath(env_dir, "lib")
			local swift = vim.fs.joinpath(lib, "swift")
			if vim.fn.has("mac") == 1 then
				adapter_env.DYLD_FALLBACK_LIBRARY_PATH = lib .. ":" .. swift
			else
				adapter_env.LD_LIBRARY_PATH = lib .. ":" .. swift
			end
		end
		callback({
			type = "executable",
			command = command,
			args = args,
			options = {
				env = adapter_env,
			},
		})
	end

	local function build_config(name, build_opts)
		build_opts = build_opts or {}
		local cwd = vim.fn.getcwd()
		local config = {
			type = "mojo-lldb",
			request = "launch",
			name = name,
			runInTerminal = true,
			cwd = cwd,
			sourceMap = { { ".", cwd } },
			initCommands = {
				"settings set target.source-map . " .. cwd,
			},
		}
		if build_opts.stop_on_entry then
			config.stopOnEntry = true
		end
		if build_opts.args_fn then
			config.args = build_opts.args_fn
		end
		if build_opts.program_fn then
			config.program = build_opts.program_fn
		end
		if build_opts.mojo_file then
			config.mojoFile = function()
				return vim.fn.expand("%:p")
			end
			config.program = function()
				return M.build()
			end
		end
		return config
	end

	dap.configurations.mojo = {
		build_config("Debug Mojo File", { mojo_file = true, stop_on_entry = true }),
		build_config("Debug Mojo File (with args)", {
			mojo_file = true,
			args_fn = function()
				local args_str = vim.fn.input("Program args: ")
				return vim.split(args_str, "%s+")
			end,
		}),
		build_config("Debug Binary", {
			program_fn = function()
				return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
			end,
		}),
		{
			type = "mojo-lldb",
			request = "attach",
			name = "Attach to Process",
			pid = require("dap.utils").pick_process,
		},
	}

	return true
end

--- Build current .mojo file and return the binary path.
--- @return string|nil
function M.build()
	local bin, _ = build_mojo_file()
	return bin
end

--- Locate the Mojo LLDB visualizers for the active environment.
--- Exposed for the native (terminal) debug adapter to load data formatters.
--- @param detected Mojo-lang.DetectedEnv|nil
--- @return string|nil, string|nil
function M.find_visualizers(detected)
	return find_visualizers(detected)
end

return M
