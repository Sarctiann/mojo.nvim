local M = {}

local completion = require("mojo.completion")

local SNIP = 15
local PLAIN_TEXT = 1
local SNIPPET = 2

--- @type Mojo-lang.CompletionItem[]?
local cached_items = nil

local function get_items()
	if cached_items then
		return cached_items
	end
	local raw = completion.all_items()
	local items = {}
	for i, item in ipairs(raw) do
		local insert_text = item.label
		local insert_text_format = PLAIN_TEXT
		if item.kind == SNIP then
			insert_text_format = SNIPPET
			local snip = nil
			for _, s in ipairs(completion.snippets) do
				if s.trigger == item.label then
					snip = s
					break
				end
			end
			if snip then
				insert_text = snip.body
			end
		end
		items[i] = {
			label = item.label,
			kind = item.kind,
			detail = item.detail,
			insertText = insert_text,
			insertTextFormat = insert_text_format,
		}
	end
	cached_items = items
	return items
end

--- @class MojoBlinkSource : blink.cmp.Source
--- @field opts table

function M.new(opts)
	local self = setmetatable({}, { __index = M })
	self.opts = opts or {}
	return self --[[@as blink.cmp.Source]]
end

function M:get_trigger_characters()
	return {}
end

function M:get_completions(context, callback)
	local line = context.line or ""
	local col = context.cursor and context.cursor.column or 0
	if col > 0 then
		local char_before = line:sub(col, col)
		if char_before:match("[%.:]") then
			callback({
				items = {},
				is_incomplete_backward = false,
				is_incomplete_forward = false,
			})
			return
		end
	end

	callback({
		items = get_items(),
		is_incomplete_backward = false,
		is_incomplete_forward = false,
	})
end

--- Returns blink.cmp configuration for Mojo filetype.
--- @param opts Mojo-lang.CompletionConfig|nil
--- @return table
function M.opts(opts)
	opts = opts or {}

	return {
		sources = {
			completion = {
				enabled_providers = { "lsp", "mojo", "snippets", "path", "buffer" },
			},
		},
		providers = {
			mojo = {
				name = "mojo",
				module = "mojo.adapters.blink",
				opts = opts,
			},
		},
	}
end

--- @param opts Mojo-lang.CompletionConfig|nil
--- @return boolean
function M.setup(opts)
	opts = opts or {}
	if opts.enabled == false then
		return false
	end

	local ok, blink = pcall(require, "blink.cmp")
	if not ok then
		return false
	end

	local user_opts = M.opts(opts)
	local existing_providers = blink.config and blink.config.providers or {}
	local providers = vim.tbl_deep_extend("force", existing_providers, user_opts.providers or {})

	blink.setup({
		providers = providers,
		sources = user_opts.sources,
	})

	return true
end

return M

