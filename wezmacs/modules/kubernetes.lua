--[[
  Module: kubernetes
  Category: devops
  Description: Kubernetes cluster management with k9s
]]

local act = require("wezmacs.action")
local keybindings = require("wezmacs.lib.keybindings")

-- Define keys function (captured in closure for setup)
local function keys_fn()
  return {
    LEADER = {
      k = {
        action = act.NewTab("k9s"),
        desc = "kubernetes/k9s",
      },
    },
  }
end

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

  keys = keys_fn,

  enabled = function(ctx)
    return ctx.has_command("k9s")
  end,

  priority = 50,

  setup = function(config, opts)
    -- Apply keybindings using the keys function (captured in closure)
    keybindings.apply_keys(config, {
      name = "kubernetes",
      keys = keys_fn,
    })
  end,
}
