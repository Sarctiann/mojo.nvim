local M = {}

local function setup_run_terminal()
	local buf = vim.api.nvim_get_current_buf()
	local win = vim.api.nvim_get_current_win()
	vim.bo[buf].buflisted = false
	vim.b[buf].mojo_run = true
	vim.api.nvim_set_hl(0, "MojoRunWinBar", { bg = "#f0903a", fg = "#ffffff" })
	vim.wo[win].winbar = "%#MojoRunWinBar#  Press [q] [Esc] or [Enter] to close this pane  "
	vim.wo[win].winhl = "Normal:NormalFloat"
	vim.wo[win].statusline = " "
	vim.api.nvim_buf_set_keymap(buf, "n", "q", ":close<CR>", { noremap = true, silent = true })
	vim.api.nvim_buf_set_keymap(buf, "n", "<Esc>", ":close<CR>", { noremap = true, silent = true })
	vim.api.nvim_buf_set_keymap(buf, "n", "<CR>", ":close<CR>", { noremap = true, silent = true })
	vim.api.nvim_buf_set_keymap(buf, "t", "q", "<C-\\><C-N>:close<CR>", { noremap = true, silent = true })
	vim.api.nvim_buf_set_keymap(buf, "t", "<Esc>", "<C-\\><C-N>:close<CR>", { noremap = true, silent = true })
	vim.api.nvim_buf_set_keymap(buf, "t", "<CR>", "<C-\\><C-N>:close<CR>", { noremap = true, silent = true })
	vim.api.nvim_create_autocmd("WinEnter", {
		buffer = buf,
		callback = function()
			local cur_win = vim.api.nvim_get_current_win()
			if vim.api.nvim_win_is_valid(cur_win) and vim.api.nvim_win_get_buf(cur_win) == buf then
				vim.wo[cur_win].statusline = " "
			end
		end,
	})
end

local function do_menu()
	require("mojo.status").show_menu()
end

local function do_refresh()
	local detect = require("mojo.env.detect")
	local cache = detect._cache()
	for k in pairs(cache) do
		cache[k] = nil
	end
	require("mojo.status")._reset_lsp_crash()
	require("mojo.env.version").clear_cache()
	vim.notify("mojo.nvim: SDK cache cleared", vim.log.levels.INFO)
end

local function do_restart()
	require("mojo.status").actions["Restart LSP"]()
end

local function do_stop()
	require("mojo.status").actions["Stop LSP"]()
end

local function do_run()
	local file = vim.fn.expand("%:p")
	if vim.bo.filetype ~= "mojo" then
		vim.notify("mojo.nvim: not a Mojo file", vim.log.levels.ERROR)
		return
	end
	local mojo = require("mojo.env").get_mojo_cmd()
	if not mojo then
		vim.notify("mojo.nvim: mojo binary not found", vim.log.levels.ERROR)
		return
	end
	vim.cmd("belowright terminal " .. mojo .. " run " .. vim.fn.shellescape(file))
	setup_run_terminal()
end

local function do_dedicated()
	local file = vim.fn.expand("%:p")
	if vim.bo.filetype ~= "mojo" then
		vim.notify("mojo.nvim: not a Mojo file", vim.log.levels.ERROR)
		return
	end
	local mojo_cmd = require("mojo.env").get_mojo_cmd()
	if not mojo_cmd then
		vim.notify("mojo.nvim: mojo binary not found", vim.log.levels.ERROR)
		return
	end
	local bufname = "mojo-run://" .. file
	local buf = vim.fn.bufnr(bufname)
	if buf > 0 then
		local win = vim.fn.bufwinid(buf)
		if win > 0 then
			vim.api.nvim_set_current_win(win)
		else
			vim.cmd("belowright sbuffer " .. buf)
			setup_run_terminal()
		end
		return
	end
	vim.cmd("belowright terminal " .. mojo_cmd .. " run " .. vim.fn.shellescape(file))
	vim.api.nvim_buf_set_name(vim.api.nvim_get_current_buf(), bufname)
	setup_run_terminal()
end

local function do_debug(backend)
	if vim.bo.filetype ~= "mojo" then
		vim.notify("mojo.nvim: not a Mojo file", vim.log.levels.ERROR)
		return
	end
	require("mojo.debug").start(backend)
end

local function do_rebuild()
	local ts = require("mojo.treesitter")
	if ts.compile_parser() then
		vim.notify("[mojo.nvim] Parser rebuilt.", vim.log.levels.INFO)
		vim.cmd("edit!")
	end
end

local function do_cache_location()
	require("mojo.status").actions["Cache Location"]()
end

local function do_clear_cache()
	require("mojo.status").actions["Clear Cache"]()
end

