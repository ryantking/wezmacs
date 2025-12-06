--[[
  Module: system-monitor
  Category: tools
  Description: System monitoring with bottom (btm)
]]

local act = require("wezmacs.action")
local keybindings = require("wezmacs.lib.keybindings")

-- Define keys function (captured in closure for setup)
local function keys_fn()
  return {
    LEADER = {
      h = {
        action = act.NewTab("btm"),
        desc = "system-monitor/btm",
      },
    },
  }
end

return {
  name = "system-monitor",
  category = "tools",
  description = "System monitoring with bottom",

  deps = { "btm" },

  opts = function()
    return {
      keybinding = "h",
      modifier = "LEADER",
    }
  end,

  keys = keys_fn,

  enabled = function(ctx)
    return ctx.has_command("btm")
  end,

  priority = 50,

  setup = function(config, opts)
    -- Apply keybindings using the keys function (captured in closure)
    keybindings.apply_keys(config, {
      name = "system-monitor",
      keys = keys_fn,
    })
  end,
}
