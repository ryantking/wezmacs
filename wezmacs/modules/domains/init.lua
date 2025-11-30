--[[
  Module: domains
  Category: devops
  Description: Quick domain management for SSH/Docker/Kubernetes

  Provides:
  - Quick attach to SSH/Docker/Kubernetes domains
  - Domain split (vertical/horizontal) support
  - Auto-detection of domain types

  Configurable flags:
    attach_key - Key for domain attach (default: "t")
    attach_mod - Modifier for attach (default: "ALT|SHIFT")
    vsplit_key - Key for vertical split (default: "_")
    vsplit_mod - Modifier for vsplit (default: "CTRL|SHIFT|ALT")
    hsplit_key - Key for horizontal split (default: "-")
    hsplit_mod - Modifier for hsplit (default: "CTRL|ALT")
    ssh_ignore - Ignore SSH domains (default: true)
    docker_ignore - Ignore Docker domains (default: false)
    kubernetes_ignore - Ignore Kubernetes domains (default: true)
]]

local wezterm = require("wezterm")

local M = {}

M._NAME = "domains"
M._CATEGORY = "devops"
M._VERSION = "0.1.0"
M._DESCRIPTION = "Quick domain management for SSH/Docker/Kubernetes"
M._EXTERNAL_DEPS = { "quick_domains (plugin)" }
M._FEATURE_FLAGS = {}
M._CONFIG_SCHEMA = {
  leader_key = "t",
  leader_mod = "LEADER",
  ssh_ignore = true,
  docker_ignore = false,
  kubernetes_ignore = true,
}

function M.init(enabled_flags, user_config, log)
  local config = {}
  for k, v in pairs(M._CONFIG_SCHEMA) do
    config[k] = user_config[k] or v
  end
  return { config = config, flags = enabled_flags or {} }
end

function M.apply_to_config(wezterm_config, state)
  local domains = wezterm.plugin.require("https://github.com/DavidRR-F/quick_domains.wezterm")

  -- Configure quick_domains to use the domains key table
  domains.apply_to_config(wezterm_config, {
    keys = {
      attach = { key = "a", mods = "", tbl = "domains" },
      vsplit = { key = "v", mods = "", tbl = "domains" },
      hsplit = { key = "h", mods = "", tbl = "domains" },
    },
    auto = {
      ssh_ignore = state.config.ssh_ignore,
      exec_ignore = {
        ssh = state.config.ssh_ignore,
        docker = state.config.docker_ignore,
        kubernetes = state.config.kubernetes_ignore,
      },
    },
  })

  -- Add Escape to domains key table if it exists
  if wezterm_config.key_tables and wezterm_config.key_tables.domains then
    table.insert(wezterm_config.key_tables.domains, { key = "Escape", action = "PopKeyTable" })
  end

  -- Add keybinding to activate domains menu
  wezterm_config.keys = wezterm_config.keys or {}
  table.insert(wezterm_config.keys, {
    key = state.config.leader_key,
    mods = state.config.leader_mod,
    action = wezterm.action.ActivateKeyTable({
      name = "domains",
      one_shot = false,
      until_unknown = true,
    }),
  })
end

return M
