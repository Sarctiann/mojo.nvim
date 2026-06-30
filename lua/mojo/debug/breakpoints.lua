local native = require("mojo.debug.native")

local M = {}

--- @type integer|nil
local watch_augroup = nil

local SIGN_NAME = "MojoBreakpoint"

-- Get nvim-dap breakpoints module if available, nil otherwise.
--- @return table|nil
local function get_dap_bp()
	local ok, bp = pcall(require, "dap.breakpoints")
	if ok then
		return bp
	end
	return nil
end

-- Ensure the fallback breakpoint sign is defined.
local function ensure_sign()
	vim.fn.sign_define(SIGN_NAME, { text = "●", texthl = "DiagnosticSignError" })
end

--- Read breakpoints from nvim-dap (if available) or fallback signs.
--- Returns a sorted list of line numbers.
--- @param buf integer|nil
--- @return integer[]
function M.get_lines(buf)
	buf = buf or vim.fn.bufnr()
	local lines = {}
	local bp = get_dap_bp()
	if bp then
		local bps = bp.get(buf)
		local buf_bps = bps[buf]
		if buf_bps then
			for _, b in ipairs(buf_bps) do
				lines[#lines + 1] = b.line
			end
		end
	else
		local placed = vim.fn.sign_getplaced(buf, { group = "*" })
		for _, entry in ipairs(placed) do
			for _, sign in ipairs(entry.signs or {}) do
				if sign.name == SIGN_NAME then
					lines[#lines + 1] = sign.lnum
				end
			end
		end
	end
	table.sort(lines)
	return lines
end

--- Toggle a breakpoint at the current line.
function M.toggle()
	local bp = get_dap_bp()
	if bp then
		bp.toggle()
	else
		ensure_sign()
		local buf = vim.fn.bufnr()
		local line = vim.fn.line(".")
		local placed = vim.fn.sign_getplaced(buf, { group = "*", lnum = line })[1]
		local exists = false
		if placed and placed.signs and #placed.signs > 0 then
			for _, s in ipairs(placed.signs) do
				if s.name == SIGN_NAME then
					vim.fn.sign_unplace("MojoDebugBPs", { buffer = buf, id = s.id })
					exists = true
				end
			end
		end
		if not exists then
			vim.fn.sign_place(0, "MojoDebugBPs", SIGN_NAME, buf, { lnum = line })
		end
	end
end

--- Remove all breakpoints from the current buffer.
function M.clear()
	local bp = get_dap_bp()
	if bp then
		local buf = vim.fn.bufnr()
		local bps = bp.get(buf)
		local buf_bps = bps[buf]
		if buf_bps then
			for _, b in ipairs(buf_bps) do
				bp.remove(buf, b.line)
			end
		end
	else
		local buf = vim.fn.bufnr()
		vim.fn.sign_unplace("MojoDebugBPs", { buffer = buf })
	end
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
