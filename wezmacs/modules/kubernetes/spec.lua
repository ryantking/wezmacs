--[[
  Module Spec: kubernetes
  Category: devops
  Description: Kubernetes cluster management with k9s
]]

return {
  name = "kubernetes",
  category = "devops",
  description = "Kubernetes cluster management with k9s",

  dependencies = {
    external = { "k9s" },
    modules = { "keybindings" },
  },

  opts = {
    keybinding = "k",
    modifier = "LEADER",
  },

  keys = {
    {
      key = "k",
      mods = "LEADER",
      action = "actions.launch_k9s",
    },
  },

  enabled = function(ctx)
    return ctx.has_command("k9s")
  end,

  priority = 50,
}
