local M = {}

--- @param opts Mojo-lang.FormatConfig|nil
--- @return boolean
function M.setup(opts)
	local ok, conform = pcall(require, "conform")
	if not ok then
		return false
	end

	local config = require("mojo.config").options
	conform.setup(require("mojo.format").opts(opts or config.format))

	return true
end

return M