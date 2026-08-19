-- test_status.lua
-- Run: nvim --headless -c "luafile tests/test_status.lua" -c "qa!"

local total_errors = 0

local function fail(msg)
	print("  FAIL: " .. msg)
	total_errors = total_errors + 1
end

local function pass(msg)
	print("  PASS: " .. msg)
end

local status = require("mojo.status")

-- status_icon
local icon_tests = {
	{ state = "running", expected = "󰄬" },
	{ state = "active", expected = "󰄬" },
	{ state = "available", expected = "󰄬" },
	{ state = "stopped", expected = "○" },
	{ state = "inactive", expected = "○" },
	{ state = "crashed", expected = "󰅖" },
	{ state = "unavailable", expected = "󰅖" },
	{ state = "unknown", expected = "󰅖" },
}

print("--- status_icon ---")
for _, tc in ipairs(icon_tests) do
	local result = status.status_icon(tc.state)
	if result == tc.expected then
		pass(string.format("status_icon(%q) = %s", tc.state, result))
	else
		fail(string.format("status_icon(%q) expected %s, got %s", tc.state, tc.expected, result))
	end
end

-- status_color
local color_tests = {
	{ state = "running", expected = "#a6da95" },
	{ state = "active", expected = "#a6da95" },
	{ state = "available", expected = "#a6da95" },
	{ state = "stopped", expected = nil },
	{ state = "inactive", expected = nil },
	{ state = "crashed", expected = "#ed8796" },
	{ state = "unavailable", expected = "#ed8796" },
	{ state = "unknown", expected = "#ed8796" },
}

print("--- status_color ---")
	for _, tc in ipairs(color_tests) do
		local result = status.status_color(tc.state)
		if result == tc.expected then
			pass(string.format("status_color(%q) = %s", tc.state, result or "nil"))
		else
			fail(string.format("status_color(%q) expected %s, got %s", tc.state, tc.expected or "nil", result or "nil"))
		end
	end

-- display returns "" for non-mojo buffers
print("--- display ---")
local d = status.display()
if d == "" then
	pass("display() returns '' for non-mojo buffer")
else
	fail(string.format("display() expected '', got %q", d))
end

-- display returns non-empty for mojo buffer
local buf = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "fn main():" })
vim.bo[buf].filetype = "mojo"
vim.api.nvim_set_current_buf(buf)

d = status.display()
if d ~= "" then
	pass("display() returns content for mojo buffer")
else
	fail("display() returned '' for mojo buffer")
end

vim.api.nvim_buf_delete(buf, { force = true })

-- lsp_status returns "unavailable" without a running LSP client
print("--- lsp_status ---")
local ls = status.lsp_status()
if ls == "unavailable" then
	pass("lsp_status() = unavailable (no LSP client)")
else
	fail(string.format("lsp_status() expected 'unavailable', got %q", ls))
end

-- dbg_status reflects debug availability (deterministic via mocked debug module)
print("--- dbg_status ---")
local debug_mock = { status = function() end }
package.loaded["mojo.debug"] = debug_mock

debug_mock.status = function()
	return { native = false, dap = false, active = nil }
end
local ds = status.dbg_status()
if ds == "unavailable" then
	pass("dbg_status() = unavailable (no debug binaries)")
else
	fail(string.format("dbg_status() expected 'unavailable', got %q", ds))
end

debug_mock.status = function()
	return { native = true, dap = false, active = nil }
end
ds = status.dbg_status()
if ds == "inactive" then
	pass("dbg_status() = inactive (native binaries present)")
else
	fail(string.format("dbg_status() expected 'inactive', got %q", ds))
end

debug_mock.status = function()
	return { native = true, dap = false, active = "native" }
end
ds = status.dbg_status()
if ds == "active" then
	pass("dbg_status() = active (native session)")
else
	fail(string.format("dbg_status() expected 'active', got %q", ds))
end

debug_mock.status = function()
	return { native = false, dap = true, active = "dap" }
end
ds = status.dbg_status()
if ds == "inactive" then
	pass("dbg_status() = inactive (dap selected, no active session)")
else
	fail(string.format("dbg_status() expected 'inactive', got %q", ds))
end

debug_mock.status = function()
	return { native = false, dap = false, active = "dap" }
