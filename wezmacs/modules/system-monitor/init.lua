--[[
  Module: system-monitor
  Category: tools
  Description: System monitoring with bottom (btm)

  Provides:
  - bottom launcher in new tab
  - CPU, memory, disk, network monitoring

  Configurable flags:
    keybinding - Keybinding to launch btm (default: "h")
    modifier - Key modifier (default: "LEADER")
]]

local wezterm = require("wezterm")
local act = wezterm.action

local M = {}

M._NAME = "system-monitor"
M._CATEGORY = "tools"
M._VERSION = "0.1.0"
M._DESCRIPTION = "System monitoring with bottom"
M._EXTERNAL_DEPS = { "bottom (btm)" }
M._FEATURE_FLAGS = {}
M._CONFIG_SCHEMA = {
  keybinding = "h",
  modifier = "LEADER",
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

  table.insert(wezterm_config.keys, {
    key = state.config.keybinding,
    mods = state.config.modifier,
    action = act.SpawnCommandInNewTab({ args = { "btm" } })
  })
end

return M
