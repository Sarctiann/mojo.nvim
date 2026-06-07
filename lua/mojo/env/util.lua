local M = {}

--- @param path string|nil
--- @param markers string[]|nil
--- @return string|nil
function M.root_for(path, markers)
	path = path or vim.fn.getcwd()
	markers = markers or { "pixi.toml", "pyproject.toml", ".pixi", ".venv" }
	return vim.fs.root(path .. "/.", markers)
end

--- @param path string|nil
--- @return boolean|nil
function M.has_file(path)
	return path and vim.uv.fs_stat(path) ~= nil
end

--- @param path string|nil
--- @return boolean|nil
function M.has_dir(path)
	return path and vim.uv.fs_stat(path) and vim.uv.fs_stat(path).type == "directory"
end

--- @param root string
--- @return string|nil, string|nil
function M.first_pixi_env(root)
	local envs_dir = vim.fs.joinpath(root, ".pixi", "envs")
	if not M.has_dir(envs_dir) then
		return nil, nil
	end

	local envs = {} --- @type string[]
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

	local env_name = envs[1] --- @type string|nil
	if not env_name then
		return nil, nil
	end

	return env_name, vim.fs.joinpath(envs_dir, env_name)
end

--- @param root string
--- @param binary string
--- @return string|nil
function M.find_pixi_binary(root, binary)
	local envs_dir = vim.fs.joinpath(root, ".pixi", "envs")
	if not M.has_dir(envs_dir) then
		return nil
	end

	for name, entry_type in vim.fs.dir(envs_dir) do
		if entry_type == "directory" then
			local candidate = vim.fs.joinpath(envs_dir, name, "bin", binary)
			if M.has_file(candidate) then
				return candidate
			end
		end
	end

	return nil
end

--- @param key string
--- @param value string|nil
function M.env_prepend(key, value)
	if not value or value == "" then
		return
	end

	local current = vim.env[key] or ""
	local parts = {} --- @type string[]
	local seen = {} --- @type table<string, boolean>

	local function add(part)
		if part ~= "" and not seen[part] then
			seen[part] = true
			table.insert(parts, part)
		end
	end

	add(value)
	for part in current:gmatch("[^:]+") do
		add(part)
	end

	vim.env[key] = table.concat(parts, ":")
end

return M