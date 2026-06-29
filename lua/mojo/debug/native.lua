local config = require("mojo.config")
local window = require("mojo.debug.window")

local M = {}

--- @type integer|nil
local term_buf = nil

--- @type integer|nil
local term_win = nil

--- @type integer|nil
local term_job = nil

--- @type string|nil
local current_file = nil

--- @type integer|nil
local source_buf = nil

function M.start()
	local file = vim.fn.expand("%:p")
	if file == "" then
		vim.notify("mojo.nvim: no file to debug", vim.log.levels.ERROR)
		return
	end
	current_file = file
	source_buf = vim.fn.bufnr(file)

	local mojo = require("mojo.env").get_mojo_cmd()
	if not mojo then
		vim.notify("mojo.nvim: mojo binary not found", vim.log.levels.ERROR)
		return
	end

	-- Build the .mojo file to a binary with full debug info
	local build_ok, bin = pcall(require("mojo.adapters.dap").build)
	if not build_ok or not bin then
		vim.notify("mojo.nvim: failed to build .mojo for debug", vim.log.levels.ERROR)
		return
	end

	-- Find the mojo-lldb binary (native LLDB CLI adapted for Mojo)
	local lldb_bin = require("mojo.env").get_dbg_native_cmd()
	if not lldb_bin then
		vim.notify("mojo.nvim: mojo-lldb not found — cannot start native debug", vim.log.levels.ERROR)
		return
	end

	-- Quarantine check (only meaningful for the mojo binary, kept for parity)
	if vim.fn.has("mac") == 1 and mojo:sub(1, 1) == "/" then
		pcall(function()
			vim.fn.system({ "xattr", "-p", "com.apple.quarantine", mojo })
			if vim.v.shell_error == 0 then
				local dir = vim.fs.dirname(mojo)
				vim.notify(
					"mojo.nvim: mojo binary has quarantine — run:\n  xattr -dr com.apple.quarantine "
						.. dir,
					vim.log.levels.WARN
				)
			end
		end)
	end

	vim.cmd("belowright terminal " .. lldb_bin .. " " .. bin)
	term_buf = vim.api.nvim_get_current_buf()
	term_win = vim.api.nvim_get_current_win()
	term_job = vim.bo[term_buf].channel

	window.setup(term_buf, term_win)

	-- Wait for the (lldb) prompt before sending breakpoints
	M._wait_for_prompt()
end

--- Poll the terminal buffer until LLDB prompt appears, then sync BPs.
function M._wait_for_prompt()
	local lib = vim.uv or vim.loop
	local timer = lib.new_timer()
	if not timer then
		return
	end
	local elapsed = 0
	timer:start(100, 200, vim.schedule_wrap(function()
		elapsed = elapsed + 1
		if not M.is_active() or elapsed > 50 then
			timer:stop()
			timer:close()
			return
		end
		local buf = term_buf
		if not buf then
			timer:stop()
			timer:close()
			return
		end
		local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
		for _, line in ipairs(lines) do
			if line:match("%(lldb%)") then
				timer:stop()
				timer:close()
				require("mojo.debug.breakpoints").sync_all()
				return
			end
		end
	end))
end

local ATTACH_ERROR_MSG = "Not allowed to attach to process"

function M.run()
	M.send("run")
	local lib = vim.uv or vim.loop
	local timer = lib.new_timer()
	if not timer then
		return
	end
	local elapsed = 0
	timer:start(300, 300, vim.schedule_wrap(function()
		elapsed = elapsed + 1
		if not M.is_active() or elapsed > 15 then
			timer:stop()
			timer:close()
			return
		end
		local buf = term_buf
		if not buf then
			timer:stop()
			timer:close()
			return
		end
		local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
		for _, line in ipairs(lines) do
			if line:find(ATTACH_ERROR_MSG, 1, true) then
				timer:stop()
				timer:close()
				vim.notify(
					table.concat({
						"mojo.nvim: LLDB cannot attach to mojo process.",
						"",
						"The mojo binary installed via uv/PyPI lacks macOS debugger entitlements.",
						"Use pixi projects for debugging, or re-sign the binary with:",
						"  codesign --force --sign - --entitlements debug.plist <binary>",
						"",
						"See :Mojo help for details.",
					}, "\n"),
					vim.log.levels.WARN
				)
				return
			end
		end
	end))
end

--- @param cmd string
function M.send(cmd)
	if not term_job or term_job <= 0 then
		return
	end
	vim.api.nvim_chan_send(term_job, cmd .. "\n")
	local opts = config.options.debug or {}
	if opts.auto_scroll ~= false then
		local buf = term_buf
		local win = term_win
		if buf and win then
			window.auto_scroll(buf, win)
		end
	end
end

--- @param line integer
function M.send_breakpoint(line)
	if not current_file then
		return
	end
	M.send(string.format('breakpoint set --file %s --line %d', current_file, line))
end

--- @param lldb_id integer
function M.remove_breakpoint(lldb_id)
	M.send(string.format('breakpoint delete %d', lldb_id))
end

function M.close()
	if term_buf and vim.api.nvim_buf_is_valid(term_buf) then
		local win = vim.fn.bufwinid(term_buf)
		if win > 0 and vim.api.nvim_win_is_valid(win) then
			vim.api.nvim_win_close(win, true)
		end
	end
	term_buf = nil
	term_win = nil
	term_job = nil
	current_file = nil
	source_buf = nil
	require("mojo.debug.breakpoints").unwatch()
end

function M.is_active()
	return term_buf ~= nil and vim.api.nvim_buf_is_valid(term_buf)
end

--- @return integer|nil
function M.get_job()
	return term_job
end

--- @return string|nil
function M.get_file()
	return current_file
end

--- @return integer|nil
function M.get_source_buf()
	return source_buf
end

return M
