--[[
  WezMacs Actions Library

  Provides helper functions for common action patterns.
  Reduces duplication in module action definitions.
]]

local split = require("wezmacs.utils.split")
local wezterm = require("wezterm")
local act = wezterm.action

local M = {}

-- Helper: wrap command in shell if not already wrapped
-- Commands should always run in shell to get correct environment (PATH, etc.)
local function wrap_in_shell(cmd_args)
  local shell = os.getenv("SHELL") or "/bin/bash"
  
  -- If string, wrap in shell
  if type(cmd_args) == "string" then
    return { shell, "-lc", cmd_args }
  end
  
  -- If table, check if already wrapped in shell
  if type(cmd_args) == "table" then
    local first = cmd_args[1]
    -- Check if first arg is a shell path
    if first == shell or first == "/bin/bash" or first == "/bin/sh" or first == "/bin/zsh" then
      return cmd_args  -- Already wrapped
    end
    -- Not wrapped, wrap it
    return { shell, "-lc", table.concat(cmd_args, " ") }
  end
  
  -- Fallback: return as-is
  return cmd_args
end

-- Create a smart split action for a command
-- Commands are always run in shell to get correct environment (PATH, etc.)
---@param cmd_args table|string|function Command arguments (table), command string, or function that returns args
---@return function Action callback
function M.smart_split_action(cmd_args)
  return function(window, pane)
    local args = cmd_args

    -- Support function for dynamic args
    if type(cmd_args) == "function" then
      args = cmd_args(window, pane)
    end

    -- Wrap in shell if needed
    args = wrap_in_shell(args)

    split.smart_split(pane, args)
  end
end

-- Create a new tab action
-- Commands are always run in shell to get correct environment (PATH, etc.)
---@param cmd_args table|string Command arguments (table) or command string
---@return table WezTerm action
function M.new_tab_action(cmd_args)
  local args = wrap_in_shell(cmd_args)
  return act.SpawnCommandInNewTab({ args = args })
end

-- Create a new window action
-- Commands are always run in shell to get correct environment (PATH, etc.)
---@param cmd_args table|string Command arguments (table) or command string
---@return table WezTerm action
function M.new_window_action(cmd_args)
  local args = wrap_in_shell(cmd_args)
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
