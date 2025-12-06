--[[
  Module Spec: docker
  Category: devops
  Description: Docker container management with lazydocker
]]

return {
  name = "docker",
  category = "devops",
  description = "Docker container management with lazydocker",

  dependencies = {
    external = { "lazydocker" },
    modules = { "keybindings" },
  },

  opts = {
    leader_key = "d",
    leader_mod = "LEADER",
  },

  keys = {
    {
      leader = "d",
      submenu = "docker",
      bindings = {
        { key = "d", desc = "Lazydocker in split", action = "actions.lazydocker_split" },
        { key = "D", desc = "Lazydocker in new tab", action = "actions.lazydocker_new_tab" },
      },
    },
  },

  enabled = function(ctx)
    return ctx.has_command("lazydocker")
  end,

  priority = 50,
}
