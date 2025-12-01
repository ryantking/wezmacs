--[[
  Module: mouse
  Category: behavior
  Description: Mouse bindings and behavior (selection, link opening, etc.)

  Provides:
  - Left-click: Copy selection to clipboard
  - CMD+left-click: Open link or extend selection
  - Quadruple-click: Select semantic zone (word/expression)
  - Wheel scroll customization

  Configurable flags:
    leader_mod - Leader modifier for mouse clicks (default: "CMD")
]]

local wezterm = require("wezterm")
local M = {}

M._NAME = "mouse"
M._CATEGORY = "behavior"
M._DESCRIPTION = "Mouse bindings and behavior"
M._EXTERNAL_DEPS = {}
M._CONFIG = {
  leader_mod = "CMD",
}

function M.apply_to_config(config)
  -- Get configuration
  local mod_config = wezmacs.get_config(M._NAME)

  config.alternate_buffer_wheel_scroll_speed = 1
  config.bypass_mouse_reporting_modifiers = mod_config.leader_mod
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
      mods = mod_config.leader_mod,
      action = wezterm.action.CompleteSelectionOrOpenLinkAtMouseCursor("ClipboardAndPrimarySelection"),
    },

    -- Quadruple-click: Select semantic zone (word/code block)
    {
      event = { Down = { streak = 4, button = "Left" } },
      action = wezterm.action.SelectTextAtMouseCursor("SemanticZone"),
    },
  }
end

return M
