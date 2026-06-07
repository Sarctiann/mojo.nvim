local M = {}

--- @type boolean
local enabled = false

--- @return string|osdate
local function timestamp()
	return os.date("%Y-%m-%d %H:%M:%S")
end

--- @param data table<string, any>|nil
--- @return string
local function format_data(data)
	if type(data) ~= "table" then
		return ""
	end

	local parts = {} --- @type string[]
	for key, value in pairs(data) do
		local value_str
		if value == nil then
			value_str = "nil"
		elseif type(value) == "boolean" then
			value_str = value and "true" or "false"
		elseif type(value) == "number" then
			value_str = tostring(value)
		else
			value_str = tostring(value)
		end
		table.insert(parts, tostring(key) .. "=" .. value_str)
	end

	table.sort(parts)
	return table.concat(parts, " ")
end

--- @param opts { debug: boolean }|nil
--- @return nil
function M.setup(opts)
	opts = opts or {}
	enabled = opts.debug or false
end

--- @param event string
--- @param data_fn fun(): table<string, any>
function M.log(event, data_fn)
	if not enabled then
		return
	end

	local ok, data = pcall(data_fn)
	if not ok then
		return
	end

	local entry = string.format("[%s] [mojo.nvim] %s", timestamp(), event)
	local data_str = format_data(data)
	if data_str ~= "" then
		entry = entry .. " | " .. data_str
	end

	local file = io.open(vim.fn.getcwd() .. "/mojo-debug.log", "a")
	if file then
		file:write(entry .. "\n")
		file:close()
	end
end

return M