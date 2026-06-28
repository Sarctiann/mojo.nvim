local detect = require("mojo.env.detect")
local util = require("mojo.env.util")
local log = require("mojo.log")

local M = {}

--- @param path string|nil
--- @return string|nil
function M.get_mojo_cmd(path)
	local env = detect.detect(path)
	if env and env.bin_dir then
		local bin = vim.fs.joinpath(env.bin_dir, "mojo")
		if util.has_file(bin) then
			return bin
		end
	end

	if env and env.type == "pixi" then
		local bin = util.find_pixi_binary(env.root, "mojo")
		if bin then
			return bin
		end
	end

	return vim.fn.executable("mojo") == 1 and "mojo" or nil
end

--- @param path string|nil
--- @return string[]|nil
function M.get_lsp_cmd(path)
	local env = detect.detect(path)
	if env and env.bin_dir then
		local bin = vim.fs.joinpath(env.bin_dir, "mojo-lsp-server")
		if util.has_file(bin) then
			log.log("lsp_cmd", function()
				return { path = path or vim.fn.getcwd(), cmd = bin, source = "bin_dir" }
			end)
			return { bin }
		end
	end

	if env and env.type == "pixi" then
		local bin = util.find_pixi_binary(env.root, "mojo-lsp-server")
		if bin then
			log.log("lsp_cmd", function()
				return { path = path or vim.fn.getcwd(), cmd = bin, source = "pixi_envs" }
			end)
			return { bin }
		end
	end

	if vim.fn.executable("mojo-lsp-server") == 1 then
		log.log("lsp_cmd", function()
			return { path = path or vim.fn.getcwd(), cmd = "mojo-lsp-server", source = "path" }
		end)
		return { "mojo-lsp-server" }
	end

	log.log("lsp_cmd_miss", function()
		return { path = path or vim.fn.getcwd() }
	end)
	return nil
end

--- Search for a debug binary by role, using config.search_for order.
--- @param path string|nil
--- @param role "dap"|"native"
--- @return string|nil, string|nil
local function find_debug_binary(path, role)
	local config = require("mojo.config")
	local entries = config.options and config.options.debug and config.options.debug.search_for
	if not entries then
		return nil, nil
	end

	local env = detect.detect(path)
	for _, entry in ipairs(entries) do
		if entry.role == role then
			local name = entry.name
			if env and env.bin_dir then
				local bin = vim.fs.joinpath(env.bin_dir, name)
				if vim.fn.executable(bin) == 1 then
					log.log("dbg_" .. role .. "_cmd", function()
						return { path = path or vim.fn.getcwd(), cmd = bin, source = "bin_dir" }
					end)
					return bin, env.env_dir
				end
			end

			if env and env.type == "pixi" then
				local bin = util.find_pixi_binary(env.root, name)
				if bin and vim.fn.executable(bin) == 1 then
					log.log("dbg_" .. role .. "_cmd", function()
						return { path = path or vim.fn.getcwd(), cmd = bin, source = "pixi_envs" }
					end)
					return bin, env.env_dir
				end
			end

			if vim.fn.executable(name) == 1 then
				log.log("dbg_" .. role .. "_cmd", function()
					return { path = path or vim.fn.getcwd(), cmd = name, source = "path" }
				end)
				return name, nil
			end
		end
	end

	log.log("dbg_" .. role .. "_cmd_miss", function()
		return { path = path or vim.fn.getcwd() }
	end)
	return nil, nil
end

--- @param path string|nil
--- @return string[]|nil, string|nil
function M.get_dap_cmd(path)
	local cmd, env_dir = find_debug_binary(path, "dap")
	if cmd then
		return { cmd }, env_dir
	end
	return nil, nil
end

--- @param path string|nil
--- @return string|nil
function M.get_dbg_native_cmd(path)
	local cmd = find_debug_binary(path, "native")
	return cmd
end

return M
