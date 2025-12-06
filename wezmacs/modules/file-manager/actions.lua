--[[
  File-manager module actions
  All action callbacks and helper functions for file-manager module
]]

local action_lib = require("wezmacs.lib.actions")

local M = {}

-- These will be set up by the module init
local _file_manager = "yazi"

function M.setup(file_manager)
  _file_manager = file_manager
end

-- File manager in smart split
function M.file_manager_split(window, pane)
  return action_lib.smart_split_action(_file_manager)(window, pane)
end

-- File manager in new tab
function M.file_manager_new_tab(window, pane)
  return action_lib.new_tab_action(_file_manager)
end

-- File manager with sudo in smart split
function M.file_manager_sudo_split(window, pane)
  return action_lib.smart_split_action("sudo " .. _file_manager .. " /")(window, pane)
end

-- File manager with sudo in new tab
function M.file_manager_sudo_tab(window, pane)
  return action_lib.new_tab_action("sudo " .. _file_manager .. " /")
end

return M
