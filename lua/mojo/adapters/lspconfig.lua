local M = {}

--- @param opts Mojo-lang.LspConfig|nil
--- @return boolean
function M.setup(opts)
	local ok, lspconfig = pcall(require, "lspconfig")
	if not ok then
		return false
	end

	local config = require("mojo.config").options
	local lsp_opts = require("mojo.lsp").opts(opts or config.lsp)

	lspconfig.mojo.setup(lsp_opts)
	return true
end

return M