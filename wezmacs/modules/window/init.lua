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
M._DESCRIPTION = "Window behavior, padding, and cursor settings"
M._EXTERNAL_DEPS = {}
M._CONFIG = {
  padding = 16,
  scrollback_lines = 5000,
  decorations = "RESIZE",
}

function M.apply_to_config(config)
  local wezterm = require("wezterm")

  -- Get configuration
  local mod_config = wezmacs.get_config(M._NAME)

  -- Window decorations and behavior
  config.window_decorations = mod_config.decorations
  config.window_close_confirmation = "NeverPrompt"

  -- Window padding (equal on all sides)
  local p = mod_config.padding
  config.window_padding = {
    left = p,
    right = p,
    top = p,
    bottom = p,
  }

  -- Scrolling behavior
  config.scrollback_lines = mod_config.scrollback_lines
  config.enable_scroll_bar = true

  -- Cursor configuration
  config.cursor_blink_rate = 500
  config.cursor_blink_ease_in = "EaseIn"
  config.cursor_blink_ease_out = "EaseOut"
  config.default_cursor_style = "BlinkingBlock"

  -- Audio feedback
  config.audible_bell = "Disabled"

  -- Apply theme-based UI styling if theme module is enabled
  local theme_config = wezmacs.get_config("theme")
  if theme_config and theme_config.color_scheme then
    local theme = wezterm.get_builtin_color_schemes()[theme_config.color_scheme]
    if theme then
      -- Window frame colors
      if not config.window_frame then
        config.window_frame = {}
      end
      config.window_frame.active_titlebar_bg = theme.background
      config.window_frame.inactive_titlebar_bg = theme.background
      config.window_frame.active_titlebar_fg = theme.foreground
      config.window_frame.inactive_titlebar_fg = theme.foreground

      -- Character selector appearance
      config.char_select_bg_color = theme.brights[1]
      config.char_select_fg_color = theme.foreground

      -- Command palette appearance
      config.command_palette_bg_color = theme.brights[1]
      config.command_palette_fg_color = theme.foreground
    end
  end
end

return M
