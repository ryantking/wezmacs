--[[
  Module Spec: domains
  Category: devops
  Description: Quick domain management for SSH/Docker/Kubernetes
]]

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
}
