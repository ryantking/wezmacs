--[[
  Module: system-monitor
  Category: tools
  Description: System monitoring with bottom (btm)
]]

local act = require("wezmacs.action")

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

  keys = {
    LEADER = {
      h = {
        action = act.NewTab("btm"),
        desc = "system-monitor/btm",
      },
    },
  },

  enabled = true,

  priority = 50,

  setup = function(config, opts)
    -- Module-specific setup (if any)
  end,
}
