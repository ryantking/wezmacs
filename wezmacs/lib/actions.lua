--[[
  WezMacs Actions Library

  Provides helper functions for common action patterns.
  Reduces duplication in module action definitions.
]]

local wezterm = require("wezterm")
local act = wezterm.action

local M = {}

-- Helper: wrap command string in shell
-- Commands should always run in shell to get correct environment (PATH, etc.)
local function wrap_in_shell(command)
  local shell = os.getenv("SHELL") or "/bin/bash"
  return { shell, "-lc", command }
end

-- Create a smart split action for a command
-- Commands are always run in shell to get correct environment (PATH, etc.)
-- Smart split auto-orients based on window aspect ratio:
--   Tall windows split horizontally (Bottom), wide windows split vertically (Right)
---@param command string|function Shell command string or function that returns command string
---@return function Action callback
function M.smart_split_action(command)
  return function(window, pane)
    local cmd = command

    -- Support function for dynamic command
    if type(command) == "function" then
      cmd = command(window, pane)
    end

    -- Wrap in shell
    local args = wrap_in_shell(cmd)

    -- Smart split: auto-orient based on pane dimensions
    local dims = pane:get_dimensions()
    local direction = dims.pixel_height > dims.pixel_width and "Bottom" or "Right"
    pane:split({
      direction = direction,
      size = 0.5,
      args = args,
    })
  end
end

-- Create a new tab action
-- Commands are always run in shell to get correct environment (PATH, etc.)
---@param command string Shell command string
---@return table WezTerm action
function M.new_tab_action(command)
  local args = wrap_in_shell(command)
  return act.SpawnCommandInNewTab({ args = args })
end

-- Create a new window action
-- Commands are always run in shell to get correct environment (PATH, etc.)
---@param command string Shell command string
---@return table WezTerm action
function M.new_window_action(command)
  local args = wrap_in_shell(command)
  return act.SpawnCommandInNewWindow({ args = args })
end

-- Create an overlay action (for floating prompts/info)
---@param content_fn function Function that returns content string
---@return function Action callback
function M.overlay_action(content_fn)
  return function(window, pane)
    local content = content_fn(window, pane)

    -- Use WezTerm toast notification system
    window:toast_notification("WezMacs", content, nil, 5000)
  end
end

return M
