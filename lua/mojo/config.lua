--- @class Mojo-lang.FiletypeConfig
--- @field enabled boolean|nil

--- @class Mojo-lang.TerminalConfig
--- @field enabled boolean|nil
--- @field auto_activate boolean|nil
--- @field delay_ms number|nil

--- @class Mojo-lang.TreesitterConfig
--- @field enabled boolean|nil
--- @field adapter (fun(opts: Mojo-lang.TreesitterConfig): boolean)|nil

--- @class Mojo-lang.LspConfig
--- @field enabled boolean|nil
--- @field root_markers string[]|nil

--- @class Mojo-lang.FormatConfig
--- @field enabled boolean|nil
--- @field formatter_name string|nil

--- @class Mojo-lang.Hooks
--- @field resolve_root (fun(path: string|nil, markers: string[]|nil): string|nil)|nil

--- @class Mojo-lang.Config
--- @field filetype Mojo-lang.FiletypeConfig|nil
--- @field terminal Mojo-lang.TerminalConfig|nil
--- @field treesitter Mojo-lang.TreesitterConfig|nil
--- @field lsp Mojo-lang.LspConfig|nil
--- @field format Mojo-lang.FormatConfig|nil
--- @field debug boolean|nil
--- @field hooks Mojo-lang.Hooks|nil

local M = {}

--- @type Mojo-lang.Config
M.defaults = {
	filetype = { enabled = true },
	terminal = {
		enabled = true,
		auto_activate = true,
		delay_ms = 200,
	},
	treesitter = {
		enabled = true,
	},
	lsp = {
		enabled = false,
		root_markers = { "pixi.toml", "pyproject.toml", ".pixi", ".venv" },
	},
	format = {
		enabled = false,
		formatter_name = "mojo",
	},
	debug = false,
	hooks = {},
}

--- @type Mojo-lang.Config
M.options = {}

--- @param user_config Mojo-lang.Config|nil
--- @return Mojo-lang.Config
function M.setup(user_config)
	M.options = vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), user_config or {})
	return M.options
end

return M
