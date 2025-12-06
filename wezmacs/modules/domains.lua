--[[
  Module: domains
  Category: devops
  Description: Quick domain management for SSH/Docker/Kubernetes
]]

local wezterm = require("wezterm")

return {
  name = "domains",
  category = "devops",
  description = "Quick domain management for SSH/Docker/Kubernetes",

  deps = {},

  opts = function()
    return {
      leader_key = "t",
      leader_mod = "LEADER",
      ssh_ignore = true,
      docker_ignore = false,
      kubernetes_ignore = true,
    }
  end,

  keys = function()
    return {}
  end,

  enabled = true,

  priority = 50,

  setup = function(config, opts)
    local domains = wezterm.plugin.require("https://github.com/DavidRR-F/quick_domains.wezterm")
    
    -- Configure quick_domains to use the domains key table
    domains.apply_to_config(config, {
      keys = {
        attach = { key = "a", mods = "LEADER", tbl = nil },
        vsplit = { key = "_", mods = "LEADER", tbl = nil },
        hsplit = { key = "|", mods = "LEADER", tbl = nil },
      },
      auto = {
        ssh_ignore = opts.ssh_ignore,
        exec_ignore = {
          ssh = opts.ssh_ignore,
          docker = opts.docker_ignore,
          kubernetes = opts.kubernetes_ignore,
        },
      },
    })
  end,
}
