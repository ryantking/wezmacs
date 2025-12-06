--[[
  System-monitor module actions
  All action callbacks and helper functions for system-monitor module
]]

local action_lib = require("wezmacs.lib.actions")

local M = {}

M.launch_btm = action_lib.new_tab_action("btm")

return M
