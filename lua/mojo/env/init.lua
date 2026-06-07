local detect = require("mojo.env.detect")
local activate = require("mojo.env.activate")
local bin = require("mojo.env.bin")

local M = {}

M.detect = detect.detect
M.activate_command = detect.activate_command
M.activate_for_dir = activate.activate_for_dir
M.activate_in_terminal = activate.activate_in_terminal
M.get_mojo_cmd = bin.get_mojo_cmd
M.get_lsp_cmd = bin.get_lsp_cmd

return M