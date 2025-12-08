--[[
  Module: window
  Description: Window decorations, padding, scrolling, and cursor behavior
]]

local wezterm = require("wezterm")
local act = wezterm.action
local wezmacs = require("wezmacs")

local theme = wezterm.plugin.require("https://github.com/neapsix/wezterm").main

return {
  name = "window",
  description = "Window behavior, padding, and cursor settings",

  opts = function()
    return {
      font = nil,
      font_size = nil,
      padding = 16,
      decorations = "RESIZE",
      close_confirmation = "NeverPrompt",

      -- Keybindings
      term_mod = wezmacs.config.term_mod,
      gui_mod = wezmacs.config.gui_mod,
      alt_mod = wezmacs.config.alt_mod,
    }
  end,

  keys = function(opts)
    return {
      { key = "n", mods = opts.term_mod, action = act.SpawnWindow, desc = "new-window" },
      { key = "n", mods = opts.gui_mod, action = act.SpawnWindow, desc = "new-window" },
      { key = "Enter", mods = opts.alt_mod, action = act.ToggleFullScreen, desc = "fullscreen" },
      { key = "m", mods = opts.gui_mod, action = act.Hide, desc = "minimize" },
    }
  end,

  setup = function(config, opts)
    -- Window decorations and behavior
    config.window_decorations = opts.decorations
    config.window_close_confirmation = opts.close_confirmation

    local color_scheme = wezmacs.color_scheme()
    if color_scheme then
      config.colors = color_scheme
      config.window_frame = config.window_frame or {}
    else
      config.colors = theme.colors()
      config.window_frame = theme.window_frame()
    end

    -- Window padding (equal on all sides)
    local p = opts.padding
    config.window_padding = {
      left = p,
      right = p,
      top = p,
      bottom = p,
    }

    -- UI fonts (for UI elements) - only if configured
    if opts.font then
      local ui_font = wezterm.font({ family = opts.font })
      config.char_select_font = ui_font
      config.command_palette_font = ui_font
      config.window_frame.font = ui_font
    end

    if opts.font_size then
      config.char_select_font_size = opts.font_size
      config.command_palette_font_size = opts.font_size
      config.window_frame.font_size = opts.font_size
    end
  end,
}
