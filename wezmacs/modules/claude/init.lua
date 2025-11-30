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
M._FEATURE_FLAGS = {}
M._CONFIG_SCHEMA = {
  leader_key = "c",
  leader_mod = "LEADER",
}

function M.init(enabled_flags, user_config, log)
  local config = {}
  for k, v in pairs(M._CONFIG_SCHEMA) do
    config[k] = user_config[k] or v
  end
  return { config = config, flags = enabled_flags or {} }
end

function M.apply_to_config(config, state)
  -- Create claude key table
  config.key_tables = config.key_tables or {}
  config.key_tables.claude = {
    { key = "c", action = act.SpawnCommandInNewTab({ args = { "fish", "-c", "claude" } }) },
    { key = "Escape", action = "PopKeyTable" },
  }

  -- Add keybinding to activate claude menu
  config.keys = config.keys or {}
  table.insert(config.keys, {
    key = state.config.leader_key,
    mods = state.config.leader_mod,
    action = act.ActivateKeyTable({
      name = "claude",
      one_shot = false,
      until_unknown = true,
    }),
  })
end

return M
