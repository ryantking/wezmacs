--[[
  Module: domains
  Category: devops
  Description: Quick domain management for SSH/Docker/Kubernetes
]]

local wezterm = require("wezterm")

-- Module spec (LazyVim-style inline spec)
return {
  name = "domains",
  category = "devops",
  description = "Quick domain management for SSH/Docker/Kubernetes",

  dependencies = {
    external = {},
    modules = { "keybindings" },
  },

  opts = {
    leader_key = "t",
    leader_mod = "LEADER",
    ssh_ignore = true,
    docker_ignore = false,
    kubernetes_ignore = true,
  },

  keys = {},

  enabled = true,

  priority = 50,

  -- Implementation function
  apply_to_config = function(config, opts)
    opts = opts or {}
    local mod = opts.leader_key ~= nil and opts or wezmacs.get_module("domains")
    local domains = wezterm.plugin.require("https://github.com/DavidRR-F/quick_domains.wezterm")
    
    -- Configure quick_domains to use the domains key table
    domains.apply_to_config(config, {
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
  end,
}
