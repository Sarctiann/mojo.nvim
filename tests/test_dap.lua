-- test_dap.lua
-- Run: nvim --headless -c "luafile tests/test_dap.lua" -c "qa!"

local total_errors = 0

local function fail(msg)
	print("  FAIL: " .. msg)
	total_errors = total_errors + 1
end

local function pass(msg)
	print("  PASS: " .. msg)
end

local dap = require("mojo.adapters.dap")

-- Ensure config defaults (incl. debug.search_for) are populated so binary
-- discovery works the same way it does at real plugin init.
require("mojo.config").setup({})

-- Build a fake pixi-style env with lib/lldb-visualizers and the Mojo LLDB plugin
local env_dir = vim.fn.tempname()
os.execute("mkdir -p " .. env_dir .. "/lib/lldb-visualizers")
os.execute("touch " .. env_dir .. "/lib/lldb-visualizers/lldbDataFormatters.py")
os.execute("touch " .. env_dir .. "/lib/lldb-visualizers/mlirDataFormatters.py")
os.execute("touch " .. env_dir .. "/lib/libMojoLLDB.dylib")

local detected = {
	type = "pixi",
	env_dir = env_dir,
	bin_dir = vim.fs.joinpath(env_dir, "bin"),
}

local visualizers, plugin = dap.find_visualizers(detected)
if visualizers and vim.uv.fs_stat(visualizers) then
	pass("find_visualizers() finds lib/lldb-visualizers in env_dir")
else
	fail("find_visualizers() did not find visualizers for pixi env")
end

if plugin and vim.uv.fs_stat(plugin) then
	pass("find_visualizers() finds libMojoLLDB plugin")
else
	fail("find_visualizers() did not find Mojo LLDB plugin")
end

-- venv-style: site-packages/modular/lib/lldb-visualizers
local venv_dir = vim.fn.tempname()
local mod_lib = venv_dir .. "/lib/python3.12/site-packages/modular/lib"
os.execute("mkdir -p " .. mod_lib .. "/lldb-visualizers")
os.execute("touch " .. mod_lib .. "/lldb-visualizers/lldbDataFormatters.py")
os.execute("touch " .. mod_lib .. "/lldb-visualizers/mlirDataFormatters.py")
os.execute("touch " .. mod_lib .. "/libMojoLLDB.so")

local venv_detected = {
	type = "venv",
	env_dir = venv_dir,
	bin_dir = venv_dir .. "/bin",
}

local v_vis, v_plugin = dap.find_visualizers(venv_detected)
if v_vis and vim.uv.fs_stat(v_vis) then
	pass("find_visualizers() finds site-packages/modular/lib visualizers")
else
	fail("find_visualizers() did not find visualizers for venv env")
end

-- No visualizers present
local empty_dir = vim.fn.tempname()
os.execute("mkdir -p " .. empty_dir .. "/bin")
local empty_detected = {
	type = "pixi",
	env_dir = empty_dir,
	bin_dir = empty_dir .. "/bin",
}
local e_vis, e_plugin = dap.find_visualizers(empty_detected)
if e_vis == nil and e_plugin == nil then
	pass("find_visualizers() returns nil when no visualizers exist")
else
	fail("find_visualizers() should return nil for empty env")
end

