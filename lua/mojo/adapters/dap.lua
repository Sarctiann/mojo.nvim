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
	local dbg_dir = vim.fs.joinpath(vim.fn.getcwd(), "_mojo-debug")
	ensure_gitignore()
	vim.fn.mkdir(dbg_dir, "p")
	local base = vim.fn.fnamemodify(file, ":t:r")
	local out = vim.fs.joinpath(dbg_dir, base .. ".bin")
	local result = vim.fn.system({ mojo, "build", "--debug-level=full", "-O0", file, "-o", out })
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
		if detected and detected.type == "venv" and detected.bin_dir then
			local pkg_root = find_package_root(detected.bin_dir)
			if pkg_root then
				local pkg_lib = vim.fs.joinpath(pkg_root, "lib")
				local ext = vim.fn.has("mac") == 1 and "dylib" or "so"
				local plugin = vim.fs.joinpath(pkg_lib, "libMojoLLDB." .. ext)
				local visualizers = vim.fs.joinpath(pkg_lib, "lldb-visualizers")
				adapter_env.MODULAR_MOJO_MAX_LLDB_PLUGIN_PATH = plugin
				adapter_env.MODULAR_MOJO_MAX_LLDB_VISUALIZERS_PATH = visualizers
				local native_bin = vim.fs.joinpath(pkg_root, "bin", "lldb-dap")
				if vim.uv.fs_stat(native_bin) then
					ensure_macos_executable(native_bin)
					command = native_bin
					args = {
						"--pre-init-command",
						"?!plugin load " .. plugin,
						"--pre-init-command",
						"?command script import " .. vim.fs.joinpath(visualizers, "lldbDataFormatters.py"),
						"--pre-init-command",
						"?command script import " .. vim.fs.joinpath(visualizers, "mlirDataFormatters.py"),
					}
				end
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

return M
