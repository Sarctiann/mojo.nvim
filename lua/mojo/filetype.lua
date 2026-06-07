local env = require("mojo.env")

local M = {}

--- @return nil
function M.setup()
	vim.filetype.add({
		extension = {
			mojo = "mojo",
			["🔥"] = "mojo",
		},
	})

	vim.api.nvim_create_autocmd({ "BufReadPre", "BufNewFile" }, {
		pattern = { "*.mojo", "*.🔥" },
		callback = function(ev)
			local path = vim.api.nvim_buf_get_name(ev.buf)
			env.activate_for_dir(path)
		end,
	})
end

return M