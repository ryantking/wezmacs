--[[
  Module: kubernetes
  Category: devops
  Description: Kubernetes cluster management with k9s

  Provides:
  - k9s launcher in new tab
  - Cluster management and monitoring

  Configurable flags:
    keybinding - Keybinding to launch k9s (default: "k")
    modifier - Key modifier (default: "LEADER")
]]

local wezterm = require("wezterm")
local act = wezterm.action

local M = {}

M._NAME = "kubernetes"
M._CATEGORY = "devops"
M._VERSION = "0.1.0"
M._DESCRIPTION = "Kubernetes cluster management with k9s"
M._EXTERNAL_DEPS = { "k9s" }
M._FEATURE_FLAGS = {}
M._CONFIG_SCHEMA = {
  keybinding = "k",
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
    action = act.SpawnCommandInNewTab({ args = { "k9s" } })
  })
end

return M
