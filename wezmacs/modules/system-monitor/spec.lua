--[[
  Module Spec: system-monitor
  Category: tools
  Description: System monitoring with bottom (btm)
]]

return {
  name = "system-monitor",
  category = "tools",
  description = "System monitoring with bottom",

  dependencies = {
    external = { "btm" },
    modules = { "keybindings" },
  },

  opts = {
    keybinding = "h",
    modifier = "LEADER",
  },

  keys = {
    {
      key = "h",
      mods = "LEADER",
      action = "actions.launch_btm",
    },
  },

  enabled = function(ctx)
    return ctx.has_command("btm")
  end,

  priority = 50,
}