end
ds = status.dbg_status()
if ds == "inactive" then
	pass("dbg_status() = inactive (dap selected, no binary)")
else
	fail(string.format("dbg_status() expected 'inactive', got %q", ds))
end

package.loaded["mojo.debug"] = nil

-- fmt_status returns "unavailable" without mojo binary
print("--- fmt_status ---")
local fs = status.fmt_status()
if fs == "unavailable" then
	pass("fmt_status() = unavailable (no mojo binary)")
else
	fail(string.format("fmt_status() expected 'unavailable', got %q", fs))
end

-- Clear Cache action passes -f and timeout, guards version < 1.0.0b2
print("--- Clear Cache action ---")
do
	local env = require("mojo.env")
	local version = require("mojo.env.version")
	local orig_mojo = env.get_mojo_cmd
	local orig_confirm = vim.fn.confirm
	local orig_system = vim.system
	local orig_version = version.get_version
	local calls = {}

	env.get_mojo_cmd = function()
		return "/bin/mojo"
	end
	vim.fn.confirm = function()
		return 1 -- Yes
	end
	vim.system = function(cmd, opts)
		table.insert(calls, { cmd = cmd, opts = opts })
		return { wait = function()
			return { code = 0, stdout = "", stderr = "" }
		end }
	end

	-- Case 1: version >= 1.0.0b2 (stable 1.0.0 allowed) -> runs with -f + timeout
	version.get_version = function()
		return "1.0.0"
	end
	calls = {}
	status.actions["Clear Cache"]()
	if #calls == 1 then
		local c = calls[1]
		local has_f = false
		local has_clear = false
		for _, a in ipairs(c.cmd) do
			if a == "-f" then
				has_f = true
			end
			if a == "--clear-cache" then
				has_clear = true
			end
		end
		if has_f and has_clear then
			pass("Clear Cache passes --clear-cache with -f")
		else
			fail("Clear Cache missing -f or --clear-cache: " .. vim.inspect(c.cmd))
		end
		if type(c.opts.timeout) == "number" then
			pass("Clear Cache sets a numeric wait timeout")
		else
			fail("Clear Cache missing timeout in vim.system opts: " .. vim.inspect(c.opts))
		end
	else
		fail("Clear Cache should run mojo once (got " .. #calls .. " calls)")
	end

	-- Case 2: version < 1.0.0b2 (1.0.0b1) -> blocked, no command issued
	version.get_version = function()
		return "1.0.0b1"
	end
	calls = {}
	status.actions["Clear Cache"]()
	if #calls == 0 then
		pass("Clear Cache blocked for Mojo < 1.0.0b2")
	else
		fail("Clear Cache should NOT run on 1.0.0b1 (got " .. #calls .. " calls)")
	end

	env.get_mojo_cmd = orig_mojo
	vim.fn.confirm = orig_confirm
	vim.system = orig_system
	version.get_version = orig_version
end

-- show_menu computes width from items (not hardcoded 20)
print("--- show_menu width ---")
do
	local orig_open = vim.api.nvim_open_win
	local orig_keymap = vim.api.nvim_buf_set_keymap
	local orig_lines = vim.api.nvim_buf_set_lines
	local opened = nil
	local keymap_calls = {}

	vim.api.nvim_open_win = function(_, _, opts)
		opened = opts
		return 1000
	end
	vim.api.nvim_buf_set_keymap = function(_, mode, lhs, rhs, opts)
		table.insert(keymap_calls, { mode = mode, lhs = lhs, rhs = rhs, opts = opts })
	end
	vim.api.nvim_buf_set_lines = function() end

	status.show_menu()

	vim.api.nvim_open_win = orig_open
	vim.api.nvim_buf_set_keymap = orig_keymap
	vim.api.nvim_buf_set_lines = orig_lines

	-- Longest item: "   [1] Cache Location" = 21 chars; menu must fit it
	if opened and opened.width and opened.width >= 21 then
		pass("show_menu width computed from items (" .. opened.width .. ")")
	else
		fail("show_menu width too small: " .. (opened and tostring(opened.width) or "nil"))
	end
end

-- Summary
print(string.rep("=", 60))
print(string.format("Total failures: %d", total_errors))
if total_errors > 0 then
	vim.cmd(string.format("cq %d", math.min(total_errors, 255)))
else
	vim.cmd("cq 0")
end
