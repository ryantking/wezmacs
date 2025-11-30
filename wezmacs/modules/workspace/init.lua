--[[
  Module: workspace
  Category: workflows
  Description: Workspace switching and management with fuzzy search

  Provides:
  - Fuzzy workspace switcher via plugin
  - Create new workspace with name prompt
  - Delete workspace with fuzzy selection
  - Previous workspace navigation
  - System workspace quick access

  Configurable flags:
    leader_key - Workspace key (default: s)
    leader_mod - Leader modifier (default: LEADER)
]]

local wezterm = require("wezterm")
local act = wezterm.action
local workspace_switcher = wezterm.plugin.require("https://github.com/MLFlexer/smart_workspace_switcher.wezterm")

local M = {}

M._NAME = "workspace"
M._CATEGORY = "workflows"
M._DESCRIPTION = "Workspace switching and management"
M._EXTERNAL_DEPS = { "smart_workspace_switcher (plugin)" }
M._FEATURES = {}
M._CONFIG_SCHEMA = {
  leader_key = "s",
  leader_mod = "LEADER",
}

function M.apply_to_config(config, state)
  -- Plugin setup
  workspace_switcher.apply_to_config(config)

  -- Keybindings
  config.keys = config.keys or {}

  -- Workspace switcher
  table.insert(config.keys, {
    key = state.config.leader_key,
    mods = state.config.leader_mod,
    action = workspace_switcher.switch_workspace(),
  })

  -- Switch to previous workspace
  table.insert(config.keys, {
    key = "S",
    mods = state.config.leader_mod,
    action = workspace_switcher.switch_to_prev_workspace(),
  })

  -- Jump to System workspace
  table.insert(config.keys, {
    key = "B",
    mods = state.config.leader_mod,
    action = wezterm.action_callback(function(window, pane)
      window:perform_action(
        act.SwitchToWorkspace({
          name = "~/System",
          spawn = { cwd = wezterm.home_dir .. "/System" },
        }),
        pane
      )
      window:set_right_status(window:active_workspace())
    end),
  })
end

return M
