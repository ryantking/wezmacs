--[[
  Git module actions
  All action callbacks and helper functions for git module
]]

local action_lib = require("wezmacs.lib.actions")
local wezterm = require("wezterm")
local act = wezterm.action

local M = {}

-- Lazygit in smart split (auto-orientation based on window aspect ratio)
-- Note: lazygit's -sm flag is specific to lazygit, so we add it here
M.lazygit_smart_split = action_lib.smart_split_action("lazygit -sm half")

-- Lazygit in new tab
M.lazygit_new_tab = action_lib.new_tab_action("lazygit")

-- Git diff with smart split orientation
M.git_diff_smart_split = action_lib.smart_split_action(
  "git diff main 2>/dev/null || git diff master 2>/dev/null || git diff origin/main 2>/dev/null || git diff origin/master 2>/dev/null || git status"
)

-- Git diff in new window
M.git_diff_new_window = action_lib.new_window_action(
  "git diff main 2>/dev/null || git diff master 2>/dev/null || git diff origin/main 2>/dev/null || git diff origin/master 2>/dev/null || git status"
)

return M
