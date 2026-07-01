local config = require("mojo.config")

local M = {}

--- Actions mapped to their descriptions.
--- @type table<string, string>
local actions = {
	toggle_breakpoint = "Toggle Breakpoint",
	clear_breakpoints = "Clear All Breakpoints",
	start = "Start Native Debug",
	continue = "Continue / Start Debug",
	step_into = "Step Into (LLDB)",
	step_over = "Step Over (LLDB)",
	step_out = "Step Out (LLDB)",
	stop = "Stop Debug",
}

--- @param action string
--- @return function
local function handler(action)
	local dbg = require("mojo.debug")
	local nat = require("mojo.debug.native")
	local bp = require("mojo.debug.breakpoints")

	if action == "toggle_breakpoint" then
		return function()
			bp.toggle()
		end
	end
	if action == "clear_breakpoints" then
		return function()
			bp.clear()
		end
	end
	if action == "start" then
		return function()
			dbg.start("native")
		end
	end
	if action == "continue" then
		return function()
			if nat.is_active() then
				nat.send("continue")
			else
				dbg.start("native")
			end
		end
	end
	if action == "step_into" then
		return function()
			if nat.is_active() then
				nat.send("step")
			end
		end
	end
	if action == "step_over" then
		return function()
			if nat.is_active() then
				nat.send("next")
			end
		end
	end
	if action == "step_out" then
		return function()
			if nat.is_active() then
				nat.send("finish")
			end
		end
	end
	if action == "stop" then
		return function()
			if nat.is_active() then
				nat.close()
				vim.notify("mojo.nvim: debug session stopped", vim.log.levels.INFO)
			end
		end
	end
	return function()
		vim.notify("mojo.nvim: unknown debug action: " .. action, vim.log.levels.ERROR)
	end
end

--- Set up native debug keymaps in the current buffer.
--- User-provided keymaps are force-set. Default keymaps are only set when
--- no other plugin has claimed the keys.
function M.setup()
	local merged = config.options.debug and config.options.debug.keymaps
	if not merged then
		return
	end

	local user_keys = config._user_debug_keymaps or {}

	local opts = { buffer = true, silent = true }

	for action, desc in pairs(actions) do
		local key = merged[action]
		if key == false or key == nil or key == "" then
			-- disabled by user or no key assigned
			goto continue
		end

		local is_user_set = user_keys[action] ~= nil

		if is_user_set then
			-- User explicitly configured this key: force it.
			if user_keys[action] ~= false then
				vim.keymap.set("n", key, handler(action), vim.tbl_extend("force", opts, { desc = desc }))
			end
		else
			-- Default: only map if not already taken.
			if vim.fn.maparg(key, "n") == "" then
				vim.keymap.set("n", key, handler(action), vim.tbl_extend("force", opts, { desc = desc }))
			end
		end

		::continue::
	end
end

return M
