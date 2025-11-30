--[[
  Module: window
  Category: ui
  Description: Window decorations, padding, scrolling, and cursor behavior

  Provides:
  - Window frame styling (resize-only decorations)
  - Padding configuration
  - Scrollback buffer size
  - Cursor style and blinking behavior

  Configurable flags:
    padding - Window padding in pixels (default: 16)
    scrollback_lines - Number of lines to keep in scrollback (default: 5000)
]]

local M = {}

M._NAME = "window"
M._CATEGORY = "ui"
M._VERSION = "0.1.0"
M._DESCRIPTION = "Window behavior, padding, and cursor settings"
M._EXTERNAL_DEPS = {}
M._FLAGS_SCHEMA = {
  padding = "number (pixels)",
  scrollback_lines = "number (lines)",
}

function M.init(flags, log)
  return {
    padding = flags.padding or 16,
    scrollback_lines = flags.scrollback_lines or 5000,
  }
end

function M.apply_to_config(config, flags, state)
  -- Window decorations and behavior
  config.window_decorations = "RESIZE"
  config.window_close_confirmation = "NeverPrompt"

  -- Window padding (equal on all sides)
  local p = state.padding
  config.window_padding = {
    left = p,
    right = p,
    top = p,
    bottom = p,
  }

  -- Scrolling behavior
  config.scrollback_lines = state.scrollback_lines
  config.enable_scroll_bar = true

  -- Cursor configuration
  config.cursor_blink_rate = 500
  config.cursor_blink_ease_in = "EaseIn"
  config.cursor_blink_ease_out = "EaseOut"
  config.default_cursor_style = "BlinkingBlock"

  -- Audio feedback
  config.audible_bell = "Disabled"
end

return M
