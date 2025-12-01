--[[
  Module: domains
  Category: devops
  Description: Quick domain management for SSH/Docker/Kubernetes

  Provides:
  - Quick attach to domain (LEADER t a)
  - Vertical split domain (LEADER t v)
  - Horizontal split domain (LEADER t h)
  - Auto-detection of domain types
  - Integration with quick_domains plugin

  Configuration:
    leader_key - Key to activate domains menu (default: "t")
    leader_mod - Modifier for leader key (default: "LEADER")
    ssh_ignore - Ignore SSH domains (default: true)
    docker_ignore - Ignore Docker domains (default: false)
    kubernetes_ignore - Ignore Kubernetes domains (default: true)
]]

local wezterm = require("wezterm")

local M = {}

M._NAME = "domains"
M._CATEGORY = "devops"
M._DESCRIPTION = "Quick domain management for SSH/Docker/Kubernetes"
M._EXTERNAL_DEPS = { "quick_domains (plugin)" }
M._FEATURES = {}
M._CONFIG_SCHEMA = {
  leader_key = "t",
  leader_mod = "LEADER",
  ssh_ignore = true,
  docker_ignore = false,
  kubernetes_ignore = true,
}

function M.apply_to_config(wezterm_config)
  local mod_config = wezmacs.get_config(M._NAME)
  local domains = wezterm.plugin.require("https://github.com/DavidRR-F/quick_domains.wezterm")

  -- Configure quick_domains to use the domains key table
  domains.apply_to_config(wezterm_config, {
    keys = {
      attach = { key = "a", mods = "", tbl = "domains" },
      vsplit = { key = "v", mods = "", tbl = "domains" },
      hsplit = { key = "h", mods = "", tbl = "domains" },
    },
    auto = {
      ssh_ignore = mod_config.ssh_ignore,
      exec_ignore = {
        ssh = mod_config.ssh_ignore,
        docker = mod_config.docker_ignore,
        kubernetes = mod_config.kubernetes_ignore,
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
    key = mod_config.leader_key,
    mods = mod_config.leader_mod,
    action = wezterm.action.ActivateKeyTable({
      name = "domains",
      one_shot = false,
      until_unknown = true,
    }),
  })
end

return M
