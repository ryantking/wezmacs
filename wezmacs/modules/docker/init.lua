--[[
  Module: docker
  Category: devops
  Description: Docker container management with lazydocker

  Provides:
  - lazydocker launcher in new tab
  - Container, image, and volume management

  Configurable flags:
    keybinding - Keybinding to launch lazydocker (default: "D")
    modifier - Key modifier (default: "LEADER")
]]

local wezterm = require("wezterm")
local act = wezterm.action

local M = {}

M._NAME = "docker"
M._CATEGORY = "devops"
M._VERSION = "0.1.0"
M._DESCRIPTION = "Docker container management with lazydocker"
M._EXTERNAL_DEPS = { "lazydocker" }
M._FEATURE_FLAGS = {}
M._CONFIG_SCHEMA = {
  leader_key = "d",
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

  table.insert(wezterm_config.keys, {
    key = state.config.keybinding,
    mods = state.config.modifier,
    action = act.SpawnCommandInNewTab({ args = { "lazydocker" } })
  })
end

return M
