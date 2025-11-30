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
M._VERSION = "0.1.0"
M._DESCRIPTION = "Mouse bindings and behavior"
M._EXTERNAL_DEPS = {}
M._FEATURE_FLAGS = {}
M._CONFIG_SCHEMA = {
  leader_mod = "CMD",
}

function M.init(enabled_flags, user_config, log)
  local config = {}
  for k, v in pairs(M._CONFIG_SCHEMA) do
    config[k] = user_config[k] or v
  end
  return { config = config, flags = enabled_flags or {} }
end

function M.apply_to_config(config, state)
  config.alternate_buffer_wheel_scroll_speed = 1
  config.bypass_mouse_reporting_modifiers = state.config.leader_mod
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
      mods = state.config.leader_mod,
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
