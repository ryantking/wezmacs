--[[
  Module: kubernetes
  Category: devops
  Description: Kubernetes cluster management with k9s
]]

local act = require("wezmacs.action")
local keybindings = require("wezmacs.lib.keybindings")

return {
  name = "kubernetes",
  category = "devops",
  description = "Kubernetes cluster management with k9s",

  deps = { "k9s" },

  opts = function()
    return {
      keybinding = "k",
      modifier = "LEADER",
    }
  end,

  keys = {
    LEADER = {
      k = {
        action = act.NewTab("k9s"),
        desc = "kubernetes/k9s",
      },
    },
  },

  enabled = function(ctx)
    return ctx.has_command("k9s")
  end,

  priority = 50,

  setup = function(config, opts)
    -- Apply keybindings
    keybindings.apply_keys(config, require("wezmacs.modules.kubernetes"), opts)
  end,
}
