local M = {}

local cache = {}

local function root_for(path, markers)
  path = path or vim.fn.getcwd()
  markers = markers or { "pixi.toml", "pyproject.toml", ".pixi", ".venv" }
  return vim.fs.root(path .. "/.", markers)
end

local function has_file(path)
  return path and vim.uv.fs_stat(path) ~= nil
end

local function has_dir(path)
  return path and vim.uv.fs_stat(path) and vim.uv.fs_stat(path).type == "directory"
end

local function first_pixi_env(root)
  local envs_dir = vim.fs.joinpath(root, ".pixi", "envs")
  if not has_dir(envs_dir) then
    return nil, nil
  end

  local envs = {}
  for name, entry_type in vim.fs.dir(envs_dir) do
    if entry_type == "directory" then
      table.insert(envs, name)
    end
  end

  table.sort(envs, function(a, b)
    if a == "default" and b ~= "default" then
      return true
    end
    if b == "default" and a ~= "default" then
      return false
    end
    return a < b
  end)

  local env_name = envs[1]
  if not env_name then
    return nil, nil
  end

  return env_name, vim.fs.joinpath(envs_dir, env_name)
end

local function find_pixi_binary(root, binary)
  local envs_dir = vim.fs.joinpath(root, ".pixi", "envs")
  if not has_dir(envs_dir) then
    return nil
  end

  for name, entry_type in vim.fs.dir(envs_dir) do
    if entry_type == "directory" then
      local candidate = vim.fs.joinpath(envs_dir, name, "bin", binary)
      if has_file(candidate) then
        return candidate
      end
    end
  end

  return nil
end

function M.detect(path)
  local root = root_for(path)
  if not root then
    return nil
  end

  if cache[root] ~= nil then
    return cache[root] or nil
  end

  local pixi_toml = vim.fs.joinpath(root, "pixi.toml")
  local pixi_dir = vim.fs.joinpath(root, ".pixi")
  if has_file(pixi_toml) or has_dir(pixi_dir) then
    local env_name, pixi_env = first_pixi_env(root)
    cache[root] = {
      type = "pixi",
      root = root,
      env_name = env_name,
      env_dir = pixi_env,
      bin_dir = pixi_env and vim.fs.joinpath(pixi_env, "bin") or nil,
      activate_cmd = env_name and string.format('eval "$(pixi shell-hook --environment %s)"', env_name)
        or 'eval "$(pixi shell-hook)"',
    }
    return cache[root]
  end

  local venv_dir = vim.fs.joinpath(root, ".venv")
  local venv_activate = vim.fs.joinpath(venv_dir, "bin", "activate")
  if has_file(venv_activate) then
    cache[root] = {
      type = "venv",
      root = root,
      env_dir = venv_dir,
      bin_dir = vim.fs.joinpath(venv_dir, "bin"),
      activate_cmd = "source .venv/bin/activate",
    }
    return cache[root]
  end

  cache[root] = false
  return nil
end

function M.get_mojo_cmd(path)
  local env = M.detect(path)
  if env and env.bin_dir then
    local bin = vim.fs.joinpath(env.bin_dir, "mojo")
    if has_file(bin) then
      return bin
    end
  end

  if env and env.type == "pixi" then
    local bin = find_pixi_binary(env.root, "mojo")
    if bin then
      return bin
    end
  end

  return vim.fn.executable("mojo") == 1 and "mojo" or nil
end

function M.get_lsp_cmd(path)
  local env = M.detect(path)
  if env and env.bin_dir then
    local bin = vim.fs.joinpath(env.bin_dir, "mojo-lsp-server")
    if has_file(bin) then
      return { bin }
    end
  end

  if env and env.type == "pixi" then
    local bin = find_pixi_binary(env.root, "mojo-lsp-server")
    if bin then
      return { bin }
    end
  end

  if vim.fn.executable("mojo-lsp-server") == 1 then
    return { "mojo-lsp-server" }
  end

  return nil
end

function M.activate_command(path)
  local env = M.detect(path)
  if not env then
    return nil
  end
  return env.activate_cmd
end

function M.activate_in_terminal(channel, path, delay_ms)
  local command = M.activate_command(path)
  if not command then
    return false
  end

  vim.defer_fn(function()
    pcall(vim.api.nvim_chan_send, channel, command .. "\n")
  end, delay_ms or 200)

  return true
end

return M
