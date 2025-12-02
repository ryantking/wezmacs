--[[
  File-manager module actions
  All action callbacks and helper functions for file-manager module
]]

local split = require("wezmacs.utils.split")

local M = {}

-- File manager in smart split
function M.file_manager_split(window, pane, file_manager)
  split.smart_split(pane, { file_manager })
end

-- File manager with sudo in smart split
function M.file_manager_sudo_split(window, pane, file_manager)
  split.smart_split(pane, { "sudo", file_manager, "/" })
end

return M
