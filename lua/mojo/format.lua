local env = require("mojo.env")

local M = {}

--- @return { command: fun(): string, args: string[], stdin: boolean }
function M.formatter()
	return {
		command = function()
			return env.get_mojo_cmd() or "mojo"
		end,
		args = { "format", "$FILENAME" },
		stdin = false,
	}
end

--- @param user_opts Mojo-lang.FormatConfig|nil
--- @return table
function M.opts(user_opts)
	user_opts = user_opts or {}
	local opts = vim.tbl_deep_extend("force", {}, user_opts)
	opts.formatters = opts.formatters or {}
	opts.formatters.mojo = M.formatter()
	opts.formatters_by_ft = opts.formatters_by_ft or {}
	if not opts.formatters_by_ft.mojo then
		opts.formatters_by_ft.mojo = { "mojo" }
	elseif type(opts.formatters_by_ft.mojo) == "table" and not vim.tbl_contains(opts.formatters_by_ft.mojo, "mojo") then
		table.insert(opts.formatters_by_ft.mojo, "mojo")
	end
	return opts
end

return M
