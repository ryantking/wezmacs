--[[
  WezMacs Keybinding Utilities

  Reusable utilities for common keybinding patterns to reduce duplication
  across modules.

  Key design decisions:
  - Uses $SHELL environment variable (not config.default_prog)
  - Always wraps commands in shell for proper environment
  - Provides consistent error handling
]]

local wezterm = require("wezterm")
local act = wezterm.action

local M = {}

-- Get the shell to use for command execution
-- Uses $SHELL environment variable, falls back to /bin/bash
---@return string Shell path
local function get_shell()
  return os.getenv("SHELL") or "/bin/bash"
end

-- Spawn a command in a new tab with shell environment
---@param cmd table Command and arguments
---@return table WezTerm action
function M.spawn_in_tab(cmd)
  return act.SpawnCommandInNewTab({
    args = { get_shell(), "-c", table.concat(cmd, " ") }
  })
end

-- Spawn a command in a smart split with shell environment
-- Uses the smart_split utility to determine orientation
---@param cmd table Command and arguments
---@return function WezTerm action callback
function M.spawn_in_split(cmd)
  local split = require("wezmacs.utils.split")
  return wezterm.action_callback(function(window, pane)
    local shell_cmd = { get_shell(), "-c", table.concat(cmd, " ") }
    split.smart_split(pane, shell_cmd)
  end)
end

-- Open selector, run command with selection, cancel on empty
---@param opts table Options: label (string), patterns (table), command (function)
---@return table WezTerm action
function M.select_and_run(opts)
  return act.QuickSelectArgs({
    label = opts.label or "select",
    patterns = opts.patterns or {},
    action = wezterm.action_callback(function(window, pane)
      local selection = window:get_selection_text_for_pane(pane)
      if selection and selection ~= "" then
        local cmd = opts.command(selection)
        if cmd then
          pane:send_text(table.concat(cmd, " ") .. "\n")
        end
      end
    end),
  })
end

-- Prompt for text input, run command with input
---@param opts table Options: label (string), command (function)
---@return function WezTerm action callback
function M.prompt_and_run(opts)
  return wezterm.action_callback(function(window, pane)
    window:perform_action(
      act.PromptInputLine({
        description = opts.label or "Enter input:",
        action = wezterm.action_callback(function(inner_window, inner_pane, line)
          if line and line ~= "" then
            local cmd = opts.command(line)
            if cmd then
              inner_pane:send_text(table.concat(cmd, " ") .. "\n")
            end
          end
        end),
      }),
      pane
    )
  end)
end

-- Create a simple command runner that just executes a command in the pane
---@param cmd table Command and arguments
---@return function WezTerm action callback
function M.run_command(cmd)
  return wezterm.action_callback(function(window, pane)
    pane:send_text(table.concat(cmd, " ") .. "\n")
  end)
end

return M