-- build_args propagation (#8): verify `mojo build` receives config.debug.build_args
do
	local tmp = vim.fn.tempname()
	os.execute("mkdir -p " .. tmp)
	local orig_cwd = vim.fn.getcwd()
	vim.api.nvim_set_current_dir(tmp)

	local captured_calls = {}
	local orig_system = vim.fn.system
	local orig_expand = vim.fn.expand
	local orig_mkdir = vim.fn.mkdir
	-- prime shell_error to 0 via a real no-op call (vim.v.shell_error is read-only)
	vim.fn.system("true")
	vim.fn.system = function(cmd)
		table.insert(captured_calls, cmd)
		return ""
	end
	vim.fn.expand = function(_)
		return vim.fs.joinpath(tmp, "foo.mojo")
	end
	vim.fn.mkdir = function()
		return 1
	end

	local env = require("mojo.env")
	local orig_get = env.get_mojo_cmd
	env.get_mojo_cmd = function()
		return "mojo"
	end

	local config = require("mojo.config")
	config.options.debug.build_args = { "--flag", "value" }

	local bin = dap.build()

	-- restore
	config.options.debug.build_args = nil
	env.get_mojo_cmd = orig_get
	vim.fn.system = orig_system
	vim.fn.expand = orig_expand
	vim.fn.mkdir = orig_mkdir
	vim.api.nvim_set_current_dir(orig_cwd)
	os.execute("rm -rf " .. tmp)

	local found = false
	for _, call in ipairs(captured_calls) do
		if type(call) == "table" and vim.tbl_contains(call, "--flag") and vim.tbl_contains(call, "value") then
			found = true
			break
		end
	end
	if bin and found then
		pass("build_args propagated to mojo build command")
	else
		fail(string.format("build_args not propagated (bin=%s, calls=%s)", bin, vim.inspect(captured_calls)))
	end
end

-- DAP adapter loads formatter pre-init-commands (#9 DAP side)
do
	local env_dir = vim.fn.tempname()
	os.execute("mkdir -p " .. env_dir .. "/lib/lldb-visualizers")
	os.execute("touch " .. env_dir .. "/lib/lldb-visualizers/lldbDataFormatters.py")
	os.execute("touch " .. env_dir .. "/lib/lldb-visualizers/mlirDataFormatters.py")
	os.execute("touch " .. env_dir .. "/lib/libMojoLLDB.dylib")
	os.execute("mkdir -p " .. env_dir .. "/bin")
	os.execute("touch " .. env_dir .. "/bin/lldb-dap")

	package.loaded["dap"] = { adapters = {}, configurations = {} }
	local env = require("mojo.env")
	local orig_dap = env.get_dap_cmd
	env.get_dap_cmd = function()
		return { "mojo-lldb-dap" }, env_dir
	end
	local detect = require("mojo.env.detect")
	local orig_detect = detect.detect
	detect.detect = function()
		return { type = "pixi", env_dir = env_dir, bin_dir = env_dir .. "/bin" }
	end

	local ok_setup = dap.setup({ enabled = true })
	local captured = nil
	local adapter_fn = package.loaded["dap"].adapters["mojo-lldb"]
	if adapter_fn then
		adapter_fn(function(cfg)
			captured = cfg
		end, nil)
	end

	env.get_dap_cmd = orig_dap
	detect.detect = orig_detect
	os.execute("rm -rf " .. env_dir)

	if captured and captured.args then
		local joined = table.concat(captured.args, " ")
		if
			joined:find("lldbDataFormatters%.py")
			and joined:find("mlirDataFormatters%.py")
			and joined:find("?command script import")
			and joined:find("?!plugin load")
		then
			pass("DAP adapter loads plugin (?!plugin load) + formatter pre-init (?command script import)")
		else
			fail("DAP adapter missing prefixed commands: " .. joined)
		end
	else
		fail(
			string.format(
				"DAP adapter did not build config (setup=%s, captured=%s)",
				tostring(ok_setup),
				vim.inspect(captured)
			)
		)
	end
end

-- DAP adapter prefers real _mojo-lldb-dap over the broken mojo-lldb-dap wrapper (pixi)
do
	local env_dir = vim.fn.tempname()
	os.execute("mkdir -p " .. env_dir .. "/lib/lldb-visualizers")
	os.execute("touch " .. env_dir .. "/lib/lldb-visualizers/lldbDataFormatters.py")
	os.execute("touch " .. env_dir .. "/lib/lldb-visualizers/mlirDataFormatters.py")
	os.execute("touch " .. env_dir .. "/lib/libMojoLLDB.dylib")
	os.execute("mkdir -p " .. env_dir .. "/bin")
	os.execute("touch " .. env_dir .. "/bin/_mojo-lldb-dap")

	package.loaded["dap"] = { adapters = {}, configurations = {} }
	local env = require("mojo.env")
	local orig_dap = env.get_dap_cmd
	env.get_dap_cmd = function()
		return { "mojo-lldb-dap" }, env_dir
	end
	local detect = require("mojo.env.detect")
	local orig_detect = detect.detect
	detect.detect = function()
		return { type = "pixi", env_dir = env_dir, bin_dir = env_dir .. "/bin" }
	end

	local ok_setup = dap.setup({ enabled = true })
	local captured = nil
	local adapter_fn = package.loaded["dap"].adapters["mojo-lldb"]
	if adapter_fn then
		adapter_fn(function(cfg)
			captured = cfg
		end, nil)
	end

	env.get_dap_cmd = orig_dap
	detect.detect = orig_detect
	os.execute("rm -rf " .. env_dir)

	if captured and captured.command == env_dir .. "/bin/_mojo-lldb-dap" and captured.args then
		local joined = table.concat(captured.args, " ")
		if
			joined:find("?command script import")
			and joined:find("?!plugin load")
		then
			pass("DAP pixi uses _mojo-lldb-dap directly with ?!plugin load + ?formatter pre-init")
		else
			fail("DAP pixi missing prefixed commands: " .. joined)
		end
	else
		fail(
			string.format(
				"DAP pixi did not resolve _mojo-lldb-dap (setup=%s, command=%s)",
				tostring(ok_setup),
				captured and captured.command or "nil"
			)
		)
	end
end

-- DAP adapter: when the Mojo plugin is missing but visualizers exist, do NOT
-- set MODULAR_MOJO_MAX_LLDB_PLUGIN_PATH and do NOT emit plugin load; still emit
-- the two ?command script import commands.
do
	local env_dir = vim.fn.tempname()
	os.execute("mkdir -p " .. env_dir .. "/lib/lldb-visualizers")
	os.execute("touch " .. env_dir .. "/lib/lldb-visualizers/lldbDataFormatters.py")
	os.execute("touch " .. env_dir .. "/lib/lldb-visualizers/mlirDataFormatters.py")
	os.execute("mkdir -p " .. env_dir .. "/bin")
	os.execute("touch " .. env_dir .. "/bin/lldb-dap")

	package.loaded["dap"] = { adapters = {}, configurations = {} }
	local env = require("mojo.env")
	local orig_dap = env.get_dap_cmd
	env.get_dap_cmd = function()
		return { "mojo-lldb-dap" }, env_dir
	end
	local detect = require("mojo.env.detect")
	local orig_detect = detect.detect
	detect.detect = function()
		return { type = "pixi", env_dir = env_dir, bin_dir = env_dir .. "/bin" }
	end

	dap.setup({ enabled = true })
	local captured = nil
	local adapter_fn = package.loaded["dap"].adapters["mojo-lldb"]
	if adapter_fn then
		adapter_fn(function(cfg)
			captured = cfg
		end, nil)
	end

	env.get_dap_cmd = orig_dap
	detect.detect = orig_detect
	os.execute("rm -rf " .. env_dir)

	if captured and captured.args then
		local joined = table.concat(captured.args, " ")
		local no_plugin_load = not joined:find("plugin load")
		local has_formatters = joined:find("?command script import") ~= nil
		local no_plugin_env = not (captured.options.env.MODULAR_MOJO_MAX_LLDB_PLUGIN_PATH)
		if no_plugin_load and has_formatters and no_plugin_env then
			pass("DAP with no plugin omits plugin load + plugin env var, keeps ?formatter imports")
		else
			fail(
				string.format(
					"DAP no-plugin case wrong (plugin_load=%s, formatters=%s, plugin_env=%s): %s",
					tostring(no_plugin_load),
					tostring(has_formatters),
					tostring(no_plugin_env),
					joined
				)
			)
		end
	else
		fail("DAP no-plugin case did not build config: " .. vim.inspect(captured))
	end
end

-- Native fallback: when mojo-lldb lacks Python scripting, prefer a system lldb;
-- pick_native_lldb returns (bin, supports_script) and the probe uses a timeout.
do
	local native = require("mojo.debug.native")
	local env = require("mojo.env")
	local orig_get = env.get_dbg_native_cmd
	local orig_exepath = vim.fn.exepath
	local orig_system = vim.system
	local probe_opts = nil

	-- mojo-lldb: no scripting; system lldb: has scripting
	env.get_dbg_native_cmd = function()
		return "/env/bin/mojo-lldb"
	end
	vim.fn.exepath = function(name)
		if name == "lldb" then
			return "/usr/bin/lldb"
		end
		return ""
	end
	vim.system = function(args, opts)
		probe_opts = opts
		local bin = args[1]
		local stderr = bin:match("mojo%-lldb") and "Embedded script interpreter unavailable" or ""
		return { wait = function()
			return { stdout = "", stderr = stderr }
		end }
	end

	local chosen, supports = native.pick_native_lldb()
	if chosen == "/usr/bin/lldb" and supports == true then
		pass("pick_native_lldb falls back to system lldb + returns scripting=true")
	else
		fail(
			string.format(
				"pick_native_lldb returned %s/%s (expected /usr/bin/lldb/true)",
				tostring(chosen),
				tostring(supports)
			)
		)
	end
	if type(probe_opts) == "table" and type(probe_opts.timeout) == "number" then
		pass("pick_native_lldb probe sets a numeric timeout")
	else
		fail("pick_native_lldb probe missing timeout: " .. vim.inspect(probe_opts))
	end

	-- mojo-lldb with scripting: prefer it
	vim.system = function(_, opts)
		probe_opts = opts
		return { wait = function()
			return { stdout = "", stderr = "" }
		end }
	end
	local chosen2, supports2 = native.pick_native_lldb()
	if chosen2 == "/env/bin/mojo-lldb" and supports2 == true then
		pass("pick_native_lldb prefers mojo-lldb + returns scripting=true")
	else
		fail(
			string.format(
				"pick_native_lldb returned %s/%s (expected /env/bin/mojo-lldb/true)",
				tostring(chosen2),
				tostring(supports2)
			)
		)
	end

	-- neither supports scripting: returns primary with scripting=false
	vim.system = function()
		return { wait = function()
			return { stdout = "", stderr = "Embedded script interpreter unavailable" }
		end }
	end
	vim.fn.exepath = function()
		return ""
	end
	local chosen3, supports3 = native.pick_native_lldb()
	if chosen3 == "/env/bin/mojo-lldb" and supports3 == false then
		pass("pick_native_lldb returns primary + scripting=false when nothing supports scripting")
	else
		fail(
			string.format(
				"pick_native_lldb returned %s/%s (expected /env/bin/mojo-lldb/false)",
				tostring(chosen3),
				tostring(supports3)
			)
		)
	end

	env.get_dbg_native_cmd = orig_get
	vim.fn.exepath = orig_exepath
	vim.system = orig_system
end

-- _import_formatter must emit a valid LLDB command (no broken Python one-liner)
do
	local native = require("mojo.debug.native")
	local captured = {}
	native.send = function(cmd)
		table.insert(captured, cmd)
	end
	native._import_formatter("/x/lib/lldb-visualizers/lldbDataFormatters.py")
	if captured[1] == 'command script import "/x/lib/lldb-visualizers/lldbDataFormatters.py"' then
		pass("_import_formatter emits a valid LLDB command script import")
	else
		fail("unexpected formatter command: " .. tostring(captured[1]))
	end
end

-- Native _on_prompt: plugin load (libMojoLLDB) is primary; .py formatters are
-- imported only when scripting is supported.
do
	local native = require("mojo.debug.native")
	local captured = {}
	native.send = function(cmd)
		table.insert(captured, cmd)
	end
	local sync_called = 0
	local orig_sync = require("mojo.debug.breakpoints").sync_all
	require("mojo.debug.breakpoints").sync_all = function()
		sync_called = sync_called + 1
	end

	local orig_detect = require("mojo.env.detect").detect
	require("mojo.env.detect").detect = function()
		return { type = "pixi", env_dir = "/env", bin_dir = "/env/bin" }
	end
	local orig_fv = require("mojo.adapters.dap").find_visualizers
	require("mojo.adapters.dap").find_visualizers = function()
		return "/env/lib/lldb-visualizers", "/env/lib/libMojoLLDB.so"
	end

	-- Case 1: scripting supported -> plugin load + both formatter imports
	native._set_supports_script(true)
	captured = {}
	sync_called = 0
	native._on_prompt()
	if
		captured[1] == 'plugin load "/env/lib/libMojoLLDB.so"'
		and captured[2] == 'command script import "/env/lib/lldb-visualizers/lldbDataFormatters.py"'
		and captured[3] == 'command script import "/env/lib/lldb-visualizers/mlirDataFormatters.py"'
		and sync_called == 1
	then
		pass("native _on_prompt loads plugin first, then formatters when scripting")
	else
		fail("native _on_prompt (scripting) unexpected commands: " .. vim.inspect(captured))
	end

	-- Case 2: no scripting -> plugin load still happens, formatters skipped
	native._set_supports_script(false)
	captured = {}
	sync_called = 0
	native._on_prompt()
	if captured[1] == 'plugin load "/env/lib/libMojoLLDB.so"' and #captured == 1 and sync_called == 1 then
		pass("native _on_prompt loads plugin even without scripting, skips formatters")
	else
		fail("native _on_prompt (no scripting) unexpected commands: " .. vim.inspect(captured))
	end

	require("mojo.debug.breakpoints").sync_all = orig_sync
	require("mojo.env.detect").detect = orig_detect
	require("mojo.adapters.dap").find_visualizers = orig_fv
end

-- Integration: real pixi + uv samples must both resolve env, visualizers, native cmd
do	local detect = require("mojo.env.detect")
	local env = require("mojo.env")
	local orig_cwd = vim.fn.getcwd()
	local samples = {
		{ dir = "tests/mojo_samples/test-mojo-pixi", type = "pixi" },
		{ dir = "tests/mojo_samples/test-mojo-uv", type = "venv" },
	}
	for _, spec in ipairs(samples) do
		local full = vim.fs.joinpath(orig_cwd, spec.dir)
		if vim.uv.fs_stat(full) then
			-- clear detect cache so the cwd change re-detects
			for k in pairs(detect._cache()) do
				detect._cache()[k] = nil
			end
			vim.api.nvim_set_current_dir(full)
			local det = detect.detect()
			if det and det.type == spec.type then
				local vis, plugin = dap.find_visualizers(det)
				local native = env.get_dbg_native_cmd()
				if vis and plugin and native then
					pass(string.format("%s: detects %s, resolves visualizers + native cmd", spec.dir, det.type))
				else
					fail(
						string.format(
							"%s: missing visualizers/plugin/native (vis=%s, plugin=%s, native=%s)",
							spec.dir,
							vis,
							plugin,
							native
						)
					)
				end
			else
				fail(string.format("%s: expected type %s, got %s", spec.dir, spec.type, det and det.type or "nil"))
			end
		else
			print("  SKIP: sample not present: " .. spec.dir)
		end
	end
	vim.api.nvim_set_current_dir(orig_cwd)
end

-- Cleanup
os.execute("rm -rf " .. env_dir)
os.execute("rm -rf " .. venv_dir)
os.execute("rm -rf " .. empty_dir)

print(string.rep("=", 60))
print(string.format("Total failures: %d", total_errors))
if total_errors > 0 then
	vim.cmd("cq " .. tostring(total_errors))
end
