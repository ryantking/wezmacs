--[[
  Module: window
  Category: ui
  Description: Window decorations, padding, scrolling, and cursor behavior
]]

local wezterm = require("wezterm")

-- Module spec (LazyVim-style inline spec)
return {
  name = "window",
  category = "ui",
  description = "Window behavior, padding, and cursor settings",

  dependencies = {
    external = {},
    modules = { "theme" },
  },

  opts = {
    padding = 16,
    scrollback_lines = 5000,
    decorations = "RESIZE",
  },

  keys = {},

  enabled = true,

  priority = 80,

  -- Implementation function
  apply_to_config = function(config, opts)
    opts = opts or {}
    local mod = opts.padding ~= nil and opts or wezmacs.get_module("window")

    -- Window decorations and behavior
    config.window_decorations = mod.decorations
    config.window_close_confirmation = "NeverPrompt"

    -- Window padding (equal on all sides)
    local p = mod.padding
    config.window_padding = {
      left = p,
      right = p,
      top = p,
      bottom = p,
    }

    -- Scrolling behavior
    config.scrollback_lines = mod.scrollback_lines
    config.enable_scroll_bar = true

    -- Cursor configuration
    config.cursor_blink_rate = 500
    config.cursor_blink_ease_in = "EaseIn"
    config.cursor_blink_ease_out = "EaseOut"
    config.default_cursor_style = "BlinkingBlock"

    -- Audio feedback
    config.audible_bell = "Disabled"

    -- Apply theme-based UI styling if theme module is enabled
    local theme_mod = wezmacs.get_module("theme")
    if theme_mod and theme_mod.color_scheme then
      local theme = wezterm.get_builtin_color_schemes()[theme_mod.color_scheme]
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
  end,
}