local function show_keymaps()
	local km = require("mojo.config").options.keymaps or {}
	local sig = km.signature_help or "K"
	local ca = km.code_action or "<leader>ca"
	vim.notify(
		table.concat({
			"mojo.nvim keymaps:",
			("  %-16s Signature help inside parens, hover otherwise"):format(sig),
			("  %-16s Code action"):format(ca),
			"  q, <Esc>, <CR>    Close run terminal",
		}, "\n"),
		vim.log.levels.INFO
	)
end

local function show_help()
	vim.notify(
		table.concat({
			"mojo.nvim subcommands:",
			"  menu       Open floating actions menu",
			"  run        Run current file in terminal split",
			"  dedicated  Run current file in dedicated buffer",
			"  debug         Debug current file (auto-select backend)",
	"  debug-native  Debug current file via mojo-lldb terminal",
	"  debug-dap     Debug current file via nvim-dap (mojo-lldb-dap)",
			"  restart    Restart Mojo LSP server",
			"  stop       Stop Mojo LSP server",
			"  refresh    Clear SDK cache and re-detect",
			"  rebuild    Rebuild tree-sitter parser",
			"  cache-location  Print the Mojo cache location",
			"  clear-cache     Clear the Mojo cache",
			"  keymaps    Show available keymaps",
			"  help       Show this help",
		}, "\n"),
		vim.log.levels.INFO
	)
end

--- @param opts Mojo-lang.Config
function M.setup(opts)
	local cmds = opts.commands or {}

	if cmds.spread then
		vim.api.nvim_create_user_command("MojoMenu", do_menu, { desc = "Open Mojo actions menu" })
		vim.api.nvim_create_user_command(
			"MojoRefreshSDK",
			do_refresh,
			{ desc = "Clear SDK cache and re-detect environment" }
		)
		vim.api.nvim_create_user_command("MojoRestartLSP", do_restart, { desc = "Restart Mojo LSP server" })
		vim.api.nvim_create_user_command("MojoStopLSP", do_stop, { desc = "Stop Mojo LSP server" })
		vim.api.nvim_create_user_command("MojoRun", do_run, { desc = "Run current Mojo file in terminal split" })
		vim.api.nvim_create_user_command(
			"MojoRunDedicated",
			do_dedicated,
			{ desc = "Run current Mojo file in dedicated terminal buffer" }
		)
	vim.api.nvim_create_user_command(
		"MojoDebug",
		function()
			do_debug("auto")
		end,
		{ desc = "Debug current Mojo file (auto-select backend)" }
	)
	vim.api.nvim_create_user_command(
		"MojoDebugNative",
		function()
			do_debug("native")
		end,
		{ desc = "Debug current Mojo file via mojo-lldb terminal" }
	)
	vim.api.nvim_create_user_command(
		"MojoDebugDap",
		function()
			do_debug("dap")
		end,
		{ desc = "Debug current Mojo file via nvim-dap (mojo-lldb-dap)" }
	)
		vim.api.nvim_create_user_command(
			"MojoRebuildParser",
			do_rebuild,
			{ desc = "Rebuild the self-hosted tree-sitter Mojo parser" }
		)
		vim.api.nvim_create_user_command(
			"MojoCacheLocation",
			do_cache_location,
			{ desc = "Print the Mojo cache location" }
		)
		vim.api.nvim_create_user_command(
			"MojoClearCache",
			do_clear_cache,
			{ desc = "Clear the Mojo cache (with confirmation)" }
		)
	end

	if cmds.master then
		local dispatch = {
			menu = do_menu,
			run = do_run,
			dedicated = do_dedicated,
			restart = do_restart,
			stop = do_stop,
			refresh = do_refresh,
			rebuild = do_rebuild,
			["debug"] = function()
			do_debug("auto")
		end,
		["debug-native"] = function()
			do_debug("native")
		end,
		["debug-dap"] = function()
			do_debug("dap")
		end,
		["cache-location"] = do_cache_location,
		["clear-cache"] = do_clear_cache,
		}

		vim.api.nvim_create_user_command("Mojo", function(info)
			local subcommand = vim.trim(info.args)
			if subcommand == "" or subcommand == "help" then
				show_help()
				return
			end

			local fn = dispatch[subcommand]
			if fn then
				fn()
			elseif subcommand == "keymaps" then
				show_keymaps()
			else
				vim.notify(
					"mojo.nvim: unknown subcommand '" .. subcommand .. "'. See ':Mojo help'",
					vim.log.levels.ERROR
				)
			end
		end, {
			nargs = "?",
			complete = function(ArgLead)
				local all =
					{ "menu", "run", "dedicated", "debug", "debug-native", "debug-dap", "restart", "stop", "refresh", "rebuild", "cache-location", "clear-cache", "keymaps", "help" }
				return vim.iter(all)
					:filter(function(s)
						return s:find(ArgLead) ~= nil
					end)
					:totable()
			end,
			desc = "Mojo plugin master command",
		})
	end
end

return M
