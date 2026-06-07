local detect = require("mojo.env.detect")
local util = require("mojo.env.util")
local debug = require("mojo.debug")

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
			debug.log("lsp_cmd", function()
				return { path = path or vim.fn.getcwd(), cmd = bin, source = "bin_dir" }
			end)
			return { bin }
		end
	end

	if env and env.type == "pixi" then
		local bin = util.find_pixi_binary(env.root, "mojo-lsp-server")
		if bin then
			debug.log("lsp_cmd", function()
				return { path = path or vim.fn.getcwd(), cmd = bin, source = "pixi_envs" }
			end)
			return { bin }
		end
	end

	if vim.fn.executable("mojo-lsp-server") == 1 then
		debug.log("lsp_cmd", function()
			return { path = path or vim.fn.getcwd(), cmd = "mojo-lsp-server", source = "path" }
		end)
		return { "mojo-lsp-server" }
	end

	debug.log("lsp_cmd_miss", function()
		return { path = path or vim.fn.getcwd() }
	end)
	return nil
end

return M