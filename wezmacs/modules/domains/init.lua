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
local spec = require("wezmacs.modules.domains.spec")

local M = {}

M._NAME = spec.name
M._CATEGORY = spec.category
M._DESCRIPTION = spec.description
M._EXTERNAL_DEPS = spec.dependencies.external or {}
M._CONFIG = spec.opts

function M.apply_to_config(config, opts)
  opts = opts or {}
  local mod = opts.leader_key ~= nil and opts or wezmacs.get_module(M._NAME)
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
