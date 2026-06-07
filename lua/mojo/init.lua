local config = require("mojo.config")
local hooks = require("mojo.hooks")
local debug = require("mojo.debug")

local M = {}

M.hooks = hooks.defaults
M.debug = debug

--- @param user_config Mojo-lang.Config|nil
--- @return Mojo-lang.Config
function M.setup(user_config)
	local opts = config.setup(user_config)
	M.hooks = hooks.merge(opts.hooks)

	debug.setup({ debug = opts.debug })
	debug.log("setup", function()
		return {
			debug = opts.debug or false,
			filetype = opts.filetype and opts.filetype.enabled ~= false,
			treesitter = opts.treesitter and opts.treesitter.enabled ~= false,
			lsp = opts.lsp and opts.lsp.enabled ~= false,
			format = opts.format and opts.format.enabled ~= false,
			terminal = opts.terminal and opts.terminal.enabled ~= false,
		}
	end)

	if opts.filetype and opts.filetype.enabled ~= false then
		require("mojo.filetype").setup()
	end

	if opts.treesitter and opts.treesitter.enabled ~= false then
		local ts_opts = opts.treesitter
		if ts_opts.adapter then
			ts_opts.adapter(ts_opts)
		else
			require("mojo.adapters.treesitter").setup(ts_opts)
		end
	end

	if opts.lsp and opts.lsp.enabled ~= false then
		local lsp_opts = opts.lsp
		if lsp_opts.adapter then
			lsp_opts.adapter(lsp_opts)
		else
			require("mojo.adapters.lspconfig").setup(lsp_opts)
		end
	end

	if opts.format and opts.format.enabled ~= false then
		local fmt_opts = opts.format
		if fmt_opts.adapter then
			fmt_opts.adapter(fmt_opts)
		else
			require("mojo.adapters.conform").setup(fmt_opts)
		end
	end

	if opts.completion and opts.completion.enabled then
		local cmp_opts = opts.completion
		if cmp_opts.adapter then
			cmp_opts.adapter(cmp_opts)
		else
			if not require("mojo.adapters.blink").setup(cmp_opts) then
				require("mojo.adapters.nvim-cmp").setup(cmp_opts)
			end
		end
	end

	if opts.terminal and opts.terminal.enabled ~= false then
		require("mojo.terminal").setup(opts.terminal)
	end

	return opts
end

return M