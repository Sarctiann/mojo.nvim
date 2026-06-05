local env = require("mojo.env")

local M = {}

local function root_dir(root_markers)
  root_markers = root_markers or { "pixi.toml", "pyproject.toml", ".pixi", ".venv" }
  return function(fname)
    local path = fname or vim.fn.getcwd()
    return vim.fs.root(path .. "/.", root_markers) or vim.fs.dirname(path)
  end
end

function M.opts(user_opts)
  user_opts = user_opts or {}
  local opts = vim.tbl_deep_extend("force", {
    cmd = { "mojo-lsp-server" },
    filetypes = { "mojo" },
    root_dir = root_dir(user_opts.root_markers),
    on_new_config = function(new_config, root)
      local cmd = env.get_lsp_cmd(root)
      if cmd then
        new_config.cmd = cmd
      end
    end,
  }, user_opts)

  return opts
end

function M.setup(user_opts)
  local ok, lspconfig = pcall(require, "lspconfig")
  if not ok then
    return false
  end

  lspconfig.mojo.setup(M.opts(user_opts))
  return true
end

return M
