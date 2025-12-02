--[[
  Workspace module actions
  All action callbacks and helper functions for workspace module
]]

local wezterm = require("wezterm")
local act = wezterm.action

local M = {}

-- Jump to System workspace
function M.jump_to_system_workspace(window, pane)
  window:perform_action(
    act.SwitchToWorkspace({
      name = "~/System",
      spawn = { cwd = wezterm.home_dir .. "/System" },
    }),
    pane
  )
  window:set_right_status(window:active_workspace())
end

return M
