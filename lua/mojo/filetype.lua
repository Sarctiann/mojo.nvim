local M = {}

function M.setup()
  vim.filetype.add({
    extension = {
      mojo = "mojo",
    },
  })
end

return M
