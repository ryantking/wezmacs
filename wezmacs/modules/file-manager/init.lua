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
M._VERSION = "0.1.0"
M._DESCRIPTION = "File management with yazi terminal file manager"
M._EXTERNAL_DEPS = { "yazi" }
M._FEATURE_FLAGS = {}
M._CONFIG_SCHEMA = {
  file_manager = "yazi",
  leader_key = "f",
  leader_mod = "LEADER",
}

function M.init(enabled_flags, user_config, log)
  local config = {}
  for k, v in pairs(M._CONFIG_SCHEMA) do
    config[k] = user_config[k] or v
  end
  return { config = config, flags = enabled_flags or {} }
end

function M.apply_to_config(wezterm_config, state)
  wezterm_config.keys = wezterm_config.keys or {}

  -- Normal yazi
  table.insert(wezterm_config.keys, {
    key = state.config.keybinding,
    mods = state.config.modifier,
    action = act.SpawnCommandInNewTab({ args = { "yazi" } })
  })

  -- Sudo yazi (for system files)
  table.insert(wezterm_config.keys, {
    key = state.config.sudo_keybinding,
    mods = state.config.modifier,
    action = act.SpawnCommandInNewTab({ args = { "sudo", "yazi", "/" } })
  })
end

return M
