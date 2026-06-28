--- @class Mojo-lang.DetectedEnv
--- @field type "pixi"|"venv"|"manual"|"derived"
--- @field root string
--- @field env_name string|nil
--- @field env_dir string|nil
--- @field bin_dir string|nil
--- @field activate_cmd string|nil

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
--- @field include_dirs string[]|nil
--- @field filter_docstring_diagnostics boolean|nil
--- @field adapter (fun(opts: Mojo-lang.LspConfig): boolean)|nil

--- @class Mojo-lang.FormatConfig
--- @field enabled boolean|nil
--- @field formatter_name string|nil
--- @field adapter (fun(opts: Mojo-lang.FormatConfig): boolean)|nil

--- @class Mojo-lang.CompletionConfig
--- @field enabled boolean|nil
--- @field adapter (fun(opts: Mojo-lang.CompletionConfig): boolean)|nil

--- @class Mojo-lang.DebugBinary
--- @field name string
--- @field role "dap"|"native"

--- @class Mojo-lang.DebugConfig
--- @field enabled boolean|nil
--- @field auto_scroll boolean|nil
--- @field auto_backend "native"|"dap"|nil
--- @field search_for Mojo-lang.DebugBinary[]|nil
--- @field adapter (fun(opts: Mojo-lang.DebugConfig): boolean)|nil

--- @class Mojo-lang.StatuslineConfig
--- @field enabled boolean|nil
--- @field icon string|nil
--- @field show_env_name boolean|nil
--- @field show_sdk_version boolean|nil
--- @field show_lsp boolean|nil
--- @field show_dbg boolean|nil
--- @field show_fmt boolean|nil
--- @field show_diag boolean|nil
--- @field clickable boolean|nil
--- @field colored boolean|nil
--- @field color string|nil
--- @field icon_color string|nil
--- @field adapter (fun(opts: Mojo-lang.StatuslineConfig): boolean)|nil

--- @class Mojo-lang.KeymapsConfig
--- @field enabled boolean|nil
--- @field signature_help string|false|nil
--- @field code_action string|false|nil

--- @class Mojo-lang.CommandsConfig
--- @field master boolean|nil
--- @field spread boolean|nil

--- @class Mojo-lang.Hooks
--- @field resolve_root (fun(path: string|nil, markers: string[]|nil): string|nil)|nil

--- @class Mojo-lang.Config
--- @field filetype Mojo-lang.FiletypeConfig|nil
--- @field terminal Mojo-lang.TerminalConfig|nil
--- @field treesitter Mojo-lang.TreesitterConfig|nil
--- @field lsp Mojo-lang.LspConfig|nil
--- @field format Mojo-lang.FormatConfig|nil
--- @field completion Mojo-lang.CompletionConfig|nil
--- @field keymaps Mojo-lang.KeymapsConfig|nil
--- @field commands Mojo-lang.CommandsConfig|nil
--- @field statusline Mojo-lang.StatuslineConfig|nil
--- @field debug Mojo-lang.DebugConfig|nil
--- @field sdk_path string|nil
--- @field verbose boolean|nil
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
		enabled = true,
		root_markers = { "pixi.toml", "pyproject.toml", ".pixi", ".venv" },
	},
	format = {
		enabled = true,
		formatter_name = "mojo",
	},
	completion = {
		enabled = true,
	},
	statusline = {
		enabled = true,
		icon = "󰈸",
		show_env_name = true,
		show_sdk_version = true,
		show_lsp = true,
		show_dbg = true,
		show_fmt = true,
		show_diag = true,
		clickable = true,
		colored = true,
		color = "#ff9e64",
		icon_color = "#ff6f00",
	},
	keymaps = {
		enabled = true,
		signature_help = "K",
		code_action = "<leader>ca",
	},
	commands = {
		master = true,
		spread = false,
	},
	debug = {
		enabled = true,
		auto_scroll = true,
		auto_backend = nil,
		search_for = {
			{ name = "lldb-dap", role = "dap" },
			{ name = "_mojo-lldb-dap", role = "dap" },
			{ name = "mojo-lldb-dap", role = "dap" },
			{ name = "mojo-lldb", role = "native" },
			{ name = "lldb", role = "native" },
		},
	},
	sdk_path = nil,
	verbose = false,
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
