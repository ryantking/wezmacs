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
M._DESCRIPTION = "System monitoring with bottom"
M._EXTERNAL_DEPS = { "bottom (btm)" }
M._FEATURES = {}
M._CONFIG_SCHEMA = {
  keybinding = "h",
  modifier = "LEADER",
}

function M.apply_to_config(wezterm_config)
  local mod_config = wezmacs.get_config(M._NAME)

  wezterm_config.keys = wezterm_config.keys or {}

  table.insert(wezterm_config.keys, {
    key = mod_config.keybinding,
    mods = mod_config.modifier,
    action = act.SpawnCommandInNewTab({ args = { "btm" } })
  })
end

return M
