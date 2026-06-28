local env = require("mojo.env")
local config = require("mojo.config")
local log = require("mojo.log")

local M = {}

--- @type boolean
local lsp_has_crashed = false

--- @type integer
local lsp_restart_count = 0

--- @type integer
local LSP_RESTART_CAP = 3

--- @type integer
local lsp_backoff_level = 0

--- @type number
local lsp_last_restart_time = 0

--- @type number
local lsp_stable_since = 0

--- @type table<integer, integer>
local BACKOFF_DELAYS = { [0] = 0, [1] = 5, [2] = 30, [3] = 60 }

function M._track_lsp_exit(code, signal)
	if code ~= 0 or (signal and signal ~= 0) then
		lsp_has_crashed = true
		lsp_restart_count = lsp_restart_count + 1
		lsp_stable_since = 0
		log.log("lsp_crashed", function()
			return { code = code, signal = signal, restart_count = lsp_restart_count }
		end)
	end
end

function M._reset_lsp_crash()
	lsp_has_crashed = false
	lsp_restart_count = 0
	lsp_backoff_level = 0
	lsp_last_restart_time = 0
	lsp_stable_since = 0
end

--- @return "running"|"stopped"|"crashed"|"capped"|"unavailable"
function M.lsp_status()
	local clients = vim.lsp.get_clients({ bufnr = vim.fn.bufnr() })
	for _, client in ipairs(clients) do
		if client.name == "mojo" then
			if lsp_stable_since == 0 then
				lsp_stable_since = vim.loop.now()
			elseif vim.loop.now() - lsp_stable_since > 30000 then
				-- Running stable for >30s: reset backoff
				lsp_backoff_level = 0
				lsp_restart_count = 0
				lsp_has_crashed = false
			end
			vim.g["mojo_lsp_status"] = "running"
			return "running"
		end
	end
	lsp_stable_since = 0
	if lsp_has_crashed and lsp_restart_count >= LSP_RESTART_CAP then
		vim.g["mojo_lsp_status"] = "capped"
		return "capped"
	end
	if lsp_has_crashed then
		vim.g["mojo_lsp_status"] = "crashed"
		return "crashed"
	end
	local result = env.get_lsp_cmd() and "stopped" or "unavailable"
	vim.g["mojo_lsp_status"] = result
	return result
end

--- @return "active"|"inactive"|"unavailable"
function M.dbg_status()
	local ok, debug = pcall(require, "mojo.debug")
	if not ok then
		return "unavailable"
	end
	local st = debug.status()
	if st.active == "dap" then
		local ok_dap, dap = pcall(require, "dap")
		if ok_dap and dap.session and dap.session() then
			return "active"
		end
		return "inactive"
	end
	if st.active == "native" then
		return "active"
	end
	if st.dap or st.native then
		return "inactive"
	end
	return "unavailable"
end

--- @return "available"|"unavailable"
function M.fmt_status()
	return env.get_mojo_cmd() and "available" or "unavailable"
end

--- @param state string
--- @return string
function M.status_icon(state)
	if state == "running" or state == "active" or state == "available" then
		return "󰄬"
	elseif state == "stopped" or state == "inactive" then
		return "○"
	end
	return "󰅖"
end

--- @return string
function M.dbg_icon()
	local ok, debug = pcall(require, "mojo.debug")
	if not ok then
		return "󰅖"
	end
	local st = debug.status()
	if st.active == "dap" then
		local ok_dap, dap = pcall(require, "dap")
		if ok_dap and dap.session and dap.session() then
			return "󰄬"
		end
		return "○"
	end
	if st.active == "native" then
		return "󰄬"
	end
	if st.dap or st.native then
		return "○"
	end
	return "󰅖"
end

--- @param state string
--- @return string|nil
function M.status_color(state)
	if state == "running" or state == "active" or state == "available" then
		return "#a6da95"
	elseif state == "stopped" or state == "inactive" then
		return nil
	end
	return "#ed8796"
end

--- @return integer, integer
local function diag_counts()
	local items = vim.diagnostic.get(vim.fn.bufnr())
	local errors = 0
	local warnings = 0
	for _, item in ipairs(items) do
		if item.severity == 1 then
			errors = errors + 1
		elseif item.severity == 2 then
			warnings = warnings + 1
		end
	end
	return errors, warnings
end

--- @return string|nil
function M.diag_text()
	local errors, warnings = diag_counts()
	if errors == 0 and warnings == 0 then
		return nil
	end
	local parts = {}
	if errors > 0 then
		table.insert(parts, "󰅙" .. errors)
	end
	if warnings > 0 then
		table.insert(parts, "⚠" .. warnings)
	end
	return table.concat(parts, " ")
end

--- @return string|nil
function M.diag_color()
	local errors = diag_counts()
	if errors > 0 then
		return "#ed8796"
	end
	return "#ff9e64"
end

