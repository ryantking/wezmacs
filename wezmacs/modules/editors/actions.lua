--[[
  Editors module actions
  All action callbacks and helper functions for editors module
]]

local wezterm = require("wezterm")
local action_lib = require("wezmacs.lib.actions")

local M = {}

-- These will be set up by the module init
local _editor = "vim"
local _ide = "code"

function M.setup(editor, ide)
  _editor = editor
  _ide = ide
end

-- Terminal editor in smart split
function M.terminal_smart_split(window, pane)
  local shell = os.getenv("SHELL") or "/bin/bash"
  return action_lib.smart_split_action({ shell, "-lc", _editor })(window, pane)
end

-- Terminal editor in new tab
function M.terminal_new_tab(window, pane)
  local shell = os.getenv("SHELL") or "/bin/bash"
  return action_lib.new_tab_action({ shell, "-lc", _editor })
end

-- IDE launcher
function M.launch_ide(window, pane)
  local cwd_uri = pane:get_current_working_dir()
  local cwd = cwd_uri and cwd_uri.file_path or wezterm.home_dir
  wezterm.background_child_process({ _ide, cwd })
end

return M
