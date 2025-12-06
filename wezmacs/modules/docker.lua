--[[
  Module: docker
  Category: devops
  Description: Docker container management with lazydocker
]]

local act = require("wezmacs.action")

return {
  name = "docker",
  category = "devops",
  description = "Docker container management with lazydocker",

  deps = { "lazydocker" },

  opts = function()
    return {
      leader_key = "d",
      leader_mod = "LEADER",
    }
  end,

  keys = {
    LEADER = {
      d = {
        d = { action = act.SmartSplit("lazydocker"), desc = "docker/lazydocker-split" },
        D = { action = act.NewTab("lazydocker"), desc = "docker/lazydocker-tab" },
      },
    },
  },

  enabled = function(ctx)
    return ctx.has_command("lazydocker")
  end,

  priority = 50,

  setup = function(config, opts)
    -- Module-specific setup (if any)
  end,
}
