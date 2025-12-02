--[[
  Docker module actions
  All action callbacks and helper functions for docker module
]]

local split = require("wezmacs.utils.split")

local M = {}

-- Lazydocker in smart split
function M.lazydocker_split(window, pane)
  split.smart_split(pane, { "lazydocker" })
end

return M
