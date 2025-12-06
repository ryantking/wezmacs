--[[
  Module: system-monitor
  Category: tools
  Description: System monitoring with bottom (btm)
]]

local keybindings = require("wezmacs.lib.keybindings")
local action_lib = require("wezmacs.lib.actions")

-- Actions (inline)
local actions = {
  launch_btm = action_lib.new_tab_action("btm"),
}

-- Module spec (LazyVim-style inline spec)
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
      action = actions.launch_btm,
    },
  },

  enabled = function(ctx)
    return ctx.has_command("btm")
  end,

  priority = 50,

  -- Implementation function
  apply_to_config = function(config, opts)
    -- Get spec (self-reference via closure)
    local spec = require("wezmacs.modules.system-monitor")
    -- Apply keybindings using library
    keybindings.apply_keys(config, spec)
  end,
}
