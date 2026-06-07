local M = {}

--- @param opts Mojo-lang.CompletionConfig|nil
--- @return boolean
function M.setup(opts)
	opts = opts or {}
	if opts.enabled == false then
		return false
	end

	local ok, cmp = pcall(require, "cmp")
	if not ok then
		return false
	end

	local completion = require("mojo.completion")
	local source = {}

	function source.new()
		return setmetatable({}, { __index = source })
	end

	function source:get_trigger_characters()
		return { ".", ":" }
	end

	function source:complete(_, callback)
		callback({ items = completion.all_items() })
	end

	cmp.register_source("mojo", source.new())

	cmp.setup.filetype("mojo", {
		sources = cmp.config.sources({
			{ name = "nvim_lsp" },
			{ name = "mojo" },
			{ name = "buffer" },
			{ name = "path" },
		}),
	})

	return true
end

return M