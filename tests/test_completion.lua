-- test_completion.lua
-- Run: nvim --headless --cmd "set rtp^=$PWD" -c "luafile tests/test_completion.lua" -c "qa!"

local total_errors = 0

local function fail(msg)
	print("  FAIL: " .. msg)
	total_errors = total_errors + 1
end

local function pass(msg)
	print("  PASS: " .. msg)
end

local completion = require("mojo.completion")

local function has(list, item)
	for _, v in ipairs(list) do
		if v == item then
			return true
		end
	end
	return false
end

local function check_present(list, label, names)
	for _, name in ipairs(names) do
		if has(list, name) then
			pass(label .. " contains " .. name)
		else
			fail(label .. " missing " .. name)
		end
	end
end

local function check_absent(list, label, names)
	for _, name in ipairs(names) do
		if not has(list, name) then
			pass(label .. " does not contain " .. name)
		else
			fail(label .. " should NOT contain " .. name)
		end
	end
end

-- Types: wrongly dropped (still in v1.0.0 prelude)
check_present(completion.types, "types", { "StringSlice", "InlineArray", "UnsafePointer" })

-- Types: do not exist in v1.0.0 stdlib -> must be removed; File -> FileHandle
check_absent(completion.types, "types", {
	"Result",
	"Regex",
	"File",
	"Address",
	"Reference",
	"Vector",
	"DynamicVector",
	"StringRef",
	"CompletionFlag",
	"Deinitable",
})
check_present(completion.types, "types", { "FileHandle" })

-- Keywords: real 1.0.0 keywords missing
check_present(completion.keywords, "keywords", { "where", "abi" })

-- Keywords: stale (zero occurrences in 1.0.4 grammar / v1.0.0 stdlib)
check_absent(completion.keywords, "keywords", { "borrowed", "inout", "exec" })

-- Builtins: need explicit imports (not in prelude) -> removed
check_absent(completion.builtins, "builtins", { "abort", "external_call", "constrained" })

-- Builtins: in prelude but missing -> added
check_present(completion.builtins, "builtins", { "alloc", "index", "trait_downcast" })

-- Snippets: ldef emits `let` which is not in the grammar -> removed
local ldef = nil
for _, s in ipairs(completion.snippets) do
	if s.trigger == "ldef" then
		ldef = s
		break
	end
end
if ldef == nil then
	pass("snippets does not contain ldef (let is not a Mojo keyword)")
else
	fail("snippets should not contain ldef (emits invalid `let`)")
end

-- Snippets: dinit must use the `deinit` convention
local dinit = nil
for _, s in ipairs(completion.snippets) do
	if s.trigger == "dinit" then
		dinit = s
		break
	end
end
if dinit and dinit.body == "def __deinit__(deinit self):\n\t$0" then
	pass("dinit snippet uses def __deinit__(deinit self):")
else
	fail("dinit snippet should be 'def __deinit__(deinit self):', got: " .. tostring(dinit and dinit.body or "nil"))
end

print(string.rep("=", 60))
print(string.format("Total failures: %d", total_errors))
if total_errors > 0 then
	vim.cmd(string.format("cq %d", math.min(total_errors, 255)))
else
	vim.cmd("cq 0")
end
