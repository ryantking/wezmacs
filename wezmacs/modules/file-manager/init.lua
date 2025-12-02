--[[
  Module: file-manager
  Category: tools
  Description: File management with configurable terminal file manager

  Provides:
  - File manager in smart split (LEADER f f)
  - File manager in new tab (LEADER f F)
  - File manager with sudo in split (LEADER f s)
  - File manager with sudo in tab (LEADER f S)
  - Configurable file manager (default: yazi)

  Configuration:
    file_manager - File manager to use (default: "yazi")
    leader_key - Key to activate file-manager menu (default: "f")
    leader_mod - Modifier for leader key (default: "LEADER")
]]

local wezterm = require("wezterm")
local act = wezterm.action
local actions = require("wezmacs.modules.file-manager.actions")

local M = {}

M._NAME = "file-manager"
M._CATEGORY = "tools"
M._DESCRIPTION = "File management with yazi terminal file manager"
M._EXTERNAL_DEPS = { "yazi" }
M._CONFIG = {
  file_manager = "yazi",
  leader_key = "f",
  leader_mod = "LEADER",
}

function M.apply_to_config(wezterm_config)
  local mod = wezmacs.get_module(M._NAME)

  -- Create file-manager key table
  wezterm_config.key_tables = wezterm_config.key_tables or {}
  wezterm_config.key_tables["file-manager"] = {
    {
      key = "f",
      action = wezterm.action_callback(function(window, pane)
        actions.file_manager_split(window, pane, mod.file_manager)
      end),
    },
    { key = "F", action = act.SpawnCommandInNewTab({ args = { mod.file_manager } }) },
    {
      key = "s",
      action = wezterm.action_callback(function(window, pane)
        actions.file_manager_sudo_split(window, pane, mod.file_manager)
      end),
    },
    { key = "S", action = act.SpawnCommandInNewTab({ args = { "sudo", mod.file_manager, "/" } }) },
    { key = "Escape", action = "PopKeyTable" },
  }

  -- Add keybinding to activate file-manager menu
  wezterm_config.keys = wezterm_config.keys or {}
  table.insert(wezterm_config.keys, {
    key = mod.leader_key,
    mods = mod.leader_mod,
    action = act.ActivateKeyTable({
      name = "file-manager",
      one_shot = false,
      until_unknown = true,
    }),
  })
end

return M
