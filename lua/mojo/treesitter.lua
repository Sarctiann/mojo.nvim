local M = {}

function M.register(parser)
  local ok, parsers = pcall(require, "nvim-treesitter.parsers")
  if not ok then
    return false
  end

  parsers.mojo = vim.tbl_deep_extend("force", {}, parser or {
    install_info = {
      url = "https://github.com/oaustegard/tree-sitter-mojo",
      revision = "v1.0",
      queries = "queries",
    },
    filetype = "mojo",
    tier = 2,
  })

  return true
end

function M.setup(opts)
  opts = opts or {}
  if opts.enabled == false then
    return
  end

  M.register(opts.parser)

  vim.api.nvim_create_autocmd("User", {
    pattern = "TSUpdate",
    callback = function()
      M.register(opts.parser)
    end,
  })
end

return M
