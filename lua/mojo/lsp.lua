local env = require("mojo.env")
local log = require("mojo.log")

local M = {}

-- Most recently resolved project root. On Neovim 0.11.0–0.11.2 the function
-- form of `cmd` receives only `dispatchers` (no `config`), so we fall back to
-- this value; on 0.11.3+ the race-free `config.root_dir` is used instead.
local resolved_root = nil

--- Native vim.lsp.config root_dir resolver (Neovim 0.11+ signature).
--- @param root_markers string[]|nil
--- @return fun(bufnr: integer, on_dir: fun(root_dir: string|nil))
local function root_dir(root_markers)
	root_markers = root_markers or { "pixi.toml", "pyproject.toml", ".pixi", ".venv" }
	return function(bufnr, on_dir)
		local fname = vim.api.nvim_buf_get_name(bufnr)
		local path = (fname ~= "" and fname) or vim.fn.getcwd()
		local root = vim.fs.root(path .. "/.", root_markers) or vim.fs.dirname(path)
		resolved_root = root
		on_dir(root)
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

	local opts
	opts = vim.tbl_deep_extend("force", {
		-- Resolve the LSP binary per project root (Pixi / venv / bin_dir / PATH).
		-- The function form of `cmd` is the native vim.lsp.config replacement for
		-- nvim-lspconfig's deprecated `on_new_config` hook. `config.root_dir` is
		-- already resolved when this runs (Neovim 0.11.3+); on 0.11.0–0.11.2,
		-- where `config` is not passed, fall back to the root from `root_dir`.
		-- The array form of `cmd` forwards cmd_cwd/cmd_env/detached for us; the
		-- function form does not, so pass them through explicitly.
		cmd = function(dispatchers, config)
			local root = (config and config.root_dir) or resolved_root
			local server = env.get_lsp_cmd(root) or { "mojo-lsp-server" }
			return vim.lsp.rpc.start(server, dispatchers, {
				cwd = opts.cmd_cwd,
				env = opts.cmd_env,
				detached = opts.detached,
			})
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
