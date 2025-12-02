--[[
  Editors module actions
  All action callbacks and helper functions for editors module
]]

local wezterm = require("wezterm")
local split = require("wezmacs.utils.split")

local M = {}

-- Terminal editor in smart split
function M.terminal_editor_split(window, pane, editor)
  split.smart_split(pane, { editor, "." })
end

-- IDE launcher
function M.launch_ide(window, pane, ide)
  local cwd_uri = pane:get_current_working_dir()
  local cwd = cwd_uri and cwd_uri.file_path or wezterm.home_dir
  wezterm.background_child_process({ ide, cwd })
end

return M
