local env = require("mojo.env")
local debug = require("mojo.debug")

local M = {}

--- @param root_markers string[]|nil
--- @return fun(fname: string|nil): string
local function root_dir(root_markers)
	root_markers = root_markers or { "pixi.toml", "pyproject.toml", ".pixi", ".venv" }
	return function(fname)
		local path = fname or vim.fn.getcwd()
		return vim.fs.root(path .. "/.", root_markers) or vim.fs.dirname(path)
	end
end

--- @param user_opts Mojo-lang.LspConfig|nil
--- @return table
function M.opts(user_opts)
	user_opts = user_opts or {}
	local opts = vim.tbl_deep_extend("force", {
		cmd = { "mojo-lsp-server" },
		filetypes = { "mojo" },
		root_dir = root_dir(user_opts.root_markers),
		on_new_config = function(new_config, root)
			local cmd = env.get_lsp_cmd(root)
			if cmd then
				new_config.cmd = cmd
			end
		end,
	}, user_opts)

	debug.log("lsp_opts", function()
		return {
			root_markers = table.concat(
				user_opts.root_markers or { "pixi.toml", "pyproject.toml", ".pixi", ".venv" },
				","
			),
		}
	end)

	return opts
end

--- @param user_opts Mojo-lang.LspConfig|nil
--- @return boolean
function M.setup(user_opts)
	local ok, lspconfig = pcall(require, "lspconfig")
	if not ok then
		debug.log("lsp_setup_skip", function()
			return { reason = "lspconfig_missing" }
		end)
		return false
	end

	debug.log("lsp_setup", function()
		return { server = "mojo" }
	end)
	lspconfig.mojo.setup(M.opts(user_opts))
	return true
end

return M
