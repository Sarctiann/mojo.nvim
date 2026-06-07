local M = {}

--- @return string
local function plugin_root()
	local source = debug.getinfo(1, "S").source
	local path = source:sub(2)
	return vim.fn.fnamemodify(path, ":h:h:h")
end

--- @return boolean
local function compile_parser()
	local root = plugin_root()
	local grammar_dir = root .. "/tree-sitter/mojo"
	local parser_dest = vim.fn.expand("~/.local/share/nvim/site/parser/mojo.so")
	local queries_dest = vim.fn.expand("~/.local/share/nvim/site/queries/mojo")

	vim.fn.mkdir(vim.fn.fnamemodify(parser_dest, ":h"), "p")
	vim.fn.mkdir(queries_dest, "p")

	local cmd = string.format(
		"cc -shared -fPIC -O2 -o %s %s/src/parser.c %s/src/scanner.c -I%s/src",
		vim.fn.shellescape(parser_dest),
		vim.fn.shellescape(grammar_dir),
		vim.fn.shellescape(grammar_dir),
		vim.fn.shellescape(grammar_dir)
	)
	local result = vim.fn.system(cmd)
	if vim.v.shell_error ~= 0 then
		vim.notify("[mojo.nvim] Compilation failed:\n" .. result, vim.log.levels.ERROR)
		return false
	end

	for _, qf in ipairs(vim.fn.readdir(grammar_dir .. "/queries")) do
		vim.fn.writefile(vim.fn.readfile(grammar_dir .. "/queries/" .. qf), queries_dest .. "/" .. qf)
	end

	return true
end

--- @return boolean
function M.register()
	local ok, parsers = pcall(require, "nvim-treesitter.parsers")
	if not ok then
		return false
	end

	local root = plugin_root()
	local grammar_dir = "tree-sitter/mojo"

	parsers.mojo = {
		install_info = {
			url = "https://github.com/Sarctiann/mojo.nvim", ---@diagnostic disable-line: missing-fields -- path takes precedence
			path = root,
			location = grammar_dir,
			files = { "src/parser.c", "src/scanner.c" },
			queries = grammar_dir .. "/queries",
			revision = "HEAD",
		},
		filetype = "mojo",
		tier = 2,
	}

	return true
end

--- @return boolean
local function stale_parser()
	local root = plugin_root()
	local grammar = root .. "/tree-sitter/mojo/grammar.js"
	local parser = vim.fn.expand("~/.local/share/nvim/site/parser/mojo.so")
	local gstat = vim.uv.fs_stat(grammar)
	local pstat = vim.uv.fs_stat(parser)
	if not gstat or not pstat then
		return true
	end
	return gstat.mtime.sec > pstat.mtime.sec
end

--- @param opts Mojo-lang.TreesitterConfig|nil
--- @return nil
function M.setup(opts)
	opts = opts or {}
	if opts.enabled == false then
		return
	end

	M.register()

	local group = vim.api.nvim_create_augroup("mojo_nvim_treesitter", { clear = true })

	vim.api.nvim_create_autocmd("User", {
		pattern = "TSUpdate",
		group = group,
		callback = function()
			M.register()
		end,
	})

	vim.api.nvim_create_autocmd("FileType", {
		pattern = "mojo",
		group = group,
		callback = function()
			if stale_parser() then
				vim.notify("[mojo.nvim] Rebuilding stale tree-sitter parser...", vim.log.levels.INFO)
				if compile_parser() then
					vim.cmd("edit!")
				end
			end
			pcall(vim.treesitter.start, 0, "mojo")
		end,
	})

	vim.api.nvim_create_user_command("MojoRebuildParser", function()
		if compile_parser() then
			vim.notify("[mojo.nvim] Parser rebuilt.", vim.log.levels.INFO)
			vim.cmd("edit!")
		end
	end, { desc = "Rebuild the self-hosted tree-sitter Mojo parser" })
end

return M
