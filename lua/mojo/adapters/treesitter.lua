local M = {}

--- @param opts Mojo-lang.TreesitterConfig|nil
--- @return boolean
function M.setup(opts)
	opts = opts or {}
	if opts.enabled == false then
		return false
	end

	local ts = require("mojo.treesitter")
	ts.register()

	local group = vim.api.nvim_create_augroup("mojo_nvim_treesitter", { clear = true })

	vim.api.nvim_create_autocmd("User", {
		pattern = "TSUpdate",
		group = group,
		callback = function()
			ts.register()
		end,
	})

	vim.api.nvim_create_autocmd("FileType", {
		pattern = "mojo",
		group = group,
		callback = function()
			if ts.stale_parser() then
				vim.notify("[mojo.nvim] Rebuilding stale tree-sitter parser...", vim.log.levels.INFO)
				if ts.compile_parser() then
					vim.cmd("edit!")
				end
			end
			pcall(vim.treesitter.start, 0, "mojo")
		end,
	})

	vim.api.nvim_create_user_command("MojoRebuildParser", function()
		if ts.compile_parser() then
			vim.notify("[mojo.nvim] Parser rebuilt.", vim.log.levels.INFO)
			vim.cmd("edit!")
		end
	end, { desc = "Rebuild the self-hosted tree-sitter Mojo parser" })

	return true
end

return M