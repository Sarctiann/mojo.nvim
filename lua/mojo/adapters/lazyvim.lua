local M = {}

--- @param opts table|nil
--- @return table
function M.treesitter(opts)
	opts = opts or {}
	opts.ensure_installed = opts.ensure_installed or {}
	if not vim.tbl_contains(opts.ensure_installed, "mojo") then
		table.insert(opts.ensure_installed, "mojo")
	end
	return opts
end

--- @param opts Mojo-lang.LspConfig|nil
--- @return table
function M.lsp(opts)
	return require("mojo.lsp").opts(opts)
end

--- @param opts Mojo-lang.FormatConfig|nil
--- @return table
function M.format(opts)
	return require("mojo.format").opts(opts)
end

--- @param opts Mojo-lang.CompletionConfig|nil
--- @return table
function M.completion(opts)
	return require("mojo.adapters.blink").opts(opts)
end

return M
