local M = {}

--- @param opts Mojo-lang.LspConfig|nil
--- @return boolean
function M.setup(opts)
	-- Use the native LSP config API (Neovim 0.11+). This replaces the deprecated
	-- `require('lspconfig')` framework (removed in nvim-lspconfig v3.0.0), so
	-- nvim-lspconfig is no longer required for Mojo LSP support.
	if not (vim.lsp.config and vim.lsp.enable) then
		return false
	end

	local config = require("mojo.config").options
	local lsp_opts = require("mojo.lsp").opts(opts or config.lsp)

	vim.lsp.config("mojo", lsp_opts)
	vim.lsp.enable("mojo")
	return true
end

return M

