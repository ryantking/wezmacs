--[[
  Module: claude
  Category: workflows
  Description: Claude Code integration with workspace management

  Provides:
  - Open Claude in new tab (LEADER c c or LEADER c C)
  - Create new agentctl workspace (LEADER c w)
  - Switch to existing workspace (LEADER c s)
  - Delete agentctl workspace (LEADER c d)

  Note: This module depends on agentctl being installed.
  If not available, only basic claude launching works.

  Configuration:
    leader_key - Key to activate claude menu (default: "c")
    leader_mod - Modifier for leader key (default: "LEADER")
]]

local wezterm = require("wezterm")
local act = wezterm.action
local actions = require("wezmacs.modules.claude.actions")
local split = require("wezmacs.utils.split")

local M = {}

M._NAME = "claude"
M._CATEGORY = "workflows"
M._DESCRIPTION = "Claude Code integration and workspace management"
M._EXTERNAL_DEPS = { "claude", "agentctl" }
M._CONFIG = {
  leader_key = "c",
  leader_mod = "LEADER",
}

function M.apply_to_config(config)
  local mod = wezmacs.get_module(M._NAME)

  -- Create claude key table
  config.key_tables = config.key_tables or {}
  config.key_tables.claude = {
    { key = "c", action = wezterm.action_callback(actions.claude_smart_split) },
    { key = "C", action = act.SpawnCommandInNewTab({ args = { os.getenv("SHELL") or "/bin/bash", "-c", "claude" } }) },
    { key = "w", action = wezterm.action_callback(actions.create_agentctl_workspace) },
    { key = "Space", action = wezterm.action_callback(actions.list_agentctl_sessions) },
    { key = "s", action = wezterm.action_callback(actions.list_agentctl_sessions) },
    { key = "d", action = wezterm.action_callback(actions.delete_agentctl_session) },
    { key = "Escape", action = "PopKeyTable" },
  }

  -- Add keybinding to activate claude menu
  config.keys = config.keys or {}
  table.insert(config.keys, { key = "Enter", mods = "SHIFT", action = act.SendString("\x1b\r") })
  table.insert(config.keys, {
    key = mod.leader_key,
    mods = mod.leader_mod,
    action = act.ActivateKeyTable({
      name = "claude",
      one_shot = false,
      until_unknown = true,
    }),
  })
end

return M