--- Single-string display for non-lualine statuslines.
--- @return string
function M.display()
	if vim.bo.filetype ~= "mojo" and not vim.b.mojo_debug and not vim.b.mojo_run then
		return ""
	end

	local opts = config.options.statusline or {}
	local parts = { opts.icon or "🔥" }

	local env_text = {}
	if opts.show_env_name ~= false then
		local detected = env.detect()
		if detected then
			local env_label = detected.type
			if detected.env_name and detected.env_name ~= "default" then
				env_label = string.format("%s %s", detected.type, detected.env_name)
			end
			table.insert(env_text, env_label)
		end
	end

	if opts.show_sdk_version ~= false then
		local version = env.get_version()
		if version then
			table.insert(env_text, version)
		end
	end

	if #env_text > 0 then
		table.insert(parts, table.concat(env_text, " "))
	end

	local status_parts = {}

	if opts.show_lsp ~= false then
		table.insert(status_parts, M.status_icon(M.lsp_status()) .. " lsp")
	end

	if opts.show_fmt ~= false then
		table.insert(status_parts, M.status_icon(M.fmt_status()) .. " fmt")
	end

	if opts.show_dbg ~= false then
		local ok, debug = pcall(require, "mojo.debug")
		local label = " dbg"
		if ok then
			local st = debug.status()
			if st.active == "native" then
				label = " dbg_ntv"
			elseif st.active == "dap" then
				label = " dbg_dap"
			end
		end
		table.insert(status_parts, M.dbg_icon() .. label)
	end

	if opts.show_diag ~= false then
		local diag = M.diag_text()
		if diag then
			table.insert(status_parts, diag)
		end
	end

	if #status_parts > 0 then
		table.insert(parts, "· " .. table.concat(status_parts, " · "))
	end

	return table.concat(parts, " ")
end

M.actions = {
	["Restart LSP"] = function()
		if lsp_has_crashed and lsp_restart_count >= LSP_RESTART_CAP then
			local delay = BACKOFF_DELAYS[lsp_backoff_level] or 60
			local elapsed = vim.loop.now() - lsp_last_restart_time
			if elapsed < delay * 1000 then
				local remaining = math.ceil(delay - elapsed / 1000)
				vim.notify(
					string.format("mojo.nvim: LSP restart backoff — wait %ds", remaining),
					vim.log.levels.WARN
				)
				return
			end
			lsp_backoff_level = math.min(lsp_backoff_level + 1, 3)
		end
		lsp_last_restart_time = vim.loop.now()
		lsp_has_crashed = false
		lsp_restart_count = 0
		lsp_stable_since = 0

		local clients = vim.lsp.get_clients({ name = "mojo" })
		if #clients == 0 then
			vim.schedule(function()
				vim.cmd("edit")
			end)
			return
		end
		for _, client in ipairs(clients) do
			client:stop()
		end
		vim.schedule(function()
			vim.wait(1000, function()
				return #vim.lsp.get_clients({ name = "mojo" }) == 0
			end, 50)
			vim.cmd("edit")
		end)
	end,
	["Stop LSP"] = function()
		local clients = vim.lsp.get_clients({ name = "mojo" })
		for _, client in ipairs(clients) do
			client:stop()
		end
	end,
	["Refresh SDK"] = function()
		local cache = require("mojo.env.detect")._cache()
		for k in pairs(cache) do
			cache[k] = nil
		end
		M._reset_lsp_crash()
		require("mojo.env.version").clear_cache()
	end,
}

--- Show floating window with numbered actions.
function M.show_menu()
	local items = vim.tbl_keys(M.actions)
	table.sort(items)

	local lines = {}
	for i, item in ipairs(items) do
		table.insert(lines, string.format("   [%d] %s", i, item))
	end

	local width = 20
	local height = #lines
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.bo[buf].filetype = "mojo-prompt"
	vim.bo[buf].modifiable = false

	vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = width,
		height = height,
		col = math.floor((vim.o.columns - width) / 2),
		row = math.floor((vim.o.lines - height) / 2),
		style = "minimal",
		border = "rounded",
		title = " Press [ 1 | 2 | 3]",
		title_pos = "center",
	})

	vim.api.nvim_buf_set_keymap(buf, "n", "1", "", {
		callback = function()
			M._close_and_run(items[1])
		end,
		noremap = true,
		silent = true,
	})
	vim.api.nvim_buf_set_keymap(buf, "n", "2", "", {
		callback = function()
			M._close_and_run(items[2])
		end,
		noremap = true,
		silent = true,
	})
	vim.api.nvim_buf_set_keymap(buf, "n", "3", "", {
		callback = function()
			M._close_and_run(items[3])
		end,
		noremap = true,
		silent = true,
	})
	vim.api.nvim_buf_set_keymap(buf, "n", "q", "", {
		callback = function()
			M._close_and_run()
		end,
		noremap = true,
		silent = true,
	})
	vim.api.nvim_buf_set_keymap(buf, "n", "<Esc>", "", {
		callback = function()
			M._close_and_run()
		end,
		noremap = true,
		silent = true,
	})
end

function M._close_and_run(action)
	if vim.api.nvim_win_is_valid(vim.api.nvim_get_current_win()) then
		vim.api.nvim_win_close(0, true)
	end
	if action then
		vim.schedule(function()
			M.actions[action]()
		end)
	end
end

return M
