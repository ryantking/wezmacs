--[[
  Module: workspace
  Category: workflows
  Description: WezTerm workspace switching and management with fuzzy search
]]

local act = require("wezmacs.action")
local wezterm = require("wezterm")

return {
  name = "workspace",
  category = "workflows",
  description = "Workspace switching and management",

  deps = {},

  opts = function()
    return {
      default_workspace = "~",
      switch_key = "s",
      switch_mod = "LEADER",
      prev_key = "S",
      prev_mod = "LEADER",
    }
  end,

  keys = function()
    local workspace_switcher = wezterm.plugin.require("https://github.com/MLFlexer/smart_workspace_switcher.wezterm")
    
    return {
      LEADER = {
        s = {
          action = function()
            return workspace_switcher.switch_workspace()
          end,
          desc = "workspace/switch",
        },
        S = {
          action = function()
            return workspace_switcher.switch_to_prev_workspace()
          end,
          desc = "workspace/switch-prev",
        },
      },
    }
  end,

  enabled = true,

  priority = 50,

  setup = function(config, spec)
    local opts = spec.opts()
    config.default_workspace = opts.default_workspace
  end,
}
