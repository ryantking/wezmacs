--[[
  Module: window
  Category: ui
  Description: Window decorations, padding, scrolling, and cursor behavior
]]

local wezterm = require("wezterm")

return {
  name = "window",
  category = "ui",
  description = "Window behavior, padding, and cursor settings",

  deps = {},

  opts = function()
    return {
      padding = 16,
      scrollback_lines = 5000,
      decorations = "RESIZE",
    }
  end,

  keys = function()
    return {}
  end,

  enabled = true,

  priority = 80,

  setup = function(config, spec)
    local opts = spec.opts()
    
    -- Window decorations and behavior
    config.window_decorations = opts.decorations
    config.window_close_confirmation = "NeverPrompt"

    -- Window padding (equal on all sides)
    local p = opts.padding
    config.window_padding = {
      left = p,
      right = p,
      top = p,
      bottom = p,
    }

    -- Scrolling behavior
    config.scrollback_lines = opts.scrollback_lines
    config.enable_scroll_bar = true

    -- Cursor configuration
    config.cursor_blink_rate = 500
    config.cursor_blink_ease_in = "EaseIn"
    config.cursor_blink_ease_out = "EaseOut"
    config.default_cursor_style = "BlinkingBlock"

    -- Audio feedback
    config.audible_bell = "Disabled"
  end,
}
