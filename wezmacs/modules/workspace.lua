--[[
  Module: workspace
  Category: workflows
  Description: WezTerm workspace switching and management with fuzzy search
]]

local act = require("wezmacs.action")
local keybindings = require("wezmacs.lib.keybindings")
local wezterm = require("wezterm")

-- Define keys function (captured in closure for setup)
local function keys_fn()
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
end

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

  keys = keys_fn,

  enabled = true,

  priority = 50,

  setup = function(config, opts)
    config.default_workspace = opts.default_workspace

    -- Apply keybindings using the keys function (captured in closure)
    keybindings.apply_keys(config, {
      name = "workspace",
      keys = keys_fn,
    })
  end,
}
