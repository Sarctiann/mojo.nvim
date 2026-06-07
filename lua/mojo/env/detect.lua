local util = require("mojo.env.util")
local debug = require("mojo.debug")

local M = {}

--- @type table<string, Mojo-lang.DetectedEnv|false>
local cache = {}

--- @param path string|nil
--- @return Mojo-lang.DetectedEnv|nil
function M.detect(path)
	local root = util.root_for(path)
	if not root then
		debug.log("detect_miss", function()
			return { path = path or vim.fn.getcwd() }
		end)
		return nil
	end

	if cache[root] ~= nil then
		debug.log("detect_cache", function()
			return { root = root, hit = true, type = cache[root] and cache[root].type or "none" }
		end)
		return cache[root] or nil
	end

	local pixi_toml = vim.fs.joinpath(root, "pixi.toml")
	local pixi_dir = vim.fs.joinpath(root, ".pixi")
	if util.has_file(pixi_toml) or util.has_dir(pixi_dir) then
		local env_name, pixi_env = util.first_pixi_env(root)
		cache[root] = {
			type = "pixi",
			root = root,
			env_name = env_name,
			env_dir = pixi_env,
			bin_dir = pixi_env and vim.fs.joinpath(pixi_env, "bin") or nil,
			activate_cmd = env_name and string.format('eval "$(pixi shell-hook --environment %s)"', env_name)
				or 'eval "$(pixi shell-hook)"',
		}
		debug.log("detect_pixi", function()
			return { root = root, env_name = env_name or "none", env_dir = pixi_env or "none" }
		end)
		return cache[root] or nil
	end

	local venv_dir = vim.fs.joinpath(root, ".venv")
	local venv_activate = vim.fs.joinpath(venv_dir, "bin", "activate")
	if util.has_file(venv_activate) then
		cache[root] = {
			type = "venv",
			root = root,
			env_dir = venv_dir,
			bin_dir = vim.fs.joinpath(venv_dir, "bin"),
			activate_cmd = "source .venv/bin/activate",
		}
		debug.log("detect_venv", function()
			return { root = root, env_dir = venv_dir }
		end)
		return cache[root] or nil
	end

	cache[root] = false
	debug.log("detect_none", function()
		return { root = root }
	end)
	return nil
end

--- @param path string|nil
--- @return string|nil
function M.activate_command(path)
	local env = M.detect(path)
	if not env then
		return nil
	end
	return env.activate_cmd
end

--- Expose cache for sibling modules (activate, bin) but not publicly.
--- @return table<string, Mojo-lang.DetectedEnv|false>
function M._cache()
	return cache
end

return M