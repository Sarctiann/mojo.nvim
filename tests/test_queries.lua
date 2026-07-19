-- test_queries.lua
-- Run: nvim --headless -c "luafile tests/test_queries.lua" -c "qa!"
--
-- Parses every .mojo file in mojo_samples/, reports ERROR nodes,
-- and runs targeted capture assertions on highlights.mojo.

local total_errors = 0
local total_files = 0

local function read_file(path)
  local f = io.open(path, "r")
  if not f then return nil end
  local content = f:read("*a")
  f:close()
  return content
  end

local function fail(msg)
  print("  FAIL: " .. msg)
  total_errors = total_errors + 1
end

local function pass(msg)
  print("  PASS: " .. msg)
end

-- Locate all .mojo files
local scandir = vim.fn.readdir("tests/mojo_samples")
local mojo_files = {}
for _, name in ipairs(scandir) do
  if name:match("%.mojo$") then
    table.insert(mojo_files, "tests/mojo_samples/" .. name)
  end
end

for _, filepath in ipairs(mojo_files) do
  local filename = filepath:match("([^/]+)$")
  local content = read_file(filepath)
  if not content then
    print(string.rep("=", 60))
    print("FILE: " .. filename .. " — CANNOT READ")
    fail("cannot read file")
    goto continue
  end

  local lines = vim.split(content, "\n", {plain = true})
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].filetype = "mojo"
  vim.bo[buf].modified = false

  local parser = vim.treesitter.get_parser(buf, "mojo", {error = true})
  local ok, tree
  ok, tree = pcall(function() local result = parser and parser:parse() return result and result[1] end)
  if not ok then
    print(string.rep("=", 60))
    print("FILE: " .. filename .. " — NO PARSER")
    fail("tree-sitter parser not available for mojo (install: :TSInstallSync mojo)")
    vim.api.nvim_buf_delete(buf, {force = true})
    goto continue
  end

  local root = tree:root()
  local file_errors = 0

  -- Walk tree counting ERROR nodes
  local function walk(node)
    if node:type() == "ERROR" then
      file_errors = file_errors + 1
      local sr, sc = node:start()
      local er, ec = node:end_()
      local text = vim.treesitter.get_node_text(node, buf)
      fail(string.format("[%s] ERROR at line %d:%d-%d:%d: %s",
        filename, sr + 1, sc, er + 1, ec, text:sub(1, 60)))
    end
    for child in node:iter_children() do
      walk(child)
    end
  end

  walk(root)

  total_files = total_files + 1
  local status = file_errors == 0 and "OK" or string.format("%d ERROR(s)", file_errors)
  print(string.format("  %-30s  %d lines  %s", filename, #lines, status))

  -- Run targeted capture tests only on highlights.mojo
  if filename == "highlights.mojo" then
    local function check(qs, min, label)
      local qok, query = pcall(vim.treesitter.query.parse, "mojo", qs)
      if not qok then
        fail(string.format("[capture][%s] query parse error: %s", label, tostring(query)))
        return
      end
      local count = 0
      for _ in query:iter_matches(root, buf, 0, -1) do
        count = count + 1
      end
      if count >= min then
        pass(string.format("[capture][%s] matched %d (expected >= %d)", label, count, min))
      else
        fail(string.format("[capture][%s] matched %d (expected >= %d)", label, count, min))
      end
    end

    check("(comment) @comment", 1, "comment")
    check("[(integer) (float)] @number", 3, "number")
    check("(string) @string", 3, "string")
    check([[
      ((identifier) @constant
       (#match? @constant "^_*[A-Z][A-Z0-9_]*$"))
    ]], 2, "constant")
    check([[
      ((identifier) @type
       (#match? @type "^[A-Z]"))
    ]], 5, "type/constructor")
    check([[
      ((identifier) @variable.builtin
       (#eq? @variable.builtin "self"))
    ]], 1, "self")
    check("(self) @type.builtin", 1, "Self")
    check("(function_signature name: (identifier) @function)", 4, "function_signature")
    check("(call function: (identifier) @function)", 3, "call")
    check("(member_call function: (identifier) @function.method)", 1, "member_call")
    check("[(none) (true) (false)] @constant.builtin", 1, "constant.builtin")
    check("[\"(\" \")\" \"[\" \"]\"] @punctuation.bracket", 4, "punctuation.bracket")
    check("(member_access member: (identifier) @property)", 1, "property")
    check("(decorator (identifier) @attribute)", 1, "decorator")
    check("(struct_header name: (identifier) @type)", 1, "struct_header")
    check("(trait_header name: (identifier) @type.definition)", 1, "trait_header")
  end

  vim.api.nvim_buf_delete(buf, {force = true})

  ::continue::
end

-- Summary
print(string.rep("=", 60))
print(string.format("Files: %d, Total failures: %d", total_files, total_errors))
if total_errors > 0 then
  vim.cmd(string.format("cq %d", math.min(total_errors, 255)))
else
  vim.cmd("cq 0")
end
