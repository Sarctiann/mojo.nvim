local detect = require("mojo.env.detect")
local util = require("mojo.env.util")
local debug = require("mojo.debug")

local M = {}

--- @param path string|nil
--- @return Mojo-lang.DetectedEnv|nil
function M.activate_for_dir(path)
	local env = detect.detect(path)
	if not env then
		debug.log("activate_skip", function()
			return { path = path or vim.fn.getcwd() }
		end)
		return nil
	end

	if env.bin_dir then
		util.env_prepend("PATH", env.bin_dir)
	end

	if env.type == "pixi" then
		vim.env.CONDA_PREFIX = env.env_dir
		vim.env.MODULAR_HOME = vim.fs.joinpath(env.env_dir, "share", "max")
		util.env_prepend("DYLD_FALLBACK_LIBRARY_PATH", vim.fs.joinpath(env.env_dir, "lib"))
		util.env_prepend("DYLD_FALLBACK_LIBRARY_PATH", vim.fs.joinpath(env.env_dir, "lib", "swift"))
	elseif env.type == "venv" then
		vim.env.VIRTUAL_ENV = env.env_dir
	end

	debug.log("activate", function()
		return {
			type = env.type,
			root = env.root,
			env_dir = env.env_dir or "none",
			bin_dir = env.bin_dir or "none",
		}
	end)

	return env
end

--- @param channel integer
--- @param path string|nil
--- @param delay_ms integer|nil
--- @return boolean
function M.activate_in_terminal(channel, path, delay_ms)
	local command = detect.activate_command(path)
	if not command then
		return false
	end

	vim.defer_fn(function()
		pcall(vim.api.nvim_chan_send, channel, command .. " && clear\n")
	end, delay_ms or 200)

	return true
end

return M