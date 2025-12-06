--[[
  Workspace module actions
  All action callbacks and helper functions for workspace module
]]

local wezterm = require("wezterm")

local M = {}

local workspace_switcher = wezterm.plugin.require("https://github.com/MLFlexer/smart_workspace_switcher.wezterm")

function M.switch_workspace(window, pane)
  return workspace_switcher.switch_workspace()
end

function M.switch_to_prev_workspace(window, pane)
  return workspace_switcher.switch_to_prev_workspace()
end

return M
