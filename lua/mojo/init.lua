local config = require("mojo.config")
local hooks = require("mojo.hooks")
local log = require("mojo.log")

local M = {}

M.hooks = hooks.defaults
M.log = log

--- @param user_config Mojo-lang.Config|nil
--- @return Mojo-lang.Config
function M.setup(user_config)
	local opts = config.setup(user_config)
	M.hooks = hooks.merge(opts.hooks)

	log.setup({ debug = opts.verbose })
	log.log("setup", function()
		return {
			verbose = opts.verbose or false,
			filetype = opts.filetype and opts.filetype.enabled ~= false,
			treesitter = opts.treesitter and opts.treesitter.enabled ~= false,
			lsp = opts.lsp and opts.lsp.enabled ~= false,
			format = opts.format and opts.format.enabled ~= false,
			terminal = opts.terminal and opts.terminal.enabled ~= false,
			statusline = opts.statusline and opts.statusline.enabled ~= false,
			debug = opts.debug and opts.debug.enabled == true,
		}
	end)

	if opts.filetype and opts.filetype.enabled ~= false then
		require("mojo.filetype").setup()
	end

	if opts.treesitter and opts.treesitter.enabled ~= false then
		local ts_opts = opts.treesitter
		if ts_opts and ts_opts.adapter then
			ts_opts.adapter(ts_opts)
		else
			require("mojo.adapters.treesitter").setup(ts_opts)
		end
	end

	if opts.lsp and opts.lsp.enabled ~= false then
		local lsp_opts = opts.lsp
		if lsp_opts and lsp_opts.adapter then
			lsp_opts.adapter(lsp_opts)
		else
			require("mojo.adapters.lspconfig").setup(lsp_opts)
		end
	end

	if opts.format and opts.format.enabled ~= false then
		local fmt_opts = opts.format
		if fmt_opts and fmt_opts.adapter then
			fmt_opts.adapter(fmt_opts)
		else
			require("mojo.adapters.conform").setup(fmt_opts)
		end
	end

	if opts.completion and opts.completion.enabled then
		local cmp_opts = opts.completion
		if cmp_opts and cmp_opts.adapter then
			cmp_opts.adapter(cmp_opts)
		elseif not require("mojo.adapters.blink").setup(cmp_opts) then
			require("mojo.adapters.nvim-cmp").setup(cmp_opts)
		end
	end

	local sl_opts = opts.statusline
	if sl_opts and sl_opts.enabled ~= false then
		if sl_opts.adapter then
			sl_opts.adapter(sl_opts)
		else
			require("mojo.adapters.lualine").setup(sl_opts)
		end
	end

	if opts.terminal and opts.terminal.enabled ~= false then
		require("mojo.terminal").setup(opts.terminal)
	end

	if opts.debug and opts.debug.enabled then
		local debug_opts = opts.debug
		if debug_opts and debug_opts.adapter then
			debug_opts.adapter(debug_opts)
		else
			require("mojo.adapters.dap").setup(debug_opts)
		end
	end

	local km = opts.keymaps
	if km and km.enabled ~= false then
		local mojo_augroup = vim.api.nvim_create_augroup("MojoKeymaps", { clear = true })
		vim.api.nvim_create_autocmd("FileType", {
			group = mojo_augroup,
			pattern = "mojo",
			callback = function()
				if km.signature_help then
					vim.keymap.set("n", km.signature_help, function()
						local line = vim.api.nvim_get_current_line()
						local col = vim.api.nvim_win_get_cursor(0)[2]
						local before = line:sub(1, col)
						local open = 0
						for i = 1, #before do
							local ch = before:sub(i, i)
							if ch == "(" then
								open = open + 1
							elseif ch == ")" then
								open = math.max(0, open - 1)
							end
						end
						if open > 0 then
							vim.lsp.buf.signature_help()
						else
							vim.lsp.buf.hover()
						end
					end, { buffer = true, desc = "LSP hover / signature help" })
				end
				if km.code_action then
					vim.keymap.set({ "n", "v" }, km.code_action, vim.lsp.buf.code_action, { buffer = true, desc = "Code action" })
				end

				require("mojo.debug.keymaps").setup()
			end,
		})
	end

	require("mojo.commands").setup(opts)

	return opts
end

return M
