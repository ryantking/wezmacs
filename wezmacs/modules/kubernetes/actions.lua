--[[
  Kubernetes module actions
  All action callbacks and helper functions for kubernetes module
]]

local action_lib = require("wezmacs.lib.actions")

local M = {}

M.launch_k9s = action_lib.new_tab_action("k9s")

return M
