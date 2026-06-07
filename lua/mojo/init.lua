local config = require("mojo.config")
local hooks = require("mojo.hooks")
local env = require("mojo.env")
local debug = require("mojo.debug")

local M = {}

M.hooks = hooks.defaults
M.debug = debug

--- @param user_config Mojo-lang.Config|nil
--- @return Mojo-lang.Config
function M.setup(user_config)
	local opts = config.setup(user_config)
	M.hooks = hooks.merge(opts.hooks)

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

	vim.api.nvim_create_autocmd({ "BufReadPre", "BufNewFile" }, {
		pattern = "*.mojo",
		callback = function(ev)
			local path = vim.api.nvim_buf_get_name(ev.buf)
			debug.log("activate_for_dir", function()
				return { path = path }
			end)
			env.activate_for_dir(path)
		end,
	})

	if opts.filetype and opts.filetype.enabled ~= false then
		require("mojo.filetype").setup()
	end

	if opts.treesitter and opts.treesitter.enabled ~= false then
		require("mojo.treesitter").setup(opts.treesitter)
	end

	if opts.lsp and opts.lsp.enabled ~= false then
		require("mojo.lsp").setup(opts.lsp)
	end

	if opts.format and opts.format.enabled ~= false then
		require("mojo.format").setup(opts.format)
	end

	if opts.terminal and opts.terminal.enabled ~= false then
		require("mojo.terminal").setup(opts.terminal)
	end

	return opts
end

return M
