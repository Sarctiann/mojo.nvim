local M = {}

function M.treesitter(opts)
  opts = opts or {}
  opts.ensure_installed = opts.ensure_installed or {}
  if not vim.tbl_contains(opts.ensure_installed, "mojo") then
    table.insert(opts.ensure_installed, "mojo")
  end
  return opts
end

function M.lsp(opts)
  return require("mojo.lsp").opts(opts)
end

function M.format(opts)
  return require("mojo.format").opts(opts)
end

return M
