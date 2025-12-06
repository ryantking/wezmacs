--[[
  Module: kubernetes
  Category: devops
  Description: Kubernetes cluster management with k9s
]]

local act = require("wezmacs.action")

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

  enabled = true,

  priority = 50,

  setup = function(config, opts)
    -- Module-specific setup (if any)
  end,
}
