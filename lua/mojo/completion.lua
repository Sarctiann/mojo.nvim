local M = {}

--- @class Mojo-lang.CompletionItem
--- @field label string
--- @field kind integer vim.lsp.protocol.CompletionItemKind
--- @field detail string|nil

--- Mojo declaration keywords (anonymous tokens in the grammar).
--- @type string[]
M.keywords = {
	-- Python-compatible
	"as",
	"assert",
	"async",
	"await",
	"break",
	"class",
	"continue",
	"def",
	"del",
	"elif",
	"else",
	"except",
	"finally",
	"for",
	"from",
	"global",
	"if",
	"import",
	"in",
	"is",
	"lambda",
	"nonlocal",
	"not",
	"or",
	"and",
	"pass",
	"raise",
	"return",
	"try",
	"while",
	"with",
	"yield",
	"match",
	"case",
	"exec",
	-- Mojo-specific
	"fn",
	"struct",
	"trait",
	"var",
	"alias",
	"comptime",
	"raises",
	"thin",
	"register_passable",
	"borrowed",
	"inout",
	"mut",
	"read",
	"ref",
	"out",
	"deinit",
	"self",
	"Self",
	"True",
	"False",
	"None",
}

--- Audited against Mojo stdlib tag mojo/v1.0.0b1 (std/prelude/__init__.mojo).
--- Python-only names dropped; capitalized types go in M.types.
--- @type string[]
M.builtins = {
	"abort",
	"abs",
	"all",
	"any",
	"ascii",
	"atof",
	"atol",
	"bin",
	"breakpoint",
	"chr",
	"constrained",
	"debug_assert",
	"divmod",
	"enumerate",
	"external_call",
	"hash",
	"hex",
	"input",
	"iter",
	"len",
	"map",
	"materialize",
	"max",
	"min",
	"next",
	"oct",
	"open",
	"ord",
	"partition",
	"pow",
	"print",
	"range",
	"rebind",
	"rebind_var",
	"reflect",
	"repr",
	"reversed",
	"round",
	"slice",
	"sort",
	"swap",
	"zip",
}

--- Mojo standard-library types (capitalized, match @constructor highlight).
--- @type string[]
M.types = {
	"Bool",
	"Int",
	"Int8",
	"Int16",
	"Int32",
	"Int64",
	"UInt8",
	"UInt16",
	"UInt32",
	"UInt64",
	"Float16",
	"Float32",
	"Float64",
	"String",
	"List",
	"Dict",
	"Set",
	"Tuple",
	"Option",
	"Result",
	"Error",
	"Regex",
	"Path",
	"File",
	"SIMD",
	"DType",
	"Address",
	"Pointer",
	"Reference",
	"Span",
	"Vector",
	"DynamicVector",
	"StringSlice",
	"StringRef",
}

--- @class Mojo-lang.Snippet
--- @field trigger string
--- @field body string
--- @field description string

--- @type Mojo-lang.Snippet[]
M.snippets = {
	{ trigger = "fn", body = "fn ${1:name}(${2})$3 -> ${4:Type}:\n\t$0", description = "fn definition with return type" },
	{ trigger = "sfn", body = "fn ${1:name}(${2})${3}:\n\t$0", description = "fn definition without return type" },
	{ trigger = "struct", body = "struct ${1:Name}:\n\t$0", description = "struct definition" },
	{ trigger = "trait", body = "trait ${1:Name}:\n\t$0", description = "trait definition" },
	{ trigger = "vdef", body = "var ${1:name}: ${2:Type} = ${3:value}", description = "var definition" },
	{ trigger = "ldef", body = "let ${1:name}: ${2:Type} = ${3:value}", description = "let definition" },
	{ trigger = "alias", body = "alias ${1:Name} = ${2:Type}", description = "alias declaration" },
	{ trigger = "ifl", body = "if ${1:cond}:\n\t$0", description = "if block" },
	{ trigger = "elfl", body = "elif ${1:cond}:\n\t$0", description = "elif block" },
	{ trigger = "ell", body = "else:\n\t$0", description = "else block" },
	{ trigger = "forl", body = "for ${1:x} in ${2:range}:\n\t$0", description = "for loop" },
	{ trigger = "wl", body = "while ${1:cond}:\n\t$0", description = "while loop" },
	{ trigger = "tc", body = "try:\n\t$0\nexcept ${1:Error}:\n\t${2:pass}", description = "try/except block" },
}

local KWORD = 14
local FUNC = 3
local CLASS = 7
local SNIP = 15

--- @return Mojo-lang.CompletionItem[]
function M.all_items()
	local items = {} --- @type Mojo-lang.CompletionItem[]

	for _, kw in ipairs(M.keywords) do
		table.insert(items, { label = kw, kind = KWORD, detail = "keyword" })
	end

	for _, fn in ipairs(M.builtins) do
		table.insert(items, { label = fn, kind = FUNC, detail = "builtin" })
	end

	for _, ty in ipairs(M.types) do
		table.insert(items, { label = ty, kind = CLASS, detail = "type" })
	end

	for _, sn in ipairs(M.snippets) do
		table.insert(items, { label = sn.trigger, kind = SNIP, detail = sn.description })
	end

	return items
end

return M