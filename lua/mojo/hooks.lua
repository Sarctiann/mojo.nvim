local M = {}

M.defaults = {
  resolve_root = function(path, markers)
    path = path or vim.fn.getcwd()
    markers = markers or { "pixi.toml", "pyproject.toml", ".pixi", ".venv" }
    return vim.fs.root(path .. "/.", markers)
  end,
}

function M.merge(user_hooks)
  return vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), user_hooks or {})
end

return M
