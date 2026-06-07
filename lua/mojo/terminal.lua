local env = require("mojo.env")

local M = {}

--- @type table<string, boolean>
local shells = { zsh = true, bash = true, fish = true, sh = true, dash = true, ksh = true }

--- @param bufname string
--- @return string|nil
local function terminal_cmd_from_bufname(bufname)
	local cmd = bufname:match(":([^:]+)$")
	return cmd and vim.fn.fnamemodify(cmd, ":t") or nil
end

--- @param buf integer
--- @return boolean
local function is_shell_terminal(buf)
	local bufname = vim.api.nvim_buf_get_name(buf)
	local cmd = terminal_cmd_from_bufname(bufname)
	if not cmd then
		return true
	end
	return shells[cmd] == true or cmd == vim.fn.fnamemodify(vim.o.shell, ":t")
end

--- @param opts Mojo-lang.TerminalConfig|nil
--- @return nil
function M.setup(opts)
	opts = opts or {}
	if opts.enabled == false or opts.auto_activate == false then
		return
	end

	vim.api.nvim_create_autocmd("TermOpen", {
		callback = function()
			local buf = vim.api.nvim_get_current_buf()
			local win = vim.api.nvim_get_current_win()
			if vim.api.nvim_win_get_config(win).relative ~= "" then
				return
			end

			if not is_shell_terminal(buf) then
				return
			end

			local channel = vim.bo[buf].channel
			if not channel or channel <= 0 then
				return
			end

			env.activate_in_terminal(channel, vim.fn.getcwd(), opts.delay_ms or 200)
		end,
	})
end

return M
