--[[
  Module: workspace
  Category: workflows
  Description: WezTerm workspace switching and management with fuzzy search

  Provides:
  - Fuzzy workspace switcher (default: LEADER s)
  - Previous workspace navigation (default: LEADER S)
  - Integration with smart_workspace_switcher plugin

  Note: For Claude Code workspace management, see the claude module.

  Configuration:
    switch_key - Key for workspace switcher (default: "s")
    switch_mod - Modifier for switch key (default: "LEADER")
    prev_key - Key for previous workspace (default: "S")
    prev_mod - Modifier for previous key (default: "LEADER")
]]

local wezterm = require("wezterm")
local act = wezterm.action
local workspace_switcher = wezterm.plugin.require("https://github.com/MLFlexer/smart_workspace_switcher.wezterm")
local actions = require("wezmacs.modules.workspace.actions")

local M = {}

M._NAME = "workspace"
M._CATEGORY = "workflows"
M._DESCRIPTION = "Workspace switching and management"
M._EXTERNAL_DEPS = {} -- Uses WezTerm plugin: smart_workspace_switcher
M._CONFIG = {
  switch_key = "s",
  switch_mod = "LEADER",
  prev_key = "S",
  prev_mod = "LEADER",
}

function M.apply_to_config(config)
  local mod = wezmacs.get_module(M._NAME)

  -- Plugin setup
  workspace_switcher.apply_to_config(config)

  -- Keybindings
  config.keys = config.keys or {}

  -- Workspace switcher
  table.insert(config.keys, {
    key = mod.leader_key,
    mods = mod.leader_mod,
    action = workspace_switcher.switch_workspace(),
  })

  -- Switch to previous workspace
  table.insert(config.keys, {
    key = "S",
    mods = mod.leader_mod,
    action = workspace_switcher.switch_to_prev_workspace(),
  })

  -- Jump to System workspace
  table.insert(config.keys, {
    key = "B",
    mods = mod.leader_mod,
    action = wezterm.action_callback(actions.jump_to_system_workspace),
  })
end

return M
