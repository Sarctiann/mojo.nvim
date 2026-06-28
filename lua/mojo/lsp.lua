local env = require("mojo.env")
local log = require("mojo.log")

local M = {}

--- Native vim.lsp.config root_dir resolver (Neovim 0.11+ signature).
--- @param root_markers string[]|nil
--- @return fun(bufnr: integer, on_dir: fun(root_dir: string|nil))
local function root_dir(root_markers)
	root_markers = root_markers or { "pixi.toml", "pyproject.toml", ".pixi", ".venv" }
	return function(bufnr, on_dir)
		local fname = vim.api.nvim_buf_get_name(bufnr)
		local path = (fname ~= "" and fname) or vim.fn.getcwd()
		on_dir(vim.fs.root(path .. "/.", root_markers) or vim.fs.dirname(path))
	end
end

--- @param user_opts Mojo-lang.LspConfig|nil
--- @return table
function M.opts(user_opts)
	user_opts = user_opts or {}

	-- Root-independent server settings derived from user options.
	local settings = nil
	local mojo_settings = {}
	if user_opts.include_dirs then
		mojo_settings.includeDirs = user_opts.include_dirs
	end
	if user_opts.filter_docstring_diagnostics ~= nil then
		mojo_settings.filterDocstringDiagnostics = user_opts.filter_docstring_diagnostics
	end
	if next(mojo_settings) then
		settings = { mojo = mojo_settings }
	end

	local opts = vim.tbl_deep_extend("force", {
		-- Resolve the LSP binary per project root (Pixi / venv / bin_dir / PATH).
		-- `config.root_dir` is already resolved to the root string by the time
		-- this runs, so the function form of `cmd` is the native vim.lsp.config
		-- replacement for nvim-lspconfig's deprecated `on_new_config` hook.
		cmd = function(dispatchers, config)
			local cmd = env.get_lsp_cmd(config and config.root_dir) or { "mojo-lsp-server" }
			return vim.lsp.rpc.start(cmd, dispatchers)
		end,
		filetypes = { "mojo" },
		root_dir = root_dir(user_opts.root_markers),
		settings = settings,
		on_exit = function(code, signal, _)
			require("mojo.status")._track_lsp_exit(code, signal)
		end,
	}, user_opts)

	log.log("lsp_opts", function()
		return {
			root_markers = table.concat(
				user_opts.root_markers or { "pixi.toml", "pyproject.toml", ".pixi", ".venv" },
				","
			),
		}
	end)

	return opts
end

return M
