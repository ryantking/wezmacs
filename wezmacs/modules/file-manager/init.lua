--[[
  Module: file-manager
  Category: tools
  Description: File management with yazi terminal file manager

  Provides:
  - yazi launcher in new tab (normal and sudo modes)
  - File browsing and management

  Configurable flags:
    keybinding - Keybinding to launch yazi (default: "y")
    sudo_keybinding - Keybinding to launch yazi as sudo (default: "Y")
    modifier - Key modifier (default: "LEADER")
]]

local wezterm = require("wezterm")
local act = wezterm.action

local M = {}

M._NAME = "file-manager"
M._CATEGORY = "tools"
M._DESCRIPTION = "File management with yazi terminal file manager"
M._EXTERNAL_DEPS = { "yazi" }
M._FEATURES = {}
M._CONFIG_SCHEMA = {
  file_manager = "yazi",
  leader_key = "f",
  leader_mod = "LEADER",
}

function M.apply_to_config(wezterm_config, state)
  local split = require("wezmacs.utils.split")

  -- File manager in smart split
  local function file_manager_split(window, pane)
    split.smart_split(pane, { state.config.file_manager })
  end

  -- File manager with sudo in smart split
  local function file_manager_sudo_split(window, pane)
    split.smart_split(pane, { "sudo", state.config.file_manager, "/" })
  end

  -- Create file-manager key table
  wezterm_config.key_tables = wezterm_config.key_tables or {}
  wezterm_config.key_tables["file-manager"] = {
    { key = "f", action = wezterm.action_callback(file_manager_split) },
    { key = "F", action = act.SpawnCommandInNewTab({ args = { state.config.file_manager } }) },
    { key = "s", action = wezterm.action_callback(file_manager_sudo_split) },
    { key = "S", action = act.SpawnCommandInNewTab({ args = { "sudo", state.config.file_manager, "/" } }) },
    { key = "Escape", action = "PopKeyTable" },
  }

  -- Add keybinding to activate file-manager menu
  wezterm_config.keys = wezterm_config.keys or {}
  table.insert(wezterm_config.keys, {
    key = state.config.leader_key,
    mods = state.config.leader_mod,
    action = act.ActivateKeyTable({
      name = "file-manager",
      one_shot = false,
      until_unknown = true,
    }),
  })
end

return M
