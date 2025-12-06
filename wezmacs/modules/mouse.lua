--[[
  Module: mouse
  Category: behavior
  Description: Mouse bindings and behavior (selection, link opening, etc.)
]]

local wezterm = require("wezterm")

-- Module spec (LazyVim-style inline spec)
return {
  name = "mouse",
  category = "behavior",
  description = "Mouse bindings and behavior",

  dependencies = {
    external = {},
    modules = {},
  },

  opts = {
    leader_mod = "CMD",
  },

  keys = {},

  enabled = true,

  priority = 50,

  -- Implementation function
  apply_to_config = function(config, opts)
    opts = opts or {}
    local mod = opts.leader_mod ~= nil and opts or wezmacs.get_module("mouse")

    config.alternate_buffer_wheel_scroll_speed = 1
    config.bypass_mouse_reporting_modifiers = mod.leader_mod
    config.hide_mouse_cursor_when_typing = false

    config.mouse_bindings = {
      -- Left-click: Copy selection to clipboard
      {
        event = { Up = { streak = 1, button = "Left" } },
        action = wezterm.action.CompleteSelection("ClipboardAndPrimarySelection"),
      },

      -- Leader+left-click: Open link or extend selection
      {
        event = { Up = { streak = 1, button = "Left" } },
        mods = mod.leader_mod,
        action = wezterm.action.CompleteSelectionOrOpenLinkAtMouseCursor("ClipboardAndPrimarySelection"),
      },

      -- Quadruple-click: Select semantic zone (word/code block)
      {
        event = { Down = { streak = 4, button = "Left" } },
        action = wezterm.action.SelectTextAtMouseCursor("SemanticZone"),
      },
    }
  end,
}
