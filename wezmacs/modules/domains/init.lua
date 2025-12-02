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
M._EXTERNAL_DEPS = {} -- Uses WezTerm plugin: quick_domains
M._CONFIG = {
  leader_key = "t",
  leader_mod = "LEADER",
  ssh_ignore = true,
  docker_ignore = false,
  kubernetes_ignore = true,
}

function M.apply_to_config(wezterm_config)
  local mod = wezmacs.get_module(M._NAME)
  local domains = wezterm.plugin.require("https://github.com/DavidRR-F/quick_domains.wezterm")
  
  -- Configure quick_domains to use the domains key table
  domains.apply_to_config(wezterm_config, {
    keys = {
      attach = { key = "a", mods = "LEADER", tbl = nil },
      vsplit = { key = "_", mods = "LEADER", tbl = nil },
      hsplit = { key = "|", mods = "LEADER", tbl = nil },
    },
    auto = {
      ssh_ignore = mod.ssh_ignore,
      exec_ignore = {
        ssh = mod.ssh_ignore,
        docker = mod.docker_ignore,
        kubernetes = mod.kubernetes_ignore,
      },
    },
  })
end

return M
