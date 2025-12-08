--[[
  WezMacs Action API

  Provides action functions ready for use in keybindings.

  Usage:
    local wezmacs = require("wezmacs")
    local act = wezmacs.action
    local wezterm = require("wezterm")

    -- Use wezmacs actions
    act.SmartSplit("lazygit")
    act.NewTab("htop")

    -- Use wezterm actions directly
    wezterm.action.ReloadConfiguration
]]

local wezterm = require("wezterm")
local act = wezterm.action

local M = {}

-- Helper: wrap command string in shell
-- Commands should always run in shell to get correct environment (PATH, etc.)
local function wrap_in_shell(command)
  local wezmacs = require("wezmacs")
  return { wezmacs.config.shell, "-lc", "exec " .. command }
end

-- Smart split action - auto-orients based on window aspect ratio
-- Tall windows split horizontally (Bottom), wide windows split vertically (Right)
---@param command string Shell command string
---@return function Action callback
function M.SmartSplit(command)
  return function(window, pane)
    local args = wrap_in_shell(command)
    local dims = pane:get_dimensions()
    local direction = dims.pixel_height > dims.pixel_width and "Bottom" or "Right"
    pane:split({
      direction = direction,
      size = 0.5,
      args = args,
    })
  end
end

-- New tab action
---@param command string Shell command string
---@return table WezTerm action
function M.NewTab(command)
  local args = wrap_in_shell(command)
  return act.SpawnCommandInNewTab({ args = args })
end

-- New window action
---@param command string Shell command string
---@return table WezTerm action
function M.NewWindow(command)
  local args = wrap_in_shell(command)
  return act.SpawnCommandInNewWindow({ args = args })
end

return M
