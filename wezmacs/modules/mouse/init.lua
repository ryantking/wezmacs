--[[
  Module: mouse
  Category: behavior
  Description: Mouse bindings and behavior (selection, link opening, etc.)
]]

local act = require("wezmacs.action")
local term = act.term

return {
  name = "mouse",
  category = "behavior",
  description = "Mouse bindings and behavior",

  deps = {},

  opts = function()
    return {
      leader_mod = "CMD",
    }
  end,

  keys = function()
    return {}
  end,

  enabled = true,

  priority = 50,

  setup = function(config, opts)
    local wezmacs = require("wezmacs")
    local leader_mod = opts.leader_mod or wezmacs.config.leader_mod or "CTRL"
    
    config.alternate_buffer_wheel_scroll_speed = 1
    config.bypass_mouse_reporting_modifiers = leader_mod
    config.hide_mouse_cursor_when_typing = false

    config.mouse_bindings = {
      -- Left-click: Copy selection to clipboard
      {
        event = { Up = { streak = 1, button = "Left" } },
        action = term.CompleteSelection("ClipboardAndPrimarySelection"),
      },

      -- Leader+left-click: Open link or extend selection
      {
        event = { Up = { streak = 1, button = "Left" } },
        mods = leader_mod,
        action = term.CompleteSelectionOrOpenLinkAtMouseCursor("ClipboardAndPrimarySelection"),
      },

      -- Quadruple-click: Select semantic zone (word/code block)
      {
        event = { Down = { streak = 4, button = "Left" } },
        action = term.SelectTextAtMouseCursor("SemanticZone"),
      },
    }
  end,
}
