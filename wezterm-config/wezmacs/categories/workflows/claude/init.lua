--[[
  Module: claude
  Category: workflows
  Description: Claude Code integration with workspace management

  Provides:
  - New Claude session in tab
  - Create new claudectl workspace
  - List and select active claudectl workspaces
  - Delete claudectl workspaces

  Note: This module depends on claudectl being installed.
  If not available, only basic claude launching works.

  Configurable flags:
    leader_key - Claude submenu key (default: c)
    leader_mod - Leader modifier (default: LEADER)
]]

local wezterm = require("wezterm")
local act = wezterm.action
local M = {}

M._NAME = "claude"
M._CATEGORY = "workflows"
M._VERSION = "0.1.0"
M._DESCRIPTION = "Claude Code integration and workspace management"
M._EXTERNAL_DEPS = { "claude (CLI)", "claudectl (optional, for workspace management)" }
M._FLAGS_SCHEMA = {
  leader_key = "string (default: c)",
  leader_mod = "string (default: LEADER)",
}

function M.init(flags, log)
  return {
    leader_key = flags.leader_key or "c",
    leader_mod = flags.leader_mod or "LEADER",
  }
end

function M.apply_to_config(config, flags, state)
  -- Create claude key table
  config.key_tables = config.key_tables or {}
  config.key_tables.claude = {
    { key = "c", action = act.SpawnCommandInNewTab({ args = { "fish", "-c", "claude" } }) },
    { key = "Escape", action = "PopKeyTable" },
  }

  -- Add keybinding to activate claude menu
  config.keys = config.keys or {}
  table.insert(config.keys, {
    key = state.leader_key,
    mods = state.leader_mod,
    action = act.ActivateKeyTable({
      name = "claude",
      one_shot = false,
      until_unknown = true,
    }),
  })
end

return M
