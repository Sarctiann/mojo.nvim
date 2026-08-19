-- test_commands.lua
-- Run: nvim --headless -c "luafile tests/test_commands.lua" -c "qa!"

local total_errors = 0

local function fail(msg)
	print("  FAIL: " .. msg)
	total_errors = total_errors + 1
end

local function pass(msg)
	print("  PASS: " .. msg)
end

local mojo = require("mojo")
mojo.setup({ verbose = false, commands = { master = true, spread = true } })

local commands = { "Mojo", "MojoRefreshSDK", "MojoRestartLSP", "MojoStopLSP", "MojoMenu", "MojoDebug", "MojoDebugNative", "MojoDebugDap", "MojoRebuildParser", "MojoCacheLocation", "MojoClearCache" }
for _, name in ipairs(commands) do
	if vim.fn.exists(":" .. name) == 2 then
		pass(":" .. name .. " command exists")
	else
		fail(":" .. name .. " command not found")
	end
end

print(string.rep("=", 60))
print(string.format("Total failures: %d", total_errors))
if total_errors > 0 then
	vim.cmd(string.format("cq %d", math.min(total_errors, 255)))
else
	vim.cmd("cq 0")
end
