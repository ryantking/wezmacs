--[[
  Module: file-manager
  Category: tools
  Description: File management with configurable terminal file manager
]]

local act = require("wezmacs.action")
local keybindings = require("wezmacs.lib.keybindings")

return {
  name = "file-manager",
  category = "tools",
  description = "File management with yazi terminal file manager",

  deps = { "yazi" },

  opts = function()
    return {
      file_manager = "yazi",
      leader_key = "f",
      leader_mod = "LEADER",
    }
  end,

  keys = function(opts)
    local file_manager = opts.file_manager or "yazi"
    
    return {
      LEADER = {
        f = {
          f = { action = act.SmartSplit(file_manager), desc = "file-manager/split" },
          F = { action = act.NewTab(file_manager), desc = "file-manager/tab" },
          s = {
            action = act.SmartSplit("sudo " .. file_manager .. " /"),
            desc = "file-manager/sudo-split",
          },
          S = {
            action = act.NewTab("sudo " .. file_manager .. " /"),
            desc = "file-manager/sudo-tab",
          },
        },
      },
    }
  end,

  enabled = function(ctx)
    return ctx.has_command("yazi")
  end,

  priority = 50,

  setup = function(config, opts)
    -- Apply keybindings
    keybindings.apply_keys(config, require("wezmacs.modules.file-manager"), opts)
  end,
}
