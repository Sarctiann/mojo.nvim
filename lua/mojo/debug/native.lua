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

--- @type boolean  Whether the active native LLDB supports Python scripting.
local native_supports_script = false

--- Whether the LLDB binary supports the embedded Python script interpreter.
--- Mojo's `mojo-lldb` is frequently built without scripting support, so data
--- formatters cannot be imported (and attempting it only produces noise).
--- @param bin string|nil
--- @return boolean
local function lldb_supports_scripting(bin)
	if not bin or bin == "" then
		return false
	end
	local ok, handle = pcall(vim.system, { bin, "--batch", "-o", "script pass" }, { text = true, timeout = 10000 })
	if not ok or not handle then
		return false
	end
	local result = handle:wait()
	local out = (result.stdout or "") .. "\n" .. (result.stderr or "")
	if out:find("script interpreter unavailable") or out:find("without scripting language support") then
		return false
	end
	return true
end

--- Choose the LLDB binary for the native (terminal) debug session.
--- Prefers the environment's `mojo-lldb`; if that build lacks a Python
--- scripting interpreter (Mojo's bundled `mojo-lldb` frequently does), fall
--- back to a system `lldb` that supports scripting so Mojo data formatters
--- can still be loaded. If no scripting-capable binary exists, returns the
--- primary `mojo-lldb` (formatters are then skipped gracefully).
--- @return string|nil, boolean  (bin, supports_script)
function M.pick_native_lldb()
	local env = require("mojo.env")
	local primary = env.get_dbg_native_cmd()
	if primary and lldb_supports_scripting(primary) then
		return primary, true
	end
	-- Falling back to a generic system lldb trades away Mojo type visualization
	-- (no libMojoLLDB); only do so when the user opts in.
	if config.options.debug.use_system_lldb then
		local sys = vim.fn.exepath("lldb")
		if sys and sys ~= "" and lldb_supports_scripting(sys) then
			vim.notify(
				"mojo.nvim: mojo-lldb lacks Python scripting; using " .. sys .. " so data formatters load",
				vim.log.levels.INFO
			)
			return sys, true
		end
	end
	return primary, false
end

--- Attempt to import a Mojo LLDB formatter script.
--- Sent as a plain LLDB `command script import` (the native LLDB binary has
--- already been selected to support Python scripting, so this succeeds).
--- @param path string
function M._import_formatter(path)
	M.send('command script import "' .. path .. '"')
end

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

	-- Choose the native LLDB binary. Prefers the environment's mojo-lldb, but
	-- falls back to a system lldb with Python scripting so Mojo data formatters
	-- can load (Mojo's bundled mojo-lldb is often built without scripting).
	-- pick_native_lldb also returns the scripting flag, avoiding a second probe.
	local lldb_bin, supports_script = M.pick_native_lldb()
	if not lldb_bin then
		vim.notify("mojo.nvim: mojo-lldb not found — cannot start native debug", vim.log.levels.ERROR)
		return
	end
	native_supports_script = supports_script

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
		if not M.is_active() then
			timer:stop()
			timer:close()
			return
		end
		if elapsed > 50 then
			timer:stop()
			timer:close()
			M._on_prompt_timeout()
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
			-- Match the standalone prompt only (a line that is just `(lldb)`),
			-- not e.g. `(lldb) target create "..."`, so the plugin/formatters are
			-- loaded once the session is actually ready rather than mid-target-create.
			if line:match("^%s*%(lldb%)%s*$") then
				timer:stop()
				timer:close()
				M._on_prompt()
				return
			end
		end
	end))
end

--- Test seam for the scripting-support flag (kept private otherwise).
--- @param v boolean
function M._set_supports_script(v)
	native_supports_script = v
end

--- Handle the `(lldb)` prompt: load the Mojo LLDB plugin (primary, since that
--- is what actually visualizes Mojo values) and, only when the LLDB build
--- supports Python scripting, import the two `.py` data formatters as
--- best-effort extras, then sync breakpoints.
function M._on_prompt()
	local detected = require("mojo.env.detect").detect()
	local visualizers, plugin = require("mojo.adapters.dap").find_visualizers(detected)
	-- libMojoLLDB is what visualizes Mojo values; load it whenever present.
	if plugin then
		M.send('plugin load "' .. plugin .. '"')
	end
	-- The .py formatters only pretty-print compiler C++ internals and need a
	-- Python-scripting LLDB; import them only when supported.
	if native_supports_script and visualizers then
		M._import_formatter(vim.fs.joinpath(visualizers, "lldbDataFormatters.py"))
		M._import_formatter(vim.fs.joinpath(visualizers, "mlirDataFormatters.py"))
	end
	require("mojo.debug.breakpoints").sync_all()
end

--- Handle the case where the `(lldb)` prompt never appears within the wait
--- window: breakpoints were never synced, so tell the user.
function M._on_prompt_timeout()
	vim.notify(
		"mojo.nvim: LLDB prompt not detected; breakpoints were not synced",
		vim.log.levels.WARN
	)
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
