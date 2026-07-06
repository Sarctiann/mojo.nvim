local env = require("mojo.env")
local config = require("mojo.config")

local M = {}

--- @type "native"|"dap"|nil
local active_backend = nil

--- @return string|nil
function M.get_backend()
	return active_backend
end

--- @param backend "auto"|"native"|"dap"|nil
function M.start(backend)
	if backend == nil or backend == "auto" then
		backend = M._pick_backend()
	end
	if not backend then
		vim.notify("mojo.nvim: no debugger available (mojo not found in PATH)", vim.log.levels.ERROR)
		return
	end

	if backend == "dap" then
		M._start_dap()
	elseif backend == "native" then
		active_backend = "native"
		require("mojo.debug.native").start()
		require("mojo.debug.breakpoints").watch()
	else
		vim.notify("mojo.nvim: unknown debug backend: " .. tostring(backend), vim.log.levels.ERROR)
	end
end

--- @return "native"|"dap"|nil
function M._pick_backend()
	if config.options.debug and config.options.debug.auto_backend then
		return config.options.debug.auto_backend
	end
	if env.get_dap_cmd() then
		return "dap"
	end
	if env.get_dbg_native_cmd() then
		return "native"
	end
	if env.get_mojo_cmd() then
		return "native"
	end
	return nil
end

function M._start_dap()
	local ok, dap = pcall(require, "dap")
	if not ok then
		vim.notify("mojo.nvim: nvim-dap not installed, cannot start dbg_dap", vim.log.levels.ERROR)
		active_backend = nil
		return
	end
	local ok_build, bin = pcall(require("mojo.adapters.dap").build)
	if not ok_build or not bin then
		active_backend = nil
		return
	end

	local cwd = vim.fn.getcwd()
	local env_vars = {}
	local detected = require("mojo.env.detect").detect()
	if detected then
		if detected.env_dir then
			env_vars.CONDA_PREFIX = detected.env_dir
			local lib = vim.fs.joinpath(detected.env_dir, "lib")
			local swift = vim.fs.joinpath(lib, "swift")
			if vim.fn.has("mac") == 1 then
				env_vars.DYLD_FALLBACK_LIBRARY_PATH = lib .. ":" .. swift
			else
				env_vars.LD_LIBRARY_PATH = lib .. ":" .. swift
			end
		end
		if detected.type == "venv" and detected.env_dir and detected.bin_dir then
			local pyvenv_cfg = vim.fs.joinpath(detected.env_dir, "pyvenv.cfg")
			local f = io.open(pyvenv_cfg, "r")
			if f then
				local python_home = nil
				local python_ver_major = "3"
				local python_ver_minor = "13"
				for line in f:lines() do
					local key, value = line:match("^(%S+)%s*=%s*(.+)$")
					if key == "home" then
						python_home = vim.fs.dirname(value)
					elseif key == "version_info" then
						local major, minor = value:match("^(%d+)%.(%d+)")
						if major then
							python_ver_major = major
						end
						if minor then
							python_ver_minor = minor
						end
					end
				end
				f:close()
				if python_home then
					env_vars.PYTHONHOME = python_home
					local python_bin = vim.fs.joinpath(detected.bin_dir, "python3")
					if vim.uv.fs_stat(python_bin) then
						env_vars.MOJO_PYTHON = python_bin
					end
					local python_lib_dir = vim.fs.joinpath(python_home, "lib")
					local ext = vim.fn.has("mac") == 1 and "dylib" or "so"
					local libpython = vim.fs.joinpath(
						python_lib_dir,
						"libpython" .. python_ver_major .. python_ver_minor .. "." .. ext
					)
					if vim.uv.fs_stat(libpython) then
						env_vars.MOJO_PYTHON_LIBRARY = libpython
					end
					local existing = env_vars.DYLD_FALLBACK_LIBRARY_PATH
						or env_vars.LD_LIBRARY_PATH
						or ""
					local lib_path = python_lib_dir
					if existing ~= "" then
						lib_path = existing .. ":" .. lib_path
					end
					if vim.fn.has("mac") == 1 then
						env_vars.DYLD_FALLBACK_LIBRARY_PATH = lib_path
					else
						env_vars.LD_LIBRARY_PATH = lib_path
					end
				end
			end
		end
	end

	local env_parts = {}
	for k, v in pairs(env_vars) do
		table.insert(env_parts, k .. "=" .. v)
	end
	local init = {}
	if #env_parts > 0 then
		table.insert(init, "settings set target.env-vars " .. table.concat(env_parts, " "))
	end

	active_backend = "dap"
	local ok_run, err = pcall(dap.run, {
		type = "mojo-lldb",
		request = "launch",
		name = "Debug Mojo File",
		program = bin,
		cwd = cwd,
		stopOnEntry = false,
		initCommands = init,
	})
	if not ok_run then
		active_backend = nil
		vim.notify("mojo.nvim: DAP launch failed: " .. tostring(err), vim.log.levels.ERROR)
	end
end

function M.toggle_bp()
	require("mojo.debug.breakpoints").toggle()
	if active_backend == "native" then
		require("mojo.debug.breakpoints").sync_all()
	end
end

function M.clear_bps()
	require("mojo.debug.breakpoints").clear()
	if active_backend == "native" then
		require("mojo.debug.breakpoints").sync_all()
	end
end

--- @return { native: boolean, dap: boolean, active: string|nil }
function M.status()
	return {
		native = env.get_dbg_native_cmd() ~= nil or env.get_mojo_cmd() ~= nil,
		dap = env.get_dap_cmd() ~= nil,
		active = active_backend,
	}
end

return M
