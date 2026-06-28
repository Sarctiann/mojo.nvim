local native = require("mojo.debug.native")

local M = {}

--- @type integer|nil
local watch_augroup = nil

--- Read all breakpoint signs in the buffer (any group, any name).
--- Returns a sorted list of line numbers.
--- @param buf integer|nil
--- @return integer[]
function M.get_lines(buf)
	buf = buf or vim.fn.bufnr()
	local seen = {}
	-- Get all signs in the buffer (no group filter)
	local placed = vim.fn.sign_getplaced(buf)
	for _, entry in ipairs(placed) do
		for _, sign in ipairs(entry.signs or {}) do
			seen[sign.lnum] = true
		end
	end
	local lines = {}
	for line, _ in pairs(seen) do
		table.insert(lines, line)
	end
	table.sort(lines)
	if buf then
		vim.notify(string.format("get_lines: buf=%d name=%s signs=%d", buf, vim.api.nvim_buf_get_name(buf), #lines), vim.log.levels.INFO)
	end
	return lines
end

--- Send all current breakpoints to the native debugger.
function M.sync_all()
	if not native.is_active() then
		return
	end
	local file = native.get_file()
	if not file then
		return
	end
	local source_buf = native.get_source_buf()
	local lines = M.get_lines(source_buf)
	vim.notify(string.format("sync_all: source_buf=%d file=%s lines=%s", source_buf or -1, file, vim.inspect(lines)), vim.log.levels.INFO)
	for _, line in ipairs(lines) do
		native.send_breakpoint(line)
	end
end

function M.watch()
	if watch_augroup then
		return
	end
	watch_augroup = vim.api.nvim_create_augroup("MojoDebugBPs", { clear = true })
	vim.api.nvim_create_autocmd("BufWritePost", {
		group = watch_augroup,
		pattern = { "*.mojo", "*.🔥" },
		callback = function()
			if native.is_active() then
				M.sync_all()
			end
		end,
	})
end

function M.unwatch()
	if watch_augroup then
		vim.api.nvim_del_augroup_by_id(watch_augroup)
		watch_augroup = nil
	end
end

return M
