--[[
  Docker module actions
  All action callbacks and helper functions for docker module
]]

local action_lib = require("wezmacs.lib.actions")

local M = {}

-- Lazydocker in smart split
M.lazydocker_split = action_lib.smart_split_action("lazydocker")

-- Lazydocker in new tab
M.lazydocker_new_tab = action_lib.new_tab_action("lazydocker")

return M
