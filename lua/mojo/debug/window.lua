local M = {}

local WINBAR_NORMAL = "%#MojoDebugWinBar#  [r]un [n]ext [s]tep [c]ontinue [v]ars [b]ps  |  [q] [esc] close  [⏎] enter  "
local WINBAR_TERMINAL = "%#MojoDebugWinBar#  ─── LLDB ─── [i] insert mode  |  [q] close  [esc] back to normal  "

local function set_winbar_text(win, text)
	if vim.api.nvim_win_is_valid(win) then
		vim.wo[win].winbar = text
	end
end

--- @param buf integer
--- @param win integer
function M.setup(buf, win)
	vim.bo[buf].buflisted = false
	vim.b[buf].mojo_debug = true

	vim.api.nvim_set_hl(0, "MojoDebugWinBar", { bg = "#4e8cbf", fg = "#ffffff" })
	set_winbar_text(win, WINBAR_NORMAL)
	vim.wo[win].winhl = "Normal:NormalFloat"
	vim.wo[win].statusline = " "

	-- Keep statusline hidden when window is refocused
	vim.api.nvim_create_autocmd("WinEnter", {
		buffer = buf,
		callback = function()
			local cur_win = vim.api.nvim_get_current_win()
			if vim.api.nvim_win_is_valid(cur_win) and vim.api.nvim_win_get_buf(cur_win) == buf then
				vim.wo[cur_win].statusline = " "
			end
		end,
	})

	-- Update winbar based on mode (n vs t)
	vim.api.nvim_create_autocmd("ModeChanged", {
		buffer = buf,
		callback = function()
			local cur_win = vim.api.nvim_get_current_win()
			if not (vim.api.nvim_win_is_valid(cur_win) and vim.api.nvim_win_get_buf(cur_win) == buf) then
				return
			end
			local mode = vim.api.nvim_get_mode().mode
			if mode:sub(1, 1) == "t" then
				set_winbar_text(cur_win, WINBAR_TERMINAL)
			else
				set_winbar_text(cur_win, WINBAR_NORMAL)
			end
		end,
	})

	-- Normal mode: q closes, <Esc> closes, <CR> enters terminal mode
	M._map(buf, "n", "q", function()
		require("mojo.debug.native").close()
	end, "Close debug terminal")
	M._map(buf, "n", "<Esc>", function()
		require("mojo.debug.native").close()
	end, "Close debug terminal")
	M._map(buf, "n", "<CR>", function()
		vim.api.nvim_command("startinsert")
	end, "Enter terminal mode (send to LLDB)")

	-- Terminal mode: q closes, <Esc> back to normal mode (does NOT close)
	M._map(buf, "t", "q", function()
		vim.cmd("stopinsert")
		require("mojo.debug.native").close()
	end, "Close debug terminal")
	M._map(buf, "t", "<Esc>", function()
		vim.cmd("stopinsert")
	end, "Back to normal mode")

	-- LLDB control commands (only meaningful in normal mode)
	local function lldb(cmd)
		return function()
			require("mojo.debug.native").send(cmd)
		end
	end
	M._map(buf, "n", "r", function()
		require("mojo.debug.native").run()
	end, "LLDB: run")
	M._map(buf, "n", "n", lldb("next"), "LLDB: next")
	M._map(buf, "n", "s", lldb("step"), "LLDB: step")
	M._map(buf, "n", "c", lldb("continue"), "LLDB: continue")
	M._map(buf, "n", "v", lldb("frame variable"), "LLDB: variables")
	M._map(buf, "n", "b", function()
		require("mojo.debug.breakpoints").sync_all()
		vim.notify("mojo.nvim: breakpoints synced to LLDB", vim.log.levels.INFO)
	end, "Sync breakpoints")
end

--- @param buf integer
--- @param win integer
function M.auto_scroll(buf, win)
	if not vim.api.nvim_buf_is_valid(buf) or not vim.api.nvim_win_is_valid(win) then
		return
	end
	local line_count = vim.api.nvim_buf_line_count(buf)
	vim.api.nvim_win_set_cursor(win, { line_count, 0 })
end

--- @param buf integer
--- @param mode string
--- @param lhs string
--- @param rhs function
--- @param desc string
function M._map(buf, mode, lhs, rhs, desc)
	vim.keymap.set(mode, lhs, rhs, { buffer = buf, noremap = true, silent = true, desc = desc })
end

return M
