local M = {}

M.defaults = {
  filetype = { enabled = true },
  terminal = {
    enabled = true,
    auto_activate = true,
    delay_ms = 200,
  },
  treesitter = {
    enabled = true,
    parser = {
      install_info = {
        url = "https://github.com/oaustegard/tree-sitter-mojo",
        revision = "v1.0",
        queries = "queries",
      },
      filetype = "mojo",
      tier = 2,
    },
  },
  lsp = {
    enabled = false,
    root_markers = { "pixi.toml", "pyproject.toml", ".pixi", ".venv" },
  },
  format = {
    enabled = false,
    formatter_name = "mojo",
  },
  debug = false,
  hooks = {},
}

M.options = vim.deepcopy(M.defaults)

function M.setup(user_config)
  M.options = vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), user_config or {})
  return M.options
end

return M
