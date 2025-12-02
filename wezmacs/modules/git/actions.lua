--[[
  Git module actions
  All action callbacks and helper functions for git module
]]

local split = require("wezmacs.utils.split")

local M = {}

-- Lazygit in smart split (auto-orientation based on window aspect ratio)
function M.lazygit_smart_split(window, pane)
  split.smart_split(pane, { "lazygit", "-sm", "half" })
end

-- Git diff with smart split orientation
function M.git_diff_smart_split(window, pane)
  split.smart_split(pane, {
    os.getenv("SHELL") or "/bin/bash",
    "-lc",
    "git diff main 2>/dev/null || git diff master 2>/dev/null || git diff origin/main 2>/dev/null || git diff origin/master 2>/dev/null || git status",
  })
end

return M
