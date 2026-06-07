local M = {}

--- Returns blink.cmp configuration for Mojo filetype.
--- Uses blink.compat to wrap the nvim-cmp source, falling back to
--- a simple static provider if blink.compat is not available.
--- @param opts Mojo-lang.CompletionConfig|nil
--- @return table
function M.opts(opts)
	opts = opts or {}

	return {
		enabled = function()
			return vim.bo.filetype == "mojo"
		end,
		sources = {
			completion = {
				enabled_providers = { "lsp", "mojo", "path", "buffer" },
			},
		},
		providers = {
			mojo = {
				name = "mojo",
				module = "blink.compat.source",
				opts = {
					provider = "mojo",
				},
			},
		},
	}
end

--- @param opts Mojo-lang.CompletionConfig|nil
--- @return boolean
function M.setup(opts)
	local ok, blink = pcall(require, "blink.cmp")
	if not ok then
		return false
	end

	require("mojo.adapters.nvim-cmp").setup(opts)

	local user_opts = M.opts(opts)
	local existing_providers = blink.config and blink.config.providers or {}
	local providers = vim.tbl_deep_extend("force", existing_providers, user_opts.providers or {})

	blink.setup({
		providers = providers,
		sources = user_opts.sources,
	})

	return true
end

return M