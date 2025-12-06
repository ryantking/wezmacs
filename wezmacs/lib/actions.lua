--[[
  WezMacs Actions Library

  Provides helper functions for common action patterns.
  Reduces duplication in module action definitions.
]]

local split = require("wezmacs.utils.split")
local wezterm = require("wezterm")
local act = wezterm.action

local M = {}

-- Create a smart split action for a command
---@param cmd_args table|function Command arguments or function that returns args
---@return function Action callback
function M.smart_split_action(cmd_args)
  return function(window, pane)
    local args = cmd_args

    -- Support function for dynamic args
    if type(cmd_args) == "function" then
      args = cmd_args(window, pane)
    end

    split.smart_split(pane, args)
  end
end

-- Create a new tab action
---@param cmd_args table Command arguments
---@return table WezTerm action
function M.new_tab_action(cmd_args)
  return act.SpawnCommandInNewTab({ args = cmd_args })
end

-- Create a new window action
---@param cmd_args table Command arguments
---@return table WezTerm action
function M.new_window_action(cmd_args)
  return act.SpawnCommandInNewWindow({ args = cmd_args })
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

-- Create a shell command action
---@param command string Shell command to execute
---@param opts table|nil Options with new_tab, new_window, smart_split
---@return function|table Action callback or WezTerm action
function M.shell_command_action(command, opts)
  opts = opts or {}

  if opts.new_tab then
    local shell = os.getenv("SHELL") or "/bin/bash"
    return M.new_tab_action({ shell, "-lc", command })
  elseif opts.new_window then
    local shell = os.getenv("SHELL") or "/bin/bash"
    return M.new_window_action({ shell, "-lc", command })
  elseif opts.smart_split then
    local shell = os.getenv("SHELL") or "/bin/bash"
    return M.smart_split_action({ shell, "-lc", command })
  else
    -- Send command to current pane
    return function(window, pane)
      pane:send_text(command .. "\n")
    end
  end
end

return M
