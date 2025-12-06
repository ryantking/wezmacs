--[[
  Module: docker
  Category: devops
  Description: Docker container management with lazydocker
]]

local act = require("wezmacs.action")
local keybindings = require("wezmacs.lib.keybindings")

-- Define keys function (captured in closure for setup)
local function keys_fn()
  return {
    LEADER = {
      d = {
        d = { action = act.SmartSplit("lazydocker"), desc = "docker/lazydocker-split" },
        D = { action = act.NewTab("lazydocker"), desc = "docker/lazydocker-tab" },
      },
    },
  }
end

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

  keys = keys_fn,

  enabled = function(ctx)
    return ctx.has_command("lazydocker")
  end,

  priority = 50,

  setup = function(config, opts)
    -- Apply keybindings using the keys function (captured in closure)
    keybindings.apply_keys(config, {
      name = "docker",
      keys = keys_fn,
    })
  end,
}
