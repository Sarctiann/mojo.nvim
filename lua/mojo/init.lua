local config = require("mojo.config")
local hooks = require("mojo.hooks")

local M = {}

M.hooks = hooks.defaults

function M.setup(user_config)
  local opts = config.setup(user_config)
  M.hooks = hooks.merge(opts.hooks)

  if opts.filetype and opts.filetype.enabled ~= false then
    require("mojo.filetype").setup()
  end

  if opts.treesitter and opts.treesitter.enabled ~= false then
    require("mojo.treesitter").setup(opts.treesitter)
  end

  if opts.lsp and opts.lsp.enabled ~= false then
    require("mojo.lsp").setup(opts.lsp)
  end

  if opts.format and opts.format.enabled ~= false then
    require("mojo.format").setup(opts.format)
  end

  if opts.terminal and opts.terminal.enabled ~= false then
    require("mojo.terminal").setup(opts.terminal)
  end

  return opts
end

return M
